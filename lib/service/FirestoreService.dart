import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/models/Transaction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUserDataByEmail(String email) {
    return FirebaseFirestore.instance
        .collection('Users') // The name of your collection
        .where('email', isEqualTo: email)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Future<void> addUserToDatabase(
      String uid, email, username, phoneNumber) async {
    await firestore.collection("Users").doc(uid).set({
      'uid': uid,
      "email": email,
      "username": username,
      "phoneNumber": phoneNumber,
      "income": 0,
      "expense": 0,
      "totalBalance": 0
    });
  }

  Stream<List<Map<String, dynamic>>> getRecentTransactionsOfUser(String uid) {
    return FirebaseFirestore.instance
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .orderBy("date", descending: true)
        .limit(7)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final transactionData = doc.data();
        return transactionData;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactionsOfUser(String uid) {
    return FirebaseFirestore.instance
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .orderBy("date", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final transactionData = doc.data();
        return transactionData;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getGoalsOfUser(String uid) {
    return FirebaseFirestore.instance
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final goalsData = doc.data();
        return goalsData;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactionsBasedOnType(
      String uid, type) {
    return FirebaseFirestore.instance
        .collection("Transactions")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("transaction")
        .where("type", isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final transactionData = doc.data();
        return transactionData;
      }).toList();
    });
  }

  Future<void> addTransaction(String uid, TransactionModel transaction) async {
    await updateUserData(uid, transaction.amount, transaction.type);
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

  Stream<double> getTotalAmountInACategory(String category) {
    return FirebaseFirestore.instance
        .collection("Transactions")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("transaction")
        .where("category", isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += int.parse(doc['amount'].toString());
      }
      return total;
    });
  }

  Future<void> addGoals(String uid, FinancialGoal goal) async {
    await firestore
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .doc(goal.id)
        .set({
      "id": goal.id,
      "title": goal.title,
      "deadline": goal.deadline,
      "description": goal.description,
      "amount": goal.targetAmount
    });
  }

  Future<void> updateUserData(
    String uid,
    double amount,
    String type,
  ) async {
    bool isExpense = TransactionType.EXPENSE.name == type;
    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "totalBalance": isExpense
          ? FieldValue.increment(-amount)
          : FieldValue.increment(amount),
      "income":
          isExpense ? FieldValue.increment(0) : FieldValue.increment(amount),
      "expense":
          !isExpense ? FieldValue.increment(0) : FieldValue.increment(amount),
    });
  }

  Future<void> updateGoal(String uid, FinancialGoal goal) async {
    print("id is ${goal.id}");
    await FirebaseFirestore.instance
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .doc(goal.id)
        .update({
      "id": goal.id,
      "title": goal.title,
      "deadline": goal.deadline,
      "description": goal.description,
      "amount": goal.targetAmount
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

  Future<void> deleteGoal(String uid, FinancialGoal goal) async {
    await FirebaseFirestore.instance
        .collection("Goals")
        .doc(uid)
        .collection("goal")
        .doc(goal.id)
        .delete();
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

      double amount = transaction["amount"]?.toDouble() ?? 0.0;
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
