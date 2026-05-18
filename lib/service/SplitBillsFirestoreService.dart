import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';

class SplitBillsFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Add a new split bill
  Future<void> addSplitBill(String uid, SplitBill splitBill) async {
    await firestore
        .collection("SplitBills")
        .doc(uid)
        .collection("bills")
        .doc(splitBill.id)
        .set(splitBill.toMap());
  }

  /// Stream all split bills
  Stream<List<SplitBill>> getSplitBillsStream(String uid) async* {
    final cacheKey = 'splitbills_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      try {
        yield cached
            .map((map) => SplitBill.fromMap(map))
            .where((bill) => bill.id.isNotEmpty)
            .toList(growable: false);
      } catch (_) {
        // Ignore a malformed cache payload and continue with network data.
      }
    }

    yield* firestore
        .collection("SplitBills")
        .doc(uid)
        .collection("bills")
        .orderBy("date", descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final data =
          snapshot.docs.map((doc) => doc.data()).toList(growable: false);
      await OfflineCacheService.saveList(cacheKey, data);
      return snapshot.docs
          .map((doc) => SplitBill.fromMap(doc.data(), fallbackId: doc.id))
          .where((bill) => bill.id.isNotEmpty)
          .toList(growable: false);
    });
  }

  /// Get a specific split bill
  Future<SplitBill?> getSplitBill(String uid, String billId) async {
    final doc = await firestore
        .collection("SplitBills")
        .doc(uid)
        .collection("bills")
        .doc(billId)
        .get();

    if (doc.exists) {
      return SplitBill.fromMap(doc.data()!, fallbackId: doc.id);
    }
    return null;
  }

  /// Update a split bill
  Future<void> updateSplitBill(String uid, SplitBill splitBill) async {
    await firestore
        .collection("SplitBills")
        .doc(uid)
        .collection("bills")
        .doc(splitBill.id)
        .update(splitBill.toMap());
  }

  /// Delete a split bill
  Future<void> deleteSplitBill(String uid, String billId) async {
    await firestore
        .collection("SplitBills")
        .doc(uid)
        .collection("bills")
        .doc(billId)
        .delete();
  }

  /// Get split bills by category
  Stream<List<SplitBill>> getSplitBillsByCategory(
      String uid, String category) async* {
    yield* firestore
        .collection("SplitBills")
        .doc(uid)
        .collection("bills")
        .where("category", isEqualTo: category)
        .orderBy("date", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SplitBill.fromMap(doc.data(), fallbackId: doc.id))
            .toList());
  }
}
