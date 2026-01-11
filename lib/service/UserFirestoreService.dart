import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/transaction/TransactionType.dart';

class UserFirestoreService{
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
    Stream<List<Map<String, dynamic>>> getUserDataByEmail(String email) {
    return firestore
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
}