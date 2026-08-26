import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/enums/splitBill/SettlementStatus.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/models/SettlementRequest.dart';
import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';
import 'package:uuid/uuid.dart';

/// Raised when a settlement cannot proceed for a reason worth showing the user
/// — a stale request, an amount that no longer fits, a bill that vanished.
class SettlementException implements Exception {
  final String message;
  const SettlementException(this.message);

  @override
  String toString() => message;
}

class SplitBillsFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Both mirrors of one debt share this id, so a settlement can address the
  /// pair without a lookup.
  static String iouIdFor(String billId, String payeeUid) =>
      '${billId}_$payeeUid';

  static double _round(double value) =>
      double.parse(value.toStringAsFixed(2));

  DocumentReference<Map<String, dynamic>> _billRef(
          String ownerUid, String billId) =>
      firestore
          .collection("SplitBills")
          .doc(ownerUid)
          .collection("bills")
          .doc(billId);

  CollectionReference<Map<String, dynamic>> _settlementsRef(
          String ownerUid, String billId) =>
      _billRef(ownerUid, billId).collection("settlements");

  DocumentReference<Map<String, dynamic>> _iouRef(String uid, String iouId) =>
      firestore.collection("IOUs").doc(uid).collection("iou").doc(iouId);

  // ───────────────────────────────────────────────────────────────────────────
  // Creation
  // ───────────────────────────────────────────────────────────────────────────

  /// Writes the bill and both sides of every debt in a single batch.
  ///
  /// For each payee with a non-zero share this creates two mirrored IOUs:
  /// an `OWED` row under the payer and an `OWE` row under the payee, sharing
  /// the id [iouIdFor]. Batching means the payer can never end up holding
  /// three IOUs while one payee holds none.
  Future<void> createSplitBillWithIOUs(SplitBill splitBill) async {
    final batch = firestore.batch();
    final payerUid = splitBill.paidBy;
    final payerName = splitBill.nameOf(payerUid, fallback: 'Someone');

    // Everyone starts at zero settled.
    final seededSettled = <String, double>{
      for (final uid in splitBill.participants) uid: 0.0,
    };
    final billToWrite = splitBill.copyWith(
      settledAmounts: seededSettled,
      status: 'ACTIVE',
      pendingSettlements: const {},
    );

    batch.set(_billRef(payerUid, splitBill.id), billToWrite.toMap());

    for (final payeeUid in splitBill.payees) {
      final share = _round(splitBill.shareOf(payeeUid));
      if (share <= 0) continue; // nobody owes nothing

      final iouId = iouIdFor(splitBill.id, payeeUid);
      final payeeName = splitBill.nameOf(payeeUid, fallback: 'Someone');
      final description = splitBill.title;

      // Payer's side — this person owes me.
      batch.set(
        _iouRef(payerUid, iouId),
        IOU(
          id: iouId,
          personName: payeeName,
          amount: share,
          description: description,
          date: splitBill.date,
          iouType: IOUType.OWED,
          status: IOUStatus.PENDING,
          category: splitBill.category,
          settledAmount: 0.0,
          splitBillId: splitBill.id,
          splitBillOwnerId: payerUid,
          counterpartyUid: payeeUid,
        ).toMap(),
      );

      // Payee's side — I owe the payer.
      batch.set(
        _iouRef(payeeUid, iouId),
        IOU(
          id: iouId,
          personName: payerName,
          amount: share,
          description: description,
          date: splitBill.date,
          iouType: IOUType.OWE,
          status: IOUStatus.PENDING,
          category: splitBill.category,
          settledAmount: 0.0,
          splitBillId: splitBill.id,
          splitBillOwnerId: payerUid,
          counterpartyUid: payerUid,
        ).toMap(),
      );
    }

    await batch.commit();
  }

  /// Kept for callers that only want the bill document.
  Future<void> addSplitBill(String uid, SplitBill splitBill) async {
    await _billRef(uid, splitBill.id).set(splitBill.toMap());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Reads
  // ───────────────────────────────────────────────────────────────────────────

  /// Stream all split bills the user takes part in, across every payer.
  Stream<List<SplitBill>> getSplitBillsStream(String uid) async* {
    final cacheKey = 'splitbills_$uid';

    final cached = await OfflineCacheService.readList(cacheKey);

    if (cached != null) {
      try {
        yield cached
            .map((map) => SplitBill.fromMap(map))
            .where((bill) => bill.id.isNotEmpty)
            .toList(growable: false);
      } catch (_) {}
    }

    yield* firestore
        .collectionGroup("bills")
        .where("participants", arrayContains: uid)
        .orderBy("date", descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.docs.map((doc) => doc.data()).toList();

      await OfflineCacheService.saveList(cacheKey, data);

      return snapshot.docs
          .map((doc) => SplitBill.fromMap(doc.data(), fallbackId: doc.id))
          .where((bill) => bill.id.isNotEmpty)
          .toList(growable: false);
    });
  }

  /// Live view of one bill. The detail page needs this so approvals and
  /// settlements land on screen the moment they are written.
  Stream<SplitBill?> watchSplitBill(String ownerUid, String billId) {
    return _billRef(ownerUid, billId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SplitBill.fromMap(doc.data()!, fallbackId: doc.id);
    });
  }

  /// Get a specific split bill.
  Future<SplitBill?> getSplitBill(String uid, String billId) async {
    final doc = await _billRef(uid, billId).get();

    if (doc.exists && doc.data() != null) {
      return SplitBill.fromMap(doc.data()!, fallbackId: doc.id);
    }
    return null;
  }

  /// Every settlement request on a bill, newest first — the audit trail.
  Stream<List<SettlementRequest>> getSettlementRequestsStream(
      String ownerUid, String billId) {
    return _settlementsRef(ownerUid, billId)
        .orderBy("requestedAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SettlementRequest.fromMap(doc.data(), fallbackId: doc.id))
            .where((request) => request.id.isNotEmpty)
            .toList(growable: false));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Settlement — request side
  // ───────────────────────────────────────────────────────────────────────────

  /// A payee asks the payer to mark [amount] as paid back.
  ///
  /// Runs as a transaction against the bill so the "one open request per payee"
  /// rule and the "never more than you owe" rule are both enforced against
  /// fresh state, not against whatever the UI happened to be showing.
  Future<void> requestSettlement({
    required SplitBill bill,
    required String fromUid,
    required double amount,
    String note = '',
  }) async {
    final requestId = const Uuid().v4();
    final rounded = _round(amount);

    if (rounded <= 0) {
      throw const SettlementException('Enter an amount greater than zero.');
    }

    final billRef = _billRef(bill.paidBy, bill.id);
    final requestRef = _settlementsRef(bill.paidBy, bill.id).doc(requestId);
    final iouId = iouIdFor(bill.id, fromUid);
    final requestedAt = DateTime.now();

    await firestore.runTransaction((transaction) async {
      final billSnap = await transaction.get(billRef);
      if (!billSnap.exists || billSnap.data() == null) {
        throw const SettlementException('This split bill no longer exists.');
      }

      final fresh = SplitBill.fromMap(billSnap.data()!, fallbackId: bill.id);

      // The payer is owed by the others; they have nothing to settle, and a
      // request against themselves would have no approver.
      if (fromUid == fresh.paidBy) {
        throw const SettlementException(
            'You paid this bill — there is nothing for you to settle.');
      }
      if (!fresh.participants.contains(fromUid)) {
        throw const SettlementException(
            'You are not part of this split bill.');
      }

      if (fresh.hasPendingFor(fromUid)) {
        throw const SettlementException(
            'You already have a settlement waiting for approval on this bill.');
      }

      final settleable = fresh.settleableFor(fromUid);
      if (settleable <= 0) {
        throw const SettlementException(
            'You have nothing left to settle on this bill.');
      }
      if (rounded > settleable + kMoneyEpsilon) {
        throw SettlementException(
            'You can settle at most ${settleable.toStringAsFixed(2)} on this bill.');
      }

      final request = SettlementRequest(
        id: requestId,
        billId: bill.id,
        billOwnerId: bill.paidBy,
        fromUid: fromUid,
        toUid: bill.paidBy,
        amount: rounded,
        note: note.trim(),
        requestedAt: requestedAt,
        status: SettlementStatus.PENDING,
      );

      transaction.set(requestRef, request.toMap());

      transaction.update(billRef, {
        'pendingSettlements.$fromUid': PendingSettlement(
          requestId: requestId,
          amount: rounded,
          requestedAt: requestedAt,
          note: note.trim(),
        ).toMap(),
      });

      // Mirror the pending flag onto both IOU rows. merge:true because bills
      // created before mirrors existed have no IOU docs to update.
      for (final uid in [bill.paidBy, fromUid]) {
        transaction.set(
          _iouRef(uid, iouId),
          {'pendingSettleAmount': rounded},
          SetOptions(merge: true),
        );
      }
    });
  }

  /// The payee withdraws their own open request.
  Future<void> cancelSettlementRequest({
    required SplitBill bill,
    required String fromUid,
  }) async {
    final pending = bill.pendingRequestFor(fromUid);
    if (pending == null) {
      throw const SettlementException('There is no request to cancel.');
    }

    await _resolveRequest(
      bill: bill,
      requestId: pending.requestId,
      fromUid: fromUid,
      resolvedBy: fromUid,
      approve: false,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Settlement — approval side
  // ───────────────────────────────────────────────────────────────────────────

  /// The payer approves a request: the money moves on the bill and both mirrors.
  Future<void> approveSettlement({
    required SplitBill bill,
    required SettlementRequest request,
    required String approverUid,
  }) async {
    if (approverUid != bill.paidBy) {
      throw const SettlementException(
          'Only the person who paid can approve a settlement.');
    }
    await _resolveRequest(
      bill: bill,
      requestId: request.id,
      fromUid: request.fromUid,
      resolvedBy: approverUid,
      approve: true,
    );
  }

  /// The payer turns a request down. Nothing moves; the payee can try again.
  Future<void> rejectSettlement({
    required SplitBill bill,
    required SettlementRequest request,
    required String approverUid,
  }) async {
    if (approverUid != bill.paidBy) {
      throw const SettlementException(
          'Only the person who paid can reject a settlement.');
    }
    await _resolveRequest(
      bill: bill,
      requestId: request.id,
      fromUid: request.fromUid,
      resolvedBy: approverUid,
      approve: false,
    );
  }

  /// Shared body for approve, reject and cancel.
  ///
  /// Reads the bill and the request together so two approvers racing the same
  /// request cannot both succeed — the second finds it already resolved.
  Future<void> _resolveRequest({
    required SplitBill bill,
    required String requestId,
    required String fromUid,
    required String resolvedBy,
    required bool approve,
  }) async {
    final billRef = _billRef(bill.paidBy, bill.id);
    final requestRef = _settlementsRef(bill.paidBy, bill.id).doc(requestId);
    final iouId = iouIdFor(bill.id, fromUid);
    final resolvedAt = DateTime.now();

    await firestore.runTransaction((transaction) async {
      final billSnap = await transaction.get(billRef);
      final requestSnap = await transaction.get(requestRef);

      if (!billSnap.exists || billSnap.data() == null) {
        throw const SettlementException('This split bill no longer exists.');
      }
      if (!requestSnap.exists || requestSnap.data() == null) {
        throw const SettlementException(
            'This settlement request no longer exists.');
      }

      final fresh = SplitBill.fromMap(billSnap.data()!, fallbackId: bill.id);
      final request =
          SettlementRequest.fromMap(requestSnap.data()!, fallbackId: requestId);

      if (!request.isPending) {
        throw const SettlementException(
            'This request has already been handled.');
      }

      final billUpdates = <String, dynamic>{
        'pendingSettlements.$fromUid': FieldValue.delete(),
      };
      final iouUpdates = <String, dynamic>{'pendingSettleAmount': 0.0};

      if (approve) {
        final share = fresh.shareOf(fromUid);
        // Clamp so an approval can never push someone past their share, even
        // if the bill was edited after the request went out.
        final rawSettled = fresh.settledOf(fromUid) + request.amount;
        final newSettled = _round(rawSettled > share ? share : rawSettled);

        billUpdates['settledAmounts.$fromUid'] = newSettled;

        final projected = fresh.copyWith(
          settledAmounts: {...fresh.settledAmounts, fromUid: newSettled},
        );
        billUpdates['status'] = projected.isFullySettled ? 'SETTLED' : 'ACTIVE';

        iouUpdates['settledAmount'] = newSettled;
        iouUpdates['status'] = (share - newSettled) <= kMoneyEpsilon
            ? IOUStatus.SETTLED.name
            : IOUStatus.PENDING.name;
      }

      transaction.update(billRef, billUpdates);
      transaction.update(requestRef, {
        'status': approve
            ? SettlementStatus.APPROVED.name
            : SettlementStatus.REJECTED.name,
        'resolvedAt': Timestamp.fromDate(resolvedAt),
        'resolvedBy': resolvedBy,
      });

      for (final uid in [bill.paidBy, fromUid]) {
        transaction.set(_iouRef(uid, iouId), iouUpdates, SetOptions(merge: true));
      }
    });
  }

  /// The payer records money they already received — cash, an offline transfer.
  ///
  /// No approval stage: the approver is the one doing it. Still writes an
  /// APPROVED request so the bill's history stays complete.
  Future<void> recordSettlementAsPayer({
    required SplitBill bill,
    required String payeeUid,
    required double amount,
    required String payerUid,
    String note = '',
  }) async {
    if (payerUid != bill.paidBy) {
      throw const SettlementException(
          'Only the person who paid can record a settlement.');
    }

    final rounded = _round(amount);
    if (rounded <= 0) {
      throw const SettlementException('Enter an amount greater than zero.');
    }

    final requestId = const Uuid().v4();
    final billRef = _billRef(bill.paidBy, bill.id);
    final requestRef = _settlementsRef(bill.paidBy, bill.id).doc(requestId);
    final iouId = iouIdFor(bill.id, payeeUid);
    final now = DateTime.now();

    await firestore.runTransaction((transaction) async {
      final billSnap = await transaction.get(billRef);
      if (!billSnap.exists || billSnap.data() == null) {
        throw const SettlementException('This split bill no longer exists.');
      }

      final fresh = SplitBill.fromMap(billSnap.data()!, fallbackId: bill.id);
      final remaining = fresh.remainingFor(payeeUid);

      if (remaining <= 0) {
        throw const SettlementException('This person is already settled up.');
      }

      // Recording alongside an open request would leave that request pending
      // against money already credited, and approving it later would count the
      // same payment twice. Make the payer resolve the request instead.
      if (fresh.hasPendingFor(payeeUid)) {
        throw SettlementException(
            '${fresh.nameOf(payeeUid, fallback: "This person")} has a settlement '
            'waiting for your approval. Approve or decline that first.');
      }
      if (rounded > remaining + kMoneyEpsilon) {
        throw SettlementException(
            'They only owe ${remaining.toStringAsFixed(2)} on this bill.');
      }

      final share = fresh.shareOf(payeeUid);
      final rawSettled = fresh.settledOf(payeeUid) + rounded;
      final newSettled = _round(rawSettled > share ? share : rawSettled);

      transaction.set(
        requestRef,
        SettlementRequest(
          id: requestId,
          billId: bill.id,
          billOwnerId: bill.paidBy,
          fromUid: payeeUid,
          toUid: bill.paidBy,
          amount: rounded,
          note: note.trim().isEmpty ? 'Recorded by payer' : note.trim(),
          requestedAt: now,
          status: SettlementStatus.APPROVED,
          resolvedAt: now,
          resolvedBy: payerUid,
        ).toMap(),
      );

      final projected = fresh.copyWith(
        settledAmounts: {...fresh.settledAmounts, payeeUid: newSettled},
      );

      transaction.update(billRef, <String, dynamic>{
        'settledAmounts.$payeeUid': newSettled,
        'status': projected.isFullySettled ? 'SETTLED' : 'ACTIVE',
      });

      final iouUpdates = {
        'settledAmount': newSettled,
        'pendingSettleAmount': 0.0,
        'status': (share - newSettled) <= kMoneyEpsilon
            ? IOUStatus.SETTLED.name
            : IOUStatus.PENDING.name,
      };

      for (final uid in [bill.paidBy, payeeUid]) {
        transaction.set(_iouRef(uid, iouId), iouUpdates, SetOptions(merge: true));
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Update / delete
  // ───────────────────────────────────────────────────────────────────────────

  /// Update a split bill.
  Future<void> updateSplitBill(String uid, SplitBill splitBill) async {
    await _billRef(uid, splitBill.id).update(splitBill.toMap());
  }

  /// Delete a bill together with everything that hangs off it — its settlement
  /// history and both mirrors of every debt. Leaving orphan IOUs behind would
  /// show people a debt with no bill to settle it against.
  Future<void> deleteSplitBill(SplitBill bill) async {
    final settlements = await _settlementsRef(bill.paidBy, bill.id).get();

    final batch = firestore.batch();

    for (final doc in settlements.docs) {
      batch.delete(doc.reference);
    }

    for (final payeeUid in bill.payees) {
      final iouId = iouIdFor(bill.id, payeeUid);
      batch.delete(_iouRef(bill.paidBy, iouId));
      batch.delete(_iouRef(payeeUid, iouId));
    }

    batch.delete(_billRef(bill.paidBy, bill.id));

    await batch.commit();
  }

  /// Delete by id only. Prefer [deleteSplitBill] — this cannot clean up the
  /// mirrors because it does not know who the participants were.
  Future<void> deleteSplitBillById(String uid, String billId) async {
    await _billRef(uid, billId).delete();
  }

  /// Get split bills by category (across all bills the user participates in)
  Stream<List<SplitBill>> getSplitBillsByCategory(
      String uid, String category) async* {
    yield* firestore
        .collectionGroup("bills")
        .where("participants", arrayContains: uid)
        .where("category", isEqualTo: category)
        .orderBy("date", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SplitBill.fromMap(doc.data(), fallbackId: doc.id))
            .where((bill) => bill.id.isNotEmpty)
            .toList());
  }
}
