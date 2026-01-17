import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';

class Ioufirestoreservice {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TransactionFirestoreService transactionFirestoreService =
      TransactionFirestoreService();

  /// Add a new IOU
  Future<void> addIOU(String uid, IOU iou) async {
    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iou.id)
        .set(iou.toMap()); // use toMap for consistency
  }

  /// Stream all IOUs
  Stream<List<IOU>> getIOUsStream(String uid) {
    return firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .orderBy("date", descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => IOU.fromMap(doc.data())).toList(),
        );
  }

  /// Update entire IOU
  Future<void> updateIOU(String uid, IOU iou) async {
    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iou.id)
        .update(iou.toMap()); // use toMap for consistency
  }

  /// Update selected fields
  Future<void> updateIOUFields(
    String uid,
    String iouId, {
    String? personName,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? iouType,
    String? status,
    String? category,
    double? settledAmount, // NEW
  }) async {
    final Map<String, dynamic> updates = {};

    if (personName != null) updates["personName"] = personName;
    if (amount != null) updates["amount"] = amount;
    if (description != null) updates["description"] = description;

    if (date != null) updates["date"] = Timestamp.fromDate(date);
    if (dueDate != null) updates["dueDate"] = Timestamp.fromDate(dueDate);
    if (clearDueDate) updates["dueDate"] = FieldValue.delete();

    if (iouType != null) updates["iouType"] = iouType;
    if (status != null) updates["status"] = status;
    if (category != null) updates["category"] = category;
    if (settledAmount != null) updates["settledAmount"] = settledAmount; // NEW

    if (updates.isEmpty) return;

    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iouId)
        .update(updates);
  }

  /// Delete IOU
  Future<void> deleteIOU(String uid, String iouId) async {
    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iouId)
        .delete();
  }
}
