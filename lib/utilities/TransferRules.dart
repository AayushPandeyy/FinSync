/// Rules for the two ledger entries a wallet-to-wallet transfer writes.
///
/// Moving money between your own wallets is neither earning nor spending, so a
/// transfer leg must never reach an income or expense figure — it would inflate
/// both sides by the same amount and disagree with the `Users` aggregates,
/// which [TransferFirestoreService] deliberately leaves alone.
///
/// Wallet balances are the one exception: there the legs are exactly what moves
/// the money, so [WalletFirestoreService.balanceOf] counts them.
class TransferRules {
  const TransferRules._();

  /// The category stamped on both legs of a transfer.
  static const String category = 'Transfer';

  static bool isTransferCategory(Object? value) =>
      (value ?? '').toString() == category;

  static bool isTransferLeg(Map<String, dynamic> transaction) =>
      isTransferCategory(transaction['category']);

  /// Drops both legs of every transfer — use before any income/expense tally.
  static List<Map<String, dynamic>> exclude(
      List<Map<String, dynamic>> transactions) {
    return transactions.where((tx) => !isTransferLeg(tx)).toList();
  }
}
