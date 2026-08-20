import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/models/Wallet.dart';
import 'package:finance_tracker/service/OfflineCacheService.dart';
import 'package:finance_tracker/utilities/TransferRules.dart';

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

  /// Transactions reference a wallet by *name*, so two wallets sharing one name
  /// would silently pool their transactions and report the same merged balance
  /// on both cards. Names are therefore unique, compared case-insensitively.
  Future<void> _assertNameIsFree(String uid, String name,
      {String? exceptId}) async {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) throw Exception('Wallet name cannot be empty');

    final snapshot = await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id == exceptId) continue;
      final other = (doc.data()['name'] ?? '').toString().trim().toLowerCase();
      if (other == wanted) {
        throw Exception('A wallet named "${name.trim()}" already exists');
      }
    }
  }

  /// Add a new wallet
  Future<void> addWallet(String uid, WalletModel wallet) async {
    await _assertNameIsFree(uid, wallet.name);
    await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .doc(wallet.id)
        .set(wallet.copyWith(name: wallet.name.trim()).toJson());
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
    await _assertNameIsFree(uid, wallet.name, exceptId: wallet.id);

    // The stored name and the name cascaded onto transactions must be
    // identical, or the stats lookup (keyed by name) stops finding the wallet's
    // history.
    final name = wallet.name.trim();
    await firestore
        .collection("Wallets")
        .doc(uid)
        .collection("wallet")
        .doc(wallet.id)
        .update(wallet.copyWith(name: name).toJson());

    // Rename wallet in all transactions if the name changed
    if (oldName != null && oldName.isNotEmpty && oldName != name) {
      final txSnapshot = await firestore
          .collection("Transactions")
          .doc(uid)
          .collection("transaction")
          .where("wallet", isEqualTo: oldName)
          .get();
      final batch = firestore.batch();
      for (final doc in txSnapshot.docs) {
        batch.update(doc.reference, {'wallet': name});
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

  /// Stream per-wallet totals derived from the transaction log.
  /// Returns `Map<walletName, {income, expense, transferIn, transferOut}>`.
  ///
  /// Transfer legs are split out from income/expense so that a transfer moves
  /// the balance (see [balanceOf]) without being reported as earning on one
  /// side of the move and spending on the other.
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
        final wallet = (data['wallet'] ?? 'Cash').toString().trim();
        if (wallet.isEmpty) continue;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final type = (data['type'] ?? '').toString();
        final isTransfer = TransferRules.isTransferLeg(data);

        stats.putIfAbsent(
          wallet,
          () => {
            'income': 0.0,
            'expense': 0.0,
            'transferIn': 0.0,
            'transferOut': 0.0,
          },
        );

        final bucket = type == 'EXPENSE'
            ? (isTransfer ? 'transferOut' : 'expense')
            : (isTransfer ? 'transferIn' : 'income');
        stats[wallet]![bucket] = stats[wallet]![bucket]! + amount;
      }
      return stats;
    });
  }

  /// The spendable balance of a wallet, derived from the transaction log: real
  /// earnings and spending plus whatever transfers moved in and out.
  ///
  /// This — not the stored `balance` field — is the single source of truth. The
  /// stored field is kept in step for compatibility, but it is not
  /// authoritative: [initializeDefaultWallets] seeds every wallet at 0, and
  /// `_adjustWalletBalance` never saw the transactions written before the
  /// wallet feature existed (those count towards "Cash" in the stats above).
  /// Reading the stored field is what made the transfer screen disagree with
  /// the wallets screen.
  static double balanceOf(
      Map<String, Map<String, double>> stats, String walletName) {
    final stat = stats[walletName.trim()];
    if (stat == null) return 0.0;
    final income = stat['income'] ?? 0.0;
    final expense = stat['expense'] ?? 0.0;
    final transferIn = stat['transferIn'] ?? 0.0;
    final transferOut = stat['transferOut'] ?? 0.0;
    return income + transferIn - expense - transferOut;
  }
}
