import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/transaction/TransactionType.dart';
import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/models/Subscription.dart';
import 'package:finance_tracker/models/Transaction.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';
import 'package:finance_tracker/service/UserFirestoreService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final UserFirestoreService userFirestoreService = UserFirestoreService();

  Stream<List<Map<String, dynamic>>> getRecentTransactionsOfUser(
      String uid) async* {
    final cacheKey = 'transactions_recent_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      yield cached;
    }

    yield* firestore
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .orderBy("date", descending: true)
        .limit(7)
        .snapshots()
        .asyncMap((snapshot) async {
      final transactions =
          snapshot.docs.map((doc) => doc.data()).toList(growable: false);
      await OfflineCacheService.saveList(cacheKey, transactions);
      return transactions;
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactionsOfUser(String uid) async* {
    final cacheKey = 'transactions_all_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      yield cached;
    }

    yield* firestore
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .orderBy("date", descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final transactions =
          snapshot.docs.map((doc) => doc.data()).toList(growable: false);
      await OfflineCacheService.saveList(cacheKey, transactions);
      return transactions;
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactionsBasedOnType(
      String uid, type) async* {
    final cacheKey = 'transactions_type_${uid}_$type';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      yield cached;
    }

    yield* firestore
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .where("type", isEqualTo: type)
        .snapshots()
        .asyncMap((snapshot) async {
      final transactions =
          snapshot.docs.map((doc) => doc.data()).toList(growable: false);
      await OfflineCacheService.saveList(cacheKey, transactions);
      return transactions;
    });
  }

  Future<void> addTransaction(String uid, TransactionModel transaction) async {
    await userFirestoreService.updateUserFinancialData(
        uid, transaction.amount, transaction.type);
    await firestore
        .collection('Transactions')
        .doc(uid)
        .collection("transaction")
        .doc(transaction.id)
        .set({
      "id": transaction.id,
      "title": transaction.title,
      "date": transaction.date,
      "description": transaction.transactionDescription,
      "amount": transaction.amount,
      "category": transaction.category,
      "type": transaction.type
    });
  }

  Stream<double> getTotalAmountInACategory(String category) async* {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cacheKey = 'transactions_category_total_${uid}_$category';
    final cached = await OfflineCacheService.readDouble(cacheKey);
    if (cached != null) {
      yield cached;
    }

    yield* firestore
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .where("category", isEqualTo: category)
        .snapshots()
        .asyncMap((snapshot) async {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += double.parse(doc['amount'].toString());
      }
      await OfflineCacheService.saveDouble(cacheKey, total);
      return total;
    });
  }

  Future<void> updateTransaction(
      {required String uid, required TransactionModel transaction}) async {
    try {
      // Fetch the previous data of the transaction to adjust balances
      final transactionRef = FirebaseFirestore.instance
          .collection("Transactions")
          .doc(uid)
          .collection("transaction")
          .doc(transaction.id);

      final transactionSnapshot = await transactionRef.get();
      if (!transactionSnapshot.exists) {
        throw Exception("Transaction not found.");
      }

      final oldData = transactionSnapshot.data();
      final oldAmount = oldData?["amount"] ?? 0;
      final oldType = oldData?["type"] ?? '';

      // Update total balance, income, and expense based on the new data
      bool isOldExpense = oldType == 'EXPENSE';
      bool isNewExpense = transaction.type == 'EXPENSE';

      await FirebaseFirestore.instance.collection("Users").doc(uid).update({
        "totalBalance": FieldValue.increment(
            (isOldExpense ? oldAmount : -oldAmount) +
                (isNewExpense ? -transaction.amount : transaction.amount)),
        "income": FieldValue.increment((isOldExpense ? 0 : -oldAmount) +
            (isNewExpense ? 0 : transaction.amount)),
        "expense": FieldValue.increment((isOldExpense ? -oldAmount : 0) +
            (isNewExpense ? transaction.amount : 0)),
      });

      // Update the transaction fields
      await transactionRef.update({
        "title": transaction.title,
        "amount": transaction.amount,
        "date": transaction.date,
        "category": transaction.category,
        "type": transaction.type,
      });
      print("Transaction updated successfully");
    } catch (e) {
      print("Failed to update transaction: $e");
      rethrow;
    }
  }

  Future<void> deleteTransaction(
      String uid, String transactionId, double amount, String type) async {
    bool isExpense = TransactionType.EXPENSE.name == type;

    // Delete the transaction document from Firestore
    await FirebaseFirestore.instance
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .doc(transactionId)
        .delete();

    // Update user's totalBalance, income, and expense fields
    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "totalBalance": FieldValue.increment(isExpense ? amount : -amount),
      "income": isExpense
          ? FieldValue.increment(0)
          : FieldValue.increment(-amount), // Decrease income if not an expense
      "expense": isExpense
          ? FieldValue.increment(-amount)
          : FieldValue.increment(0), // Decrease expense if it's an expense
    });
  }

  Future<Map<String, Map<String, double>>> getTransactionsGroupedByDay(
      String uid) async {
    final DateTime now = DateTime.now();
    final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    final snapshot = await FirebaseFirestore.instance
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy("date", descending: true)
        .get();

    // Create maps for income and expense transactions
    Map<String, double> incomeTransactions = {};
    Map<String, double> expenseTransactions = {};

    for (var doc in snapshot.docs) {
      Map<String, dynamic> transaction = doc.data();
      DateTime transactionDate = (transaction["date"] as Timestamp).toDate();
      String dayKey = DateFormat('yyyy-MM-dd').format(transactionDate);

      double amount = (transaction["amount"])?.toDouble() ?? 0.0;
      String type = transaction["type"];

      // Add the amount to the corresponding map (income or expense)
      if (type == TransactionType.EXPENSE.name) {
        if (!expenseTransactions.containsKey(dayKey)) {
          expenseTransactions[dayKey] = 0.0;
        }
        expenseTransactions[dayKey] = expenseTransactions[dayKey]! + amount;
      } else {
        if (!incomeTransactions.containsKey(dayKey)) {
          incomeTransactions[dayKey] = 0.0;
        }
        incomeTransactions[dayKey] = incomeTransactions[dayKey]! + amount;
      }
    }

    return {
      'income': incomeTransactions,
      'expense': expenseTransactions,
    };
  }
}
