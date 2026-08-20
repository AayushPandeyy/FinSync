import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/utilities/TransferRules.dart';

class TransferFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Transfer [amount] from [fromWalletId] to [toWalletId] for user [uid].
  /// Creates two transaction records (outgoing and incoming) and updates
  /// the wallet balances in a single Firestore transaction.
  ///
  /// [fromBalance] is the source wallet's spendable balance from
  /// [WalletFirestoreService.balanceOf]. The caller supplies it because the
  /// balance is derived from the transaction collection, which a Firestore
  /// transaction cannot query — and because the stored `balance` field it used
  /// to check instead lags behind and rejected valid transfers.
  Future<void> transferBetweenWallets({
    required String uid,
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required double fromBalance,
    String? note,
  }) async {
    if (fromWalletId == toWalletId) {
      throw Exception('Source and destination wallets must be different');
    }
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
    }
    // Compared in whole cents so float drift cannot reject an exact-balance
    // transfer.
    if ((fromBalance * 100).round() < (amount * 100).round()) {
      throw Exception('Insufficient balance in source wallet');
    }

    final fromRef = firestore
        .collection('Wallets')
        .doc(uid)
        .collection('wallet')
        .doc(fromWalletId);
    final toRef = firestore
        .collection('Wallets')
        .doc(uid)
        .collection('wallet')
        .doc(toWalletId);

    final txCollection =
        firestore.collection('Transactions').doc(uid).collection('transaction');

    await firestore.runTransaction((tx) async {
      final fromSnap = await tx.get(fromRef);
      final toSnap = await tx.get(toRef);

      if (!fromSnap.exists) throw Exception('Source wallet not found');
      if (!toSnap.exists) throw Exception('Destination wallet not found');

      final fromData = fromSnap.data()!;
      final toData = toSnap.data()!;

      // The stored field is a mirror, not the source of truth, so move it by a
      // delta rather than overwriting it with a figure read here.
      tx.update(fromRef, {'balance': FieldValue.increment(-amount)});
      tx.update(toRef, {'balance': FieldValue.increment(amount)});

      // Create transaction docs for both sides. Use server timestamp.
      final now = Timestamp.now();

      final fromWalletName = (fromData['name'] ?? '').toString();
      final toWalletName = (toData['name'] ?? '').toString();

      final outDoc = txCollection.doc();
      final inDoc = txCollection.doc();

      tx.set(outDoc, {
        'id': outDoc.id,
        'title': 'Transfer to $toWalletName',
        'date': now,
        'description': note ?? 'Transfer to $toWalletName from $fromWalletName',
        'amount': amount,
        'category': TransferRules.category,
        'type': 'EXPENSE',
        'wallet': fromWalletName,
      });

      tx.set(inDoc, {
        'id': inDoc.id,
        'title': 'Transfer from $fromWalletName',
        'date': now,
        'description': note ?? 'Transfer from $fromWalletName to $toWalletName',
        'amount': amount,
        'category': TransferRules.category,
        'type': 'INCOME',
        'wallet': toWalletName,
      });
    });
  }
}
