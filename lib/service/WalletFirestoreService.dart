import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/Wallet.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';

class WalletFirestoreService {
  final firestore = FirebaseFirestore.instance;

  /// Stream of wallets for a user
  Stream<List<Map<String, dynamic>>> getWalletsOfUser(String uid) async* {
    final cacheKey = 'wallets_$uid';
    final cached = await OfflineCacheService.readList(cacheKey);
    if (cached != null) {
      yield cached;
    }

    yield* firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .snapshots()
        .asyncMap((snapshot) async {
      final walletsData =
          snapshot.docs.map((doc) => doc.data()).toList(growable: false);
      await OfflineCacheService.saveList(cacheKey, walletsData);
      return walletsData;
    });
  }

  /// Initialize default wallets for a new user (Cash, Bank, Digital Wallet)
  Future<void> initializeDefaultWallets(String uid) async {
    final defaultWallets = WalletModel.getDefaultWallets(uid);
    for (final wallet in defaultWallets) {
      await firestore
          .collection("Wallets")
          .doc(uid)
          .collection("wallet")
          .doc(wallet.id)
          .set(wallet.toJson());
    }
  }

  /// Check if user has wallets; if not, create defaults
  Future<void> ensureWalletsExist(String uid) async {
    final snapshot = await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await initializeDefaultWallets(uid);
    }
  }

  /// Add a new wallet
  Future<void> addWallet(String uid, WalletModel wallet) async {
    await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .doc(wallet.id)
        .set(wallet.toJson());
  }

  /// Update wallet balance
  Future<void> updateWalletBalance(
      String uid, String walletId, double newBalance) async {
    await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .doc(walletId)
        .update({'balance': newBalance});
  }

  /// Update wallet details. If [oldName] is provided and differs from
  /// the new name, all transactions referencing the old wallet name
  /// will be updated to the new name.
  Future<void> updateWallet(String uid, WalletModel wallet,
      {String? oldName}) async {
    await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .doc(wallet.id)
        .update(wallet.toJson());

    // Rename wallet in all transactions if the name changed
    if (oldName != null && oldName.isNotEmpty && oldName != wallet.name) {
      final txSnapshot = await firestore
          .collection("Transactions")
          .doc(uid)
          .collection("transaction")
          .where("wallet", isEqualTo: oldName)
          .get();
      final batch = firestore.batch();
      for (final doc in txSnapshot.docs) {
        batch.update(doc.reference, {'wallet': wallet.name});
      }
      await batch.commit();
    }
  }

  /// Delete a wallet
  Future<void> deleteWallet(String uid, String walletId) async {
    await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .doc(walletId)
        .delete();
  }

  /// Stream per-wallet income & expense totals from transactions.
  /// Returns a Map<walletName, {income: double, expense: double}>.
  Stream<Map<String, Map<String, double>>> getWalletStats(String uid) {
    return firestore
        .collection("Transactions")
        .doc(uid)
        .collection("transaction")
        .snapshots()
        .map((snapshot) {
      final Map<String, Map<String, double>> stats = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final wallet = (data['wallet'] ?? 'Cash').toString();
        if (wallet.isEmpty) continue;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (data['type'] ?? '').toString();
        stats.putIfAbsent(wallet, () => {'income': 0.0, 'expense': 0.0});
        if (type == 'EXPENSE') {
          stats[wallet]!['expense'] = stats[wallet]!['expense']! + amount;
        } else {
          stats[wallet]!['income'] = stats[wallet]!['income']! + amount;
        }
      }
      return stats;
    });
  }
}
