import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/family/FamilyRole.dart';
import 'package:finance_tracker/models/Family.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// Firestore access for family mode.
///
/// Layout:
/// ```
/// Families/{familyId}
///   ├─ members/{uid}
///   ├─ joinRequests/{uid}
///   ├─ transactions/{txId}
///   └─ subscriptions/{subId}
/// ```
/// The family document carries `memberIds` / `adminIds` arrays so membership
/// and permission checks are a single read, and running `income` / `expense` /
/// `totalBalance` totals so the dashboard never has to sum the whole history.
class FamilyFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static const String _familiesCollection = 'Families';
  static const String _membersCollection = 'members';
  static const String _joinRequestsCollection = 'joinRequests';
  static const String _transactionsCollection = 'transactions';
  static const String _subscriptionsCollection = 'subscriptions';

  CollectionReference<Map<String, dynamic>> get _families =>
      firestore.collection(_familiesCollection);

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) =>
      _families.doc(familyId);

  CollectionReference<Map<String, dynamic>> _members(String familyId) =>
      _familyDoc(familyId).collection(_membersCollection);

  CollectionReference<Map<String, dynamic>> _joinRequests(String familyId) =>
      _familyDoc(familyId).collection(_joinRequestsCollection);

  CollectionReference<Map<String, dynamic>> _transactions(String familyId) =>
      _familyDoc(familyId).collection(_transactionsCollection);

  CollectionReference<Map<String, dynamic>> _subscriptions(String familyId) =>
      _familyDoc(familyId).collection(_subscriptionsCollection);

  // ─── Codes ────────────────────────────────────────────────────────────────

  /// Ambiguous glyphs (0/O, 1/I) are left out so codes survive being read aloud.
  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _randomCode([int length = 6]) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _codeAlphabet[random.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// Generates a code that no existing family is using.
  Future<String> _generateUniqueCode() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _randomCode();
      final existing =
          await _families.where('code', isEqualTo: code).limit(1).get();
      if (existing.docs.isEmpty) return code;
    }
    // Astronomically unlikely; fall back to a longer code rather than failing.
    return _randomCode(8);
  }

  // ─── Family lifecycle ─────────────────────────────────────────────────────

  /// Creates a family with [creatorUid] as its first admin and returns its id.
  Future<Family> createFamily({
    required String creatorUid,
    required String creatorName,
    required String creatorEmail,
    required String familyName,
    required String designation,
  }) async {
    final familyId = const Uuid().v4();
    final code = await _generateUniqueCode();
    final now = DateTime.now();

    final family = Family(
      id: familyId,
      name: familyName,
      code: code,
      createdBy: creatorUid,
      createdAt: now,
      memberIds: [creatorUid],
      adminIds: [creatorUid],
    );

    final batch = firestore.batch();

    batch.set(_familyDoc(familyId), {
      'id': familyId,
      'name': familyName,
      'code': code,
      'createdBy': creatorUid,
      'createdAt': Timestamp.fromDate(now),
      'memberIds': [creatorUid],
      'adminIds': [creatorUid],
      'income': 0.0,
      'expense': 0.0,
      'totalBalance': 0.0,
    });

    batch.set(
      _members(familyId).doc(creatorUid),
      FamilyMember(
        uid: creatorUid,
        username: creatorName,
        email: creatorEmail,
        role: FamilyRole.admin,
        designation: designation,
        joinedAt: now,
      ).toMap(),
    );

    await batch.commit();
    return family;
  }

  /// Every family the user belongs to. Most users have exactly one.
  Stream<List<Family>> getMyFamilies(String uid) {
    return _families
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Family.fromMap(doc.id, doc.data()))
            .toList(growable: false));
  }

  Stream<Family?> getFamily(String familyId) {
    return _familyDoc(familyId).snapshots().map(
          (doc) => doc.exists ? Family.fromMap(doc.id, doc.data()!) : null,
        );
  }

  Future<Family?> findFamilyByCode(String code) async {
    final normalised = code.trim().toUpperCase();
    if (normalised.isEmpty) return null;

    final snapshot =
        await _families.where('code', isEqualTo: normalised).limit(1).get();
    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return Family.fromMap(doc.id, doc.data());
  }

  /// Rotates the invite code — useful once a code has been shared too widely.
  Future<String> regenerateCode(String familyId) async {
    final code = await _generateUniqueCode();
    await _familyDoc(familyId).update({'code': code});
    return code;
  }

  Future<void> renameFamily(String familyId, String name) {
    return _familyDoc(familyId).update({'name': name});
  }

  // ─── Joining ──────────────────────────────────────────────────────────────

  /// Files a request to join the family behind [code].
  ///
  /// Members are never added directly: an admin has to approve the request,
  /// which is what keeps "only admin can add new members" true even though the
  /// code itself is shareable.
  ///
  /// Returns the family that was found so the UI can name it back to the user.
  Future<Family> requestToJoin({
    required String code,
    required String uid,
    required String username,
    required String email,
    required String designation,
  }) async {
    final family = await findFamilyByCode(code);
    if (family == null) {
      throw FamilyException('No family found with that code.');
    }
    if (family.memberIds.contains(uid)) {
      throw FamilyException('You are already a member of ${family.name}.');
    }

    final existing = await _joinRequests(family.id).doc(uid).get();
    if (existing.exists &&
        JoinRequestStatusX.fromValue(existing.data()?['status']?.toString()) ==
            JoinRequestStatus.pending) {
      throw FamilyException(
        'You already have a pending request for ${family.name}.',
      );
    }

    await _joinRequests(family.id).doc(uid).set({
      'uid': uid,
      'username': username,
      'email': email,
      'designation': designation,
      'status': JoinRequestStatus.pending.value,
      'requestedAt': Timestamp.fromDate(DateTime.now()),
      'familyId': family.id,
      'familyName': family.name,
    });

    return family;
  }

  Stream<List<FamilyJoinRequest>> getPendingRequests(String familyId) {
    return _joinRequests(familyId)
        .where('status', isEqualTo: JoinRequestStatus.pending.value)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyJoinRequest.fromMap(doc.id, doc.data()))
            .toList(growable: false));
  }

  /// A member's own view of where their request stands, so the join screen can
  /// show "waiting for approval" instead of an empty state.
  Stream<FamilyJoinRequest?> watchMyRequest(String familyId, String uid) {
    return _joinRequests(familyId).doc(uid).snapshots().map(
          (doc) =>
              doc.exists ? FamilyJoinRequest.fromMap(doc.id, doc.data()!) : null,
        );
  }

  /// Any pending request this user has filed, across all families.
  Future<List<FamilyJoinRequest>> getMyPendingRequests(String uid) async {
    final snapshot = await firestore
        .collectionGroup(_joinRequestsCollection)
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: JoinRequestStatus.pending.value)
        .get();

    return snapshot.docs
        .map((doc) => FamilyJoinRequest.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  /// Admin-only: turns a pending request into a member.
  Future<void> approveRequest({
    required String familyId,
    required FamilyJoinRequest request,
  }) async {
    final batch = firestore.batch();

    batch.set(
      _members(familyId).doc(request.uid),
      FamilyMember(
        uid: request.uid,
        username: request.username,
        email: request.email,
        role: FamilyRole.member,
        designation: request.designation,
        joinedAt: DateTime.now(),
      ).toMap(),
    );

    batch.update(_familyDoc(familyId), {
      'memberIds': FieldValue.arrayUnion([request.uid]),
    });

    batch.update(_joinRequests(familyId).doc(request.uid), {
      'status': JoinRequestStatus.approved.value,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  Future<void> rejectRequest({
    required String familyId,
    required String uid,
  }) {
    return _joinRequests(familyId).doc(uid).update({
      'status': JoinRequestStatus.rejected.value,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> cancelMyRequest({
    required String familyId,
    required String uid,
  }) {
    return _joinRequests(familyId).doc(uid).delete();
  }

  // ─── Members ──────────────────────────────────────────────────────────────

  Stream<List<FamilyMember>> getMembers(String familyId) {
    return _members(familyId).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FamilyMember.fromMap(doc.id, doc.data()))
        .toList(growable: false));
  }

  Stream<FamilyMember?> watchMember(String familyId, String uid) {
    return _members(familyId).doc(uid).snapshots().map(
          (doc) => doc.exists ? FamilyMember.fromMap(doc.id, doc.data()!) : null,
        );
  }

  Future<FamilyMember?> getMemberOnce(String familyId, String uid) async {
    final doc = await _members(familyId).doc(uid).get();
    if (!doc.exists) return null;
    return FamilyMember.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateDesignation({
    required String familyId,
    required String uid,
    required String designation,
  }) {
    return _members(familyId).doc(uid).update({'designation': designation});
  }

  /// Admin-only: promote a member, or demote an admin back to member.
  Future<void> setRole({
    required String familyId,
    required String uid,
    required FamilyRole role,
  }) async {
    final batch = firestore.batch();

    batch.update(_members(familyId).doc(uid), {'role': role.value});
    batch.update(_familyDoc(familyId), {
      'adminIds': role == FamilyRole.admin
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });

    await batch.commit();
  }

  /// Admin-only: drop someone from the family. Their past entries stay in the
  /// shared ledger — removing them would silently change everyone's totals.
  Future<void> removeMember({
    required String familyId,
    required String uid,
  }) async {
    final batch = firestore.batch();

    batch.delete(_members(familyId).doc(uid));
    batch.update(_familyDoc(familyId), {
      'memberIds': FieldValue.arrayRemove([uid]),
      'adminIds': FieldValue.arrayRemove([uid]),
    });

    await batch.commit();
  }

  /// Leaving is the self-service version of [removeMember]. The last admin is
  /// blocked so a family can never end up with nobody able to manage it.
  Future<void> leaveFamily({
    required String familyId,
    required String uid,
  }) async {
    final doc = await _familyDoc(familyId).get();
    if (!doc.exists) return;

    final family = Family.fromMap(doc.id, doc.data()!);
    if (family.adminIds.length == 1 && family.adminIds.contains(uid)) {
      throw FamilyException(
        'You are the only admin. Promote another member before leaving.',
      );
    }

    await removeMember(familyId: familyId, uid: uid);
  }

  // ─── Transactions ─────────────────────────────────────────────────────────

  Stream<List<FamilyTransaction>> getTransactions(String familyId,
      {int? limit}) {
    Query<Map<String, dynamic>> query =
        _transactions(familyId).orderBy('date', descending: true);
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FamilyTransaction.fromMap(doc.id, doc.data()))
        .toList(growable: false));
  }

  Stream<List<FamilyTransaction>> getTransactionsByType(
    String familyId,
    String type,
  ) {
    return _transactions(familyId)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => FamilyTransaction.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.date.compareTo(a.date));
      return items;
    });
  }

  /// Writes the entry and folds it into both the family totals and the
  /// author's own contribution counters in one batch.
  Future<void> addTransaction({
    required String familyId,
    required FamilyTransaction transaction,
  }) async {
    final isExpense = transaction.isExpense;
    final signed = isExpense ? -transaction.amount : transaction.amount;

    final batch = firestore.batch();

    batch.set(
      _transactions(familyId).doc(transaction.id),
      transaction.toMap(),
    );

    batch.update(_familyDoc(familyId), {
      'totalBalance': FieldValue.increment(signed),
      'income': FieldValue.increment(isExpense ? 0 : transaction.amount),
      'expense': FieldValue.increment(isExpense ? transaction.amount : 0),
    });

    batch.update(_members(familyId).doc(transaction.createdBy), {
      'income': FieldValue.increment(isExpense ? 0 : transaction.amount),
      'expense': FieldValue.increment(isExpense ? transaction.amount : 0),
    });

    await batch.commit();
  }

  Future<void> updateTransaction({
    required String familyId,
    required FamilyTransaction transaction,
  }) async {
    final ref = _transactions(familyId).doc(transaction.id);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      throw FamilyException('That transaction no longer exists.');
    }

    final old = FamilyTransaction.fromMap(snapshot.id, snapshot.data()!);
    final oldSigned = old.isExpense ? -old.amount : old.amount;
    final newSigned =
        transaction.isExpense ? -transaction.amount : transaction.amount;

    final incomeDelta = (old.isExpense ? 0.0 : -old.amount) +
        (transaction.isExpense ? 0.0 : transaction.amount);
    final expenseDelta = (old.isExpense ? -old.amount : 0.0) +
        (transaction.isExpense ? transaction.amount : 0.0);

    final batch = firestore.batch();

    // The author never changes on edit, so `old.createdBy` stays authoritative.
    batch.update(ref, {
      'title': transaction.title,
      'amount': transaction.amount,
      'date': Timestamp.fromDate(transaction.date),
      'description': transaction.description,
      'category': transaction.category,
      'type': transaction.type,
    });

    batch.update(_familyDoc(familyId), {
      'totalBalance': FieldValue.increment(newSigned - oldSigned),
      'income': FieldValue.increment(incomeDelta),
      'expense': FieldValue.increment(expenseDelta),
    });

    batch.update(_members(familyId).doc(old.createdBy), {
      'income': FieldValue.increment(incomeDelta),
      'expense': FieldValue.increment(expenseDelta),
    });

    await batch.commit();
  }

  Future<void> deleteTransaction({
    required String familyId,
    required FamilyTransaction transaction,
  }) async {
    final isExpense = transaction.isExpense;
    final signed = isExpense ? -transaction.amount : transaction.amount;

    final batch = firestore.batch();

    batch.delete(_transactions(familyId).doc(transaction.id));

    batch.update(_familyDoc(familyId), {
      'totalBalance': FieldValue.increment(-signed),
      'income': FieldValue.increment(isExpense ? 0 : -transaction.amount),
      'expense': FieldValue.increment(isExpense ? -transaction.amount : 0),
    });

    if (transaction.createdBy.isNotEmpty) {
      batch.update(_members(familyId).doc(transaction.createdBy), {
        'income': FieldValue.increment(isExpense ? 0 : -transaction.amount),
        'expense': FieldValue.increment(isExpense ? -transaction.amount : 0),
      });
    }

    await batch.commit();
  }

  // ─── Subscriptions ────────────────────────────────────────────────────────

  Stream<List<FamilySubscription>> getSubscriptions(String familyId) {
    return _subscriptions(familyId).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => FamilySubscription.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
      return items;
    });
  }

  Future<void> addSubscription({
    required String familyId,
    required FamilySubscription subscription,
  }) {
    return _subscriptions(familyId)
        .doc(subscription.id)
        .set(subscription.toMap());
  }

  Future<void> updateSubscription({
    required String familyId,
    required FamilySubscription subscription,
  }) {
    return _subscriptions(familyId)
        .doc(subscription.id)
        .update(subscription.toMap());
  }

  Future<void> setSubscriptionActive({
    required String familyId,
    required String subscriptionId,
    required bool isActive,
  }) {
    return _subscriptions(familyId)
        .doc(subscriptionId)
        .update({'isActive': isActive});
  }

  Future<void> deleteSubscription({
    required String familyId,
    required String subscriptionId,
  }) {
    return _subscriptions(familyId).doc(subscriptionId).delete();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
}

/// Failure with a message that is safe to show the user as-is.
class FamilyException implements Exception {
  FamilyException(this.message);

  final String message;

  @override
  String toString() => message;
}
