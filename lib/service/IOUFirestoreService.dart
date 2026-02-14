import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';
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
  Stream<List<IOU>> getIOUsStream(String uid) async* {
    final cacheKey = 'ious_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      yield cached.map((map) => IOU.fromMap(map)).toList(growable: false);
    }

    yield* firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .orderBy("date", descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final data =
          snapshot.docs.map((doc) => doc.data()).toList(growable: false);
      await OfflineCacheService.saveList(cacheKey, data);
      return data.map((doc) => IOU.fromMap(doc)).toList(growable: false);
    });
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
