import 'package:cloud_firestore/cloud_firestore.dart';

class TransferFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Transfer [amount] from [fromWalletId] to [toWalletId] for user [uid].
  /// Creates two transaction records (outgoing and incoming) and updates
  /// the wallet balances in a single Firestore transaction.
  Future<void> transferBetweenWallets({
    required String uid,
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? note,
  }) async {
    if (fromWalletId == toWalletId) {
      throw Exception('Source and destination wallets must be different');
    }
    if (amount <= 0) {
      throw Exception('Amount must be greater than zero');
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

      final double fromBalance =
          (fromData['balance'] as num?)?.toDouble() ?? 0.0;
      final double toBalance = (toData['balance'] as num?)?.toDouble() ?? 0.0;

      if (fromBalance < amount) {
        throw Exception('Insufficient balance in source wallet');
      }

      // Update balances
      tx.update(fromRef, {'balance': fromBalance - amount});
      tx.update(toRef, {'balance': toBalance + amount});

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
        'category': 'Transfer',
        'type': 'EXPENSE',
        'wallet': fromWalletName,
      });

      tx.set(inDoc, {
        'id': inDoc.id,
        'title': 'Transfer from $fromWalletName',
        'date': now,
        'description': note ?? 'Transfer from $fromWalletName to $toWalletName',
        'amount': amount,
        'category': 'Transfer',
        'type': 'INCOME',
        'wallet': toWalletName,
      });
    });
  }
}
