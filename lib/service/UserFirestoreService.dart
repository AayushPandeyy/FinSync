import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/transaction/TransactionType.dart';
import 'package:finance_tracker/service/AuthFirestoreService.dart';

class UserFirestoreService{
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AuthFirestoreService firestoreService = AuthFirestoreService();
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

    Future<void> updateUserFinancialData(
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

   Future<void> updateAllUserFields({
    required String uid,
    required String email,
    required String username,
    required String phoneNumber,
    required double income,
    required double expense,
    required double totalBalance,
  }) async {
    await firestore.collection("Users").doc(uid).update({
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'income': income,
      'expense': expense,
      'totalBalance': totalBalance,
    });
  }

  /// 🔹 Update ONLY provided user fields (partial update)
  Future<void> updateByUserFields(
    String uid,
    Map<String, dynamic> fieldsToUpdate,
  ) async {
    await firestore.collection("Users").doc(uid).update(fieldsToUpdate);
  }

Future<void> deleteUser(String uid) async {
    // Delete subcollections FIRST
    await _deleteSubcollectionSafely("Transactions", uid, "transaction");
    await _deleteSubcollectionSafely("Budgets", uid, "budget");
    await _deleteSubcollectionSafely("Goals", uid, "goal");
    await _deleteSubcollectionSafely("IOUs", uid, "iou");

    // Then delete parent docs
    await firestore.collection("Transactions").doc(uid).delete();
    await firestore.collection("Budgets").doc(uid).delete();
    await firestore.collection("Goals").doc(uid).delete();
    await firestore.collection("IOUs").doc(uid).delete();
    await firestore.collection("Users").doc(uid).delete();

    await firestoreService.logout();
    await firestoreService.deleteUser();
  }


Future<void> _deleteSubcollectionSafely(
    String parentCollection,
    String uid,
    String subcollectionName,
  ) async {
    const int batchSize = 400;
    QuerySnapshot snapshot;

    do {
      snapshot = await firestore
          .collection(parentCollection)
          .doc(uid)
          .collection(subcollectionName)
          .limit(batchSize)
          .get();

      final batch = firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } while (snapshot.docs.isNotEmpty);
  }


}