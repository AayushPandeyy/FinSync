import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/models/Transaction.dart';

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
        .orderBy("date")
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

  Future<void> deleteTransaction(
      String uid, String transactionId, int amount, String type) async {
    bool isExpense = TransactionType.EXPENSE.name == type;
    await FirebaseFirestore.instance
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .doc(transactionId)
        .delete();
    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "totalBalance": FieldValue.increment(-amount),
      "income":
          isExpense ? FieldValue.increment(0) : FieldValue.increment(-amount),
      "expense":
          !isExpense ? FieldValue.increment(0) : FieldValue.increment(-amount),
    });
  }
}
