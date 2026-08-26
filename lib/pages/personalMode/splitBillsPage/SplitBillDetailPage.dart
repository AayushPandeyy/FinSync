import 'package:finance_tracker/models/SettlementRequest.dart';
import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/service/SplitBillsFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/widgets/splitBills/SettleSplitDialog.dart';
import 'package:finance_tracker/widgets/splitBills/SettlementRequestTile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SplitBillDetailPage extends StatefulWidget {
  final SplitBill splitBill;

  const SplitBillDetailPage({Key? key, required this.splitBill})
      : super(key: key);

  @override
  State<SplitBillDetailPage> createState() => _SplitBillDetailPageState();
}

class _SplitBillDetailPageState extends State<SplitBillDetailPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final SplitBillsFirestoreService _service = SplitBillsFirestoreService();

  late Future<Map<String, String>> _usernamesFuture;

  /// Guards the approve / decline buttons while a transaction is in flight, so
  /// a double tap cannot fire the same resolution twice.
  bool _isResolving = false;

  static const _amber = Color(0xFFF39C12);
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFE63946);
  static const _ink = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF999999);

  @override
  void initState() {
    super.initState();
    _usernamesFuture = _fetchUsernames();
    CurrencyService.initializeCurrency().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Names come off the bill when it has them. Only bills written before names
  /// were denormalised need the per-participant lookup.
  Future<Map<String, String>> _fetchUsernames() async {
    final bill = widget.splitBill;
    final Map<String, String> result = {};

    for (final uid in bill.participants) {
      final stamped = bill.participantNames[uid];
      if (stamped != null && stamped.trim().isNotEmpty) {
        result[uid] = stamped;
        continue;
      }

      try {
        final doc =
            await FirebaseFirestore.instance.collection('Users').doc(uid).get();
        result[uid] = doc.data()?['username'] as String? ?? 'Unknown';
      } catch (_) {
        result[uid] = 'Unknown';
      }
    }
    return result;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '${CurrencyService.getCurrencySymbolSync()} ${formatter.format(amount)}';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return Icons.restaurant;
      case 'travel':
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.electrical_services;
      case 'rent':
      case 'housing':
        return Icons.home;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.receipt_long;
    }
  }

  void _snack(String message, {Color background = _ink}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: background),
      );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openSettleDialog(SplitBill bill) async {
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SettleSplitDialog(
        bill: bill,
        payeeUid: currentUserId,
        actorUid: currentUserId,
        mode: SettleMode.request,
      ),
    );

    if (sent == true) {
      _snack('Settlement sent for approval.', background: _amber);
    }
  }

  Future<void> _openRecordDialog(SplitBill bill, String payeeUid) async {
    final recorded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SettleSplitDialog(
        bill: bill,
        payeeUid: payeeUid,
        actorUid: currentUserId,
        mode: SettleMode.record,
      ),
    );

    if (recorded == true) {
      _snack('Payment recorded.', background: _green);
    }
  }

  Future<void> _resolve(
    SplitBill bill,
    SettlementRequest request, {
    required bool approve,
  }) async {
    if (_isResolving) return;
    setState(() => _isResolving = true);

    try {
      if (approve) {
        await _service.approveSettlement(
          bill: bill,
          request: request,
          approverUid: currentUserId,
        );
        _snack('Settlement approved.', background: _green);
      } else {
        await _service.rejectSettlement(
          bill: bill,
          request: request,
          approverUid: currentUserId,
        );
        _snack('Settlement declined.', background: _red);
      }
    } on SettlementException catch (e) {
      _snack(e.message, background: _red);
    } catch (_) {
      _snack('Something went wrong. Please try again.', background: _red);
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  Future<void> _cancelOwnRequest(SplitBill bill) async {
    if (_isResolving) return;
    setState(() => _isResolving = true);

    try {
      await _service.cancelSettlementRequest(
        bill: bill,
        fromUid: currentUserId,
      );
      _snack('Request withdrawn.');
    } on SettlementException catch (e) {
      _snack(e.message, background: _red);
    } catch (_) {
      _snack('Could not withdraw the request.', background: _red);
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  void _showDeleteDialog(SplitBill bill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Split Bill',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'This removes the bill for everyone, along with the IOUs it created '
          'and its settlement history. This cannot be undone.',
          style: TextStyle(color: _muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteSplitBill(bill);
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                _snack('Failed to delete. Please try again.', background: _red);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    // Live so an approval on the other side lands here without a reopen.
    return StreamBuilder<SplitBill?>(
      stream: _service.watchSplitBill(
          widget.splitBill.paidBy, widget.splitBill.id),
      builder: (context, billSnapshot) {
        final bill = billSnapshot.data ?? widget.splitBill;
        final bool isPayer = bill.paidBy == currentUserId;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8FA),
          body: SafeArea(
            child: Column(
              children: [
                _navBar(width, bill, isPayer),
                Expanded(
                  child: FutureBuilder<Map<String, String>>(
                    future: _usernamesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(color: _amber),
                        );
                      }

                      // Live bill names win; the future only fills the gaps.
                      final usernames = <String, String>{
                        ...?snapshot.data,
                        ...bill.participantNames,
                      };

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroCard(
                              bill: bill,
                              width: width,
                              categoryIcon: _categoryIcon(bill.category),
                              formatCurrency: _formatCurrency,
                            ),
                            const SizedBox(height: 16),

                            // ── Your position + settle action ──────────
                            _BalanceCard(
                              bill: bill,
                              isPayer: isPayer,
                              currentUserId: currentUserId,
                              width: width,
                              formatCurrency: _formatCurrency,
                              isBusy: _isResolving,
                              onSettle: () => _openSettleDialog(bill),
                              onCancelRequest: () => _cancelOwnRequest(bill),
                            ),
                            const SizedBox(height: 16),

                            _sectionTitle('Paid by', width),
                            const SizedBox(height: 8),
                            _InfoCard(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isPayer ? 'You paid this bill' : 'Paid by',
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: width * 0.038,
                                      ),
                                    ),
                                    Text(
                                      isPayer
                                          ? 'You'
                                          : (usernames[bill.paidBy] ??
                                              'Unknown'),
                                      style: TextStyle(
                                        color: _amber,
                                        fontWeight: FontWeight.w600,
                                        fontSize: width * 0.038,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _sectionTitle('Who Owes What', width),
                            const SizedBox(height: 8),
                            _InfoCard(
                              children: bill.participants
                                  .map((uid) => _ParticipantRow(
                                        uid: uid,
                                        bill: bill,
                                        username:
                                            usernames[uid] ?? 'Unknown',
                                        isPayer: uid == bill.paidBy,
                                        isCurrentUser: uid == currentUserId,
                                        viewerIsPayer: isPayer,
                                        formatCurrency: _formatCurrency,
                                        width: width,
                                        onRecordPayment: () =>
                                            _openRecordDialog(bill, uid),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),

                            // ── Settlement activity ────────────────────
                            _settlementSection(bill, usernames, width, isPayer),

                            const SizedBox(height: 16),
                            _sectionTitle('Split Summary', width),
                            const SizedBox(height: 8),
                            _SummaryCard(
                              bill: bill,
                              usernames: usernames,
                              formatCurrency: _formatCurrency,
                              width: width,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _navBar(double width, SplitBill bill, bool isPayer) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: _ink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split Bill Details',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: width * 0.045,
                  ),
                ),
                Text(
                  bill.isFullySettled
                      ? 'Everyone is settled up'
                      : 'Expense breakdown',
                  style: TextStyle(
                    color: bill.isFullySettled ? _green : _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isPayer)
            GestureDetector(
              onTap: () => _showDeleteDialog(bill),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 20, color: _red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, double width) {
    return Text(
      text,
      style: TextStyle(
        color: _ink,
        fontWeight: FontWeight.w600,
        fontSize: width * 0.038,
      ),
    );
  }

  /// The bill's settlement history, with approve / decline on anything still
  /// open when the viewer is the payer.
  Widget _settlementSection(
    SplitBill bill,
    Map<String, String> usernames,
    double width,
    bool isPayer,
  ) {
    return StreamBuilder<List<SettlementRequest>>(
      stream: _service.getSettlementRequestsStream(bill.paidBy, bill.id),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? const <SettlementRequest>[];
        if (requests.isEmpty) return const SizedBox.shrink();

        final pendingCount = requests.where((r) => r.isPending).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionTitle('Settlement Activity', width),
                const SizedBox(width: 8),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPayer
                          ? '$pendingCount to review'
                          : '$pendingCount pending',
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...requests.map((request) => SettlementRequestTile(
                  request: request,
                  requesterName: request.fromUid == currentUserId
                      ? 'You'
                      : (usernames[request.fromUid] ?? 'Unknown'),
                  currencySymbol: CurrencyService.getCurrencySymbolSync(),
                  canApprove: isPayer && request.fromUid != currentUserId,
                  canCancel: request.fromUid == currentUserId,
                  isBusy: _isResolving,
                  onApprove: () => _resolve(bill, request, approve: true),
                  onReject: () => _resolve(bill, request, approve: false),
                  onCancel: () => _cancelOwnRequest(bill),
                )),
          ],
        );
      },
    );
  }
}

// ── Hero Card ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final SplitBill bill;
  final double width;
  final IconData categoryIcon;
  final String Function(double) formatCurrency;

  const _HeroCard({
    required this.bill,
    required this.width,
    required this.categoryIcon,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final settled = bill.isFullySettled;
    final progress = bill.settlementProgress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(categoryIcon,
                    color: const Color(0xFFF39C12), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.title,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                        fontSize: width * 0.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM yyyy').format(bill.date),
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatCurrency(bill.totalAmount),
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w800,
              fontSize: width * 0.07,
            ),
          ),
          if (bill.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bill.description,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Settlement progress across the whole bill.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settled ? 'Fully settled' : 'Settled so far',
                style: TextStyle(
                  color: settled
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF999999),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${formatCurrency(bill.totalSettled)} of ${formatCurrency(bill.totalOwedToPayer)}',
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                settled ? const Color(0xFF2E7D32) : const Color(0xFFF39C12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Text(
                  bill.category,
                  style: const TextStyle(
                    color: Color(0xFFF39C12),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (settled) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Text(
                    'Settled',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Balance / action card ───────────────────────────────────────────────────

/// The one thing the reader came for: what they owe or are owed on this bill,
/// and the button that does something about it.
class _BalanceCard extends StatelessWidget {
  final SplitBill bill;
  final bool isPayer;
  final String currentUserId;
  final double width;
  final String Function(double) formatCurrency;
  final bool isBusy;
  final VoidCallback onSettle;
  final VoidCallback onCancelRequest;

  const _BalanceCard({
    required this.bill,
    required this.isPayer,
    required this.currentUserId,
    required this.width,
    required this.formatCurrency,
    required this.isBusy,
    required this.onSettle,
    required this.onCancelRequest,
  });

  static const _amber = Color(0xFFF39C12);
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFE63946);

  @override
  Widget build(BuildContext context) {
    // A viewer who is neither payer nor payee has nothing to act on.
    if (!isPayer && !bill.participants.contains(currentUserId)) {
      return const SizedBox.shrink();
    }

    if (isPayer) return _payerView();
    return _payeeView();
  }

  Widget _payerView() {
    final remaining = bill.totalRemaining;
    final settled = bill.isFullySettled;
    final pendingCount = bill.pendingRequestCount;

    return _shell(
      accent: settled ? _green : _green,
      label: settled ? 'Everyone has settled up' : 'You are owed',
      amount: settled ? bill.totalOwedToPayer : remaining,
      amountColor: settled ? _green : _green,
      caption: settled
          ? 'Collected ${formatCurrency(bill.totalSettled)} in total'
          : '${formatCurrency(bill.totalSettled)} of ${formatCurrency(bill.totalOwedToPayer)} collected',
      footer: pendingCount > 0
          ? _pendingNotice(
              pendingCount == 1
                  ? '1 settlement is waiting for your approval'
                  : '$pendingCount settlements are waiting for your approval',
            )
          : null,
    );
  }

  Widget _payeeView() {
    final share = bill.shareOf(currentUserId);
    final remaining = bill.remainingFor(currentUserId);
    final pending = bill.pendingFor(currentUserId);
    final settleable = bill.settleableFor(currentUserId);
    final isSettled = bill.isSettledFor(currentUserId);

    return _shell(
      accent: isSettled ? _green : _red,
      label: isSettled ? 'You are settled up' : 'You owe',
      amount: isSettled ? share : remaining,
      amountColor: isSettled ? _green : _red,
      caption: isSettled
          ? 'Your full share of ${formatCurrency(share)} is cleared'
          : '${formatCurrency(bill.settledOf(currentUserId))} of ${formatCurrency(share)} settled',
      footer: pending > 0
          ? _pendingNotice(
              '${formatCurrency(pending)} is waiting for approval',
              action: TextButton(
                onPressed: isBusy ? null : onCancelRequest,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Withdraw',
                  style: TextStyle(
                    color: Color(0xFF8A6114),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            )
          : null,
      action: (!isSettled && settleable > 0)
          ? SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : onSettle,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(
                  pending > 0
                      ? 'Settle the remaining ${formatCurrency(settleable)}'
                      : 'Settle up',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06D6A0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _pendingNotice(String text, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: _amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: _amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: Color(0xFF8A6114),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) action else const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _shell({
    required Color accent,
    required String label,
    required double amount,
    required Color amountColor,
    required String caption,
    Widget? footer,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w800,
              fontSize: width * 0.065,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer,
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ],
      ),
    );
  }
}

// ── Info Card wrapper ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _intersperse(
            children, const Divider(height: 20, color: Color(0xFFF0F0F0))),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return items;
    final result = <Widget>[items.first];
    for (int i = 1; i < items.length; i++) {
      result.add(separator);
      result.add(items[i]);
    }
    return result;
  }
}

// ── Participant Row ──────────────────────────────────────────────────────────

class _ParticipantRow extends StatelessWidget {
  final String uid;
  final SplitBill bill;
  final String username;
  final bool isPayer;
  final bool isCurrentUser;

  /// True when the person reading this is the payer, who alone may record a
  /// payment on someone else's behalf.
  final bool viewerIsPayer;

  final String Function(double) formatCurrency;
  final double width;
  final VoidCallback onRecordPayment;

  const _ParticipantRow({
    required this.uid,
    required this.bill,
    required this.username,
    required this.isPayer,
    required this.isCurrentUser,
    required this.viewerIsPayer,
    required this.formatCurrency,
    required this.width,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    final amount = bill.shareOf(uid);
    final settled = bill.settledOf(uid);
    final remaining = bill.remainingFor(uid);
    final pending = bill.pendingFor(uid);
    final isSettled = !isPayer && bill.isSettledFor(uid);

    final Color amountColor;
    final String label;
    final Color? rowTint;

    if (isPayer) {
      amountColor = const Color(0xFF2E7D32);
      label = 'Paid the bill · own share';
      rowTint = null;
    } else if (isCurrentUser) {
      amountColor = isSettled ? const Color(0xFF2E7D32) : const Color(0xFFF39C12);
      label = _statusLine(settled, remaining, pending, isSettled, 'Your share');
      rowTint = const Color(0xFFFFF8EE);
    } else {
      amountColor =
          isSettled ? const Color(0xFF2E7D32) : const Color(0xFFE63946);
      label = _statusLine(settled, remaining, pending, isSettled, 'Owes');
      rowTint = null;
    }

    // The payer can log cash they have already been handed.
    final canRecord =
        viewerIsPayer && !isPayer && remaining > 0;

    Widget row = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isPayer
                ? const Color(0xFFE8F5E9)
                : isCurrentUser
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFF5F5F5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isSettled
                ? const Icon(Icons.check, size: 18, color: Color(0xFF2E7D32))
                : Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isPayer
                          ? const Color(0xFF2E7D32)
                          : isCurrentUser
                              ? const Color(0xFFF39C12)
                              : const Color(0xFF999999),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrentUser ? '$username (You)' : username,
                style: TextStyle(
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: width * 0.038,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    color: pending > 0
                        ? const Color(0xFFF39C12)
                        : const Color(0xFF999999),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(amount),
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w700,
                fontSize: width * 0.038,
              ),
            ),
            if (canRecord)
              GestureDetector(
                onTap: onRecordPayment,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'Record payment',
                    style: TextStyle(
                      color: Color(0xFF06D6A0),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    if (rowTint != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: rowTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: row,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: row,
    );
  }

  String _statusLine(double settled, double remaining, double pending,
      bool isSettled, String prefix) {
    if (isSettled) return 'Settled up';
    if (pending > 0) {
      return '${formatCurrency(pending)} awaiting approval';
    }
    if (settled > 0) {
      return '${formatCurrency(remaining)} still owed';
    }
    return prefix;
  }
}

// ── Summary Card ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SplitBill bill;
  final Map<String, String> usernames;
  final String Function(double) formatCurrency;
  final double width;

  const _SummaryCard({
    required this.bill,
    required this.usernames,
    required this.formatCurrency,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final participantCount = bill.participants.length;
    final totalAmount = bill.totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total + Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(
                label: 'Total Amount',
                value: formatCurrency(totalAmount),
                valueColor: const Color(0xFF1A1A1A),
                width: width,
              ),
              _SummaryItem(
                label: 'Participants',
                value: '$participantCount people',
                valueColor: const Color(0xFFF39C12),
                width: width,
                alignRight: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Share breakdown',
            style: TextStyle(
              color: const Color(0xFF999999),
              fontSize: width * 0.033,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          // Progress bars for each participant
          ...bill.splitAmounts.entries.map((entry) {
            final fraction = totalAmount > 0 ? entry.value / totalAmount : 0.0;
            final pct = (fraction * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        usernames[entry.key] ?? 'Unknown',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF39C12)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double width;
  final bool alignRight;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.width,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF999999), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: width * 0.04,
          ),
        ),
      ],
    );
  }
}
