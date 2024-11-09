import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> addTransaction(String uid) async {
    String docId = uid + DateTime.now().toString();
    await firestore
        .collection('Transactions')
        .doc(uid)
        .collection("transaction")
        .doc(docId)
        .set({
      "uid": docId,
    });
  }
}
