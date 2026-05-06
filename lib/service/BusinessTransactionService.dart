import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/BusinessTransaction.dart';

class BusinessTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection path helper:
  /// BusinessTransactions/{businessId}/transactions/{transactionId}
  CollectionReference _ref(String businessId) {
    return _firestore
        .collection("BusinessTransactions")
        .doc(businessId)
        .collection("transactions");
  }

  /// CREATE
  Future<String> addTransaction(
    String businessId,
    BusinessTransaction transaction,
  ) async {
    try {
      DocumentReference docRef = await _ref(businessId).add(
        transaction.toMap(),
      );

      return docRef.id;
    } catch (e) {
      throw Exception("Failed to add transaction: $e");
    }
  }

  /// READ ALL (for a business)
  Stream<List<BusinessTransaction>> getTransactions(String businessId) {
    return _ref(businessId)
        .orderBy("date", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BusinessTransaction.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  /// READ SINGLE
  Future<BusinessTransaction?> getTransactionById(
    String businessId,
    String transactionId,
  ) async {
    try {
      DocumentSnapshot doc = await _ref(businessId).doc(transactionId).get();

      if (doc.exists) {
        return BusinessTransaction.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get transaction: $e");
    }
  }

  /// UPDATE
  Future<void> updateTransaction(
    String businessId,
    String transactionId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _ref(businessId).doc(transactionId).update(data);
    } catch (e) {
      throw Exception("Failed to update transaction: $e");
    }
  }

  /// DELETE
  Future<void> deleteTransaction(
    String businessId,
    String transactionId,
  ) async {
    try {
      await _ref(businessId).doc(transactionId).delete();
    } catch (e) {
      throw Exception("Failed to delete transaction: $e");
    }
  }
}
