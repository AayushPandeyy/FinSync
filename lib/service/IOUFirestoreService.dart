import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';

class Ioufirestoreservice {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TransactionFirestoreService transactionFirestoreService = TransactionFirestoreService();

  Future<void> addIOU(String uid, IOU iou) async {
    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iou.id)
        .set({
      "id": iou.id,
      "personName":iou.personName,
      "amount":iou.amount,
      "description":iou.description,
      "date":iou.date,
      "dueDate":iou.dueDate,
      "iouType":iou.iouType.name,
      "status":iou.status.name,
    });
  }

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


Future<void> updateIOU(String uid, IOU iou) async {
    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iou.id)
        .update({
      "personName": iou.personName,
      "amount": iou.amount,
      "description": iou.description,
      "date": iou.date,
      "dueDate": iou.dueDate,
      "iouType": iou.iouType.name,
      "status": iou.status.name,
    });
  }

  Future<void> updateIOUFields(
    String uid,
    String iouId, {
    String? personName,
    double? amount,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    String? iouType,
    String? status,
  }) async {
    final Map<String, dynamic> updates = {};

    if (personName != null) updates["personName"] = personName;
    if (amount != null) updates["amount"] = amount;
    if (description != null) updates["description"] = description;
    if (date != null) updates["date"] = date;
    if (dueDate != null) updates["dueDate"] = dueDate;
    if (iouType != null) updates["iouType"] = iouType;
    if (status != null) updates["status"] = status;

    if (updates.isEmpty) return;

    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iouId)
        .update(updates);
  }


Future<void> deleteIOU(String uid, String iouId) async {
    await firestore
        .collection("IOUs")
        .doc(uid)
        .collection("iou")
        .doc(iouId)
        .delete();
  }

}
