import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/models/Transaction.dart';
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

  Future<void> addUserToDatabase(String uid, email, username) async {
    await firestore.collection("Users").doc(uid).set({
      'uid': uid,
      "email": email,
      "username": username,
      "income": 0,
      "expense": 0,
      "totalBalance": 0
    });
  }

  Stream<List<Map<String, dynamic>>> getTransactionsOfUser(String uid) {
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

  Future<void> updateUserData(
    String uid,
    int amount,
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
      String uid, String transactionId, int amount, String type) async {
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
}
