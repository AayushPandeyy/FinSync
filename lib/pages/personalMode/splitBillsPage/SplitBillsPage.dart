import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/pages/personalMode/splitBillsPage/AddSplitBillPage.dart';
import 'package:finance_tracker/pages/personalMode/splitBillsPage/SplitBillDetailPage.dart';
import 'package:finance_tracker/service/SplitBillsFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:finance_tracker/widgets/splitBills/SettleSplitDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

/// How the list is narrowed. "Total value of every bill I appear in" is not a
/// number anyone acts on, so the page is organised by position instead.
enum SplitFilter { all, iOwe, owedToMe, settled }

class SplitBillsPage extends StatefulWidget {
  const SplitBillsPage({super.key});

  @override
  State<SplitBillsPage> createState() => _SplitBillsPageState();
}

class _SplitBillsPageState extends State<SplitBillsPage> {
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  String _currencySymbol = 'Rs';
  SplitFilter _filter = SplitFilter.all;

  String uid = FirebaseAuth.instance.currentUser!.uid;
  final SplitBillsFirestoreService firestoreService =
      SplitBillsFirestoreService();

  static const _amber = Color(0xFFF39C12);
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFE63946);
  static const _ink = Color(0xFF1A1A1A);
  static const _grey = Color(0xFF9AA3AF);

  final _formatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    _initCurrency();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3804780729029008/8582553165',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  Future<void> _initCurrency() async {
    await CurrencyService.initializeCurrency();
    if (!mounted) return;
    setState(() {
      _currencySymbol = CurrencyService.getCurrencySymbolSync();
    });
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  String _money(double amount) => '$_currencySymbol ${_formatter.format(amount)}';

  // ─── Position maths ────────────────────────────────────────────────────────

  /// What the reader still owes across every bill they are a payee on.
  double _totalIOwe(List<SplitBill> bills) => bills
      .where((b) => b.paidBy != uid)
      .fold(0.0, (sum, b) => sum + b.remainingFor(uid));

  /// What the reader is still owed across every bill they paid.
  double _totalOwedToMe(List<SplitBill> bills) => bills
      .where((b) => b.paidBy == uid)
      .fold(0.0, (sum, b) => sum + b.totalRemaining);

  /// Requests sitting on the reader's desk, across every bill they paid.
  int _requestsToReview(List<SplitBill> bills) => bills
      .where((b) => b.paidBy == uid)
      .fold(0, (sum, b) => sum + b.pendingRequestCount);

  bool _isSettledForMe(SplitBill bill) =>
      bill.paidBy == uid ? bill.isFullySettled : bill.isSettledFor(uid);

  List<SplitBill> _applyFilter(List<SplitBill> bills) {
    switch (_filter) {
      case SplitFilter.all:
        return bills;
      case SplitFilter.iOwe:
        return bills
            .where((b) => b.paidBy != uid && !b.isSettledFor(uid))
            .toList();
      case SplitFilter.owedToMe:
        return bills
            .where((b) => b.paidBy == uid && !b.isFullySettled)
            .toList();
      case SplitFilter.settled:
        return bills.where(_isSettledForMe).toList();
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openBill(SplitBill bill) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SplitBillDetailPage(splitBill: bill),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _settle(SplitBill bill) async {
    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SettleSplitDialog(
        bill: bill,
        payeeUid: uid,
        actorUid: uid,
        mode: SettleMode.request,
      ),
    );

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Settlement sent for approval.'),
          backgroundColor: _amber,
        ));
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Split Bills',
        subtitle: 'Divide and track shared expenses',
        useCustomDesign: true,
        actions: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddSplitBillPage()),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<SplitBill>>(
        stream: firestoreService.getSplitBillsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bills = snapshot.data ?? [];

          if (bills.isEmpty) return _emptyState();

          final visible = _applyFilter(bills);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _positionCard(bills),
                const SizedBox(height: 14),
                _filterRow(bills),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  _emptyFilterState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (context, index) => _billCard(visible[index]),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _isBannerAdLoaded
          ? SizedBox(
              height: _bannerAd.size.height.toDouble(),
              width: _bannerAd.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd),
            )
          : null,
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  /// Net position first, the two sides underneath. This replaces the old sum of
  /// bill totals, which mixed in money that was never the reader's to settle.
  Widget _positionCard(List<SplitBill> bills) {
    final owed = _totalOwedToMe(bills);
    final owe = _totalIOwe(bills);
    final net = owed - owe;
    final reviews = _requestsToReview(bills);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_amber.withOpacity(0.85), const Color(0xFFE67E22)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            net >= 0 ? 'You are owed overall' : 'You owe overall',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _money(net.abs()),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _positionHalf('Owed to you', owed),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _positionHalf('You owe', owe, alignEnd: true),
              ),
            ],
          ),
          if (reviews > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 15, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reviews == 1
                          ? '1 settlement is waiting for your approval'
                          : '$reviews settlements are waiting for your approval',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _positionHalf(String label, double amount, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _money(amount),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _filterRow(List<SplitBill> bills) {
    final counts = {
      SplitFilter.all: bills.length,
      SplitFilter.iOwe: bills
          .where((b) => b.paidBy != uid && !b.isSettledFor(uid))
          .length,
      SplitFilter.owedToMe:
          bills.where((b) => b.paidBy == uid && !b.isFullySettled).length,
      SplitFilter.settled: bills.where(_isSettledForMe).length,
    };

    const labels = {
      SplitFilter.all: 'All',
      SplitFilter.iOwe: 'I owe',
      SplitFilter.owedToMe: 'Owed to me',
      SplitFilter.settled: 'Settled',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SplitFilter.values.map((filter) {
          final isActive = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? _amber : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? _amber : const Color(0xFFE9EDF2),
                  ),
                ),
                child: Text(
                  '${labels[filter]} (${counts[filter]})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Card ──────────────────────────────────────────────────────────────────

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
      case 'groceries':
        return Icons.local_grocery_store;
      default:
        return Icons.receipt_long;
    }
  }

  Widget _billCard(SplitBill bill) {
    final bool isPayer = bill.paidBy == uid;
    final bool isParticipant = bill.participants.contains(uid);

    // Everything the card says is driven by the reader's own position.
    final double headline;
    final String headlineCaption;
    final Color accent;
    final double progress;
    final String chipLabel;
    final Color chipColor;

    if (isPayer) {
      final settled = bill.isFullySettled;
      headline = settled ? bill.totalOwedToPayer : bill.totalRemaining;
      headlineCaption = settled
          ? 'collected in full of ${_money(bill.totalAmount)}'
          : 'owed to you of ${_money(bill.totalAmount)} total';
      accent = _green;
      progress = bill.settlementProgress;
      if (bill.pendingRequestCount > 0) {
        chipLabel = bill.pendingRequestCount == 1
            ? '1 request'
            : '${bill.pendingRequestCount} requests';
        chipColor = _amber;
      } else if (settled) {
        chipLabel = 'Settled';
        chipColor = _green;
      } else {
        chipLabel = 'Unsettled';
        chipColor = _grey;
      }
    } else if (isParticipant) {
      final share = bill.shareOf(uid);
      final settledAmt = bill.settledOf(uid);
      final pending = bill.pendingFor(uid);
      final isSettled = bill.isSettledFor(uid);

      headline = isSettled ? share : bill.remainingFor(uid);
      progress = bill.progressFor(uid);

      if (isSettled) {
        headlineCaption = 'your share, fully settled';
        accent = _green;
        chipLabel = 'Settled';
        chipColor = _green;
      } else if (pending > 0) {
        headlineCaption = 'remaining · ${_money(pending)} awaiting approval';
        accent = _amber;
        chipLabel = 'Pending approval';
        chipColor = _amber;
      } else if (settledAmt > 0) {
        headlineCaption =
            'you owe · ${_money(settledAmt)} of ${_money(share)} settled';
        accent = _red;
        chipLabel = 'Partially settled';
        chipColor = _amber;
      } else {
        headlineCaption = 'you owe of ${_money(bill.totalAmount)} total';
        accent = _red;
        chipLabel = 'Unsettled';
        chipColor = _red;
      }
    } else {
      headline = bill.totalAmount;
      headlineCaption = '${bill.participants.length} participants';
      accent = _grey;
      progress = bill.settlementProgress;
      chipLabel = '${bill.participants.length} people';
      chipColor = _grey;
    }

    final payerName =
        isPayer ? 'You paid' : '${bill.nameOf(bill.paidBy)} paid';

    // The payee acts from here; the payer reviews on the detail page.
    final bool showSettle = !isPayer &&
        isParticipant &&
        !bill.isSettledFor(uid) &&
        bill.settleableFor(uid) > 0;
    final bool showReview = isPayer && bill.pendingRequestCount > 0;

    return GestureDetector(
      onTap: () => _openBill(bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chipColor == _amber
                ? _amber.withOpacity(0.4)
                : const Color(0xFFE9EDF2),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_categoryIcon(bill.category),
                      color: _amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$payerName · ${DateFormat('d MMM').format(bill.date)} · ${bill.participants.length} people',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Headline figure ──────────────────────────────────────
            Text(
              _money(headline),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              headlineCaption,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? _green : accent,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Status + action ──────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: chipColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (showSettle)
                  _cardButton(
                    label: bill.hasPendingFor(uid) ? 'Settle more' : 'Settle',
                    color: const Color(0xFF06D6A0),
                    onTap: () => _settle(bill),
                  )
                else if (showReview)
                  _cardButton(
                    label: 'Review',
                    color: _amber,
                    onTap: () => _openBill(bill),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─── Empty states ──────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No split bills yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking shared expenses',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _emptyFilterState() {
    const messages = {
      SplitFilter.all: 'No split bills yet.',
      SplitFilter.iOwe: 'You are all square — nothing outstanding.',
      SplitFilter.owedToMe: 'Nobody owes you anything right now.',
      SplitFilter.settled: 'Nothing has been settled yet.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            messages[_filter]!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
