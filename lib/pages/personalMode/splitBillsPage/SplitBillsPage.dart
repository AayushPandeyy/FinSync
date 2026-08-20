import 'package:finance_tracker/models/SplitBill.dart';
import 'package:finance_tracker/pages/personalMode/splitBillsPage/AddSplitBillPage.dart';
import 'package:finance_tracker/pages/personalMode/splitBillsPage/SplitBillDetailPage.dart';
import 'package:finance_tracker/service/SplitBillsFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

class SplitBillsPage extends StatefulWidget {
  const SplitBillsPage({super.key});

  @override
  State<SplitBillsPage> createState() => _SplitBillsPageState();
}

class _SplitBillsPageState extends State<SplitBillsPage> {
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  String _currencySymbol = 'Rs';

  String uid = FirebaseAuth.instance.currentUser!.uid;
  final SplitBillsFirestoreService firestoreService =
      SplitBillsFirestoreService();

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
  }

  double _getTotalAmount(List<SplitBill> bills) {
    return bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
  }

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
                color: const Color(0xFFF39C12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<SplitBill>>(
        stream: firestoreService.getSplitBillsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            print('Error loading split bills: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final bills = snapshot.data ?? [];

          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.money_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final totalAmount = _getTotalAmount(bills);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF39C12).withOpacity(0.8),
                        const Color(0xFFE67E22),
                      ],
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
                        'Total Split Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currencySymbol ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Bills list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    final String currentUserId =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    final bool isPayer = bill.paidBy == currentUserId;
                    final double myShare =
                        bill.splitAmounts[currentUserId] ?? 0.0;
                    final formatter = NumberFormat('#,##0.00');

                    // Status label + colour
                    final String statusLabel;
                    final Color statusColor;
                    if (isPayer) {
                      final double totalOwedToMe = bill.splitAmounts.entries
                          .where((e) => e.key != currentUserId)
                          .fold(0.0, (sum, e) => sum + e.value);
                      statusLabel =
                          'You are owed $_currencySymbol ${formatter.format(totalOwedToMe)}';
                      statusColor = const Color(0xFF2E7D32);
                    } else if (bill.participants.contains(currentUserId)) {
                      statusLabel =
                          'You owe $_currencySymbol ${formatter.format(myShare)}';
                      statusColor = const Color(0xFFE63946);
                    } else {
                      statusLabel = '${bill.participants.length} participants';
                      statusColor = const Color(0xFF9AA3AF);
                    }

                    // Category icon — same switch as detail page
                    IconData categoryIcon;
                    switch (bill.category.toLowerCase()) {
                      case 'food':
                      case 'dining':
                        categoryIcon = Icons.restaurant;
                        break;
                      case 'travel':
                      case 'transport':
                        categoryIcon = Icons.directions_car;
                        break;
                      case 'shopping':
                        categoryIcon = Icons.shopping_bag;
                        break;
                      case 'entertainment':
                        categoryIcon = Icons.movie;
                        break;
                      case 'utilities':
                        categoryIcon = Icons.electrical_services;
                        break;
                      case 'rent':
                      case 'housing':
                        categoryIcon = Icons.home;
                        break;
                      case 'health':
                      case 'medical':
                        categoryIcon = Icons.local_hospital;
                        break;
                      case 'groceries':
                        categoryIcon = Icons.local_grocery_store;
                        break;
                      default:
                        categoryIcon = Icons.receipt_long;
                    }

                    return GestureDetector(
                      onTap: () async {
                        final deleted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SplitBillDetailPage(splitBill: bill),
                          ),
                        );
                        if (deleted == true) {
                          // refresh your list here, e.g. setState(() {})
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9EDF2)),
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
                            // ── Top row: icon  |  title + category  |  amount ──
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF39C12)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(categoryIcon,
                                      color: const Color(0xFFF39C12), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bill.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF3E0),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              bill.category,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFFF39C12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$_currencySymbol ${formatter.format(bill.totalAmount)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'total',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9AA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // ── Optional description ─────────────────────────────
                            if (bill.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                bill.description,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF666666)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            const SizedBox(height: 10),

                            // ── Bottom row: status (owe/owed)  |  participants  |  date ──
                            Row(
                              children: [
                                // Status pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Participants
                                const Icon(Icons.group_outlined,
                                    size: 13, color: Color(0xFF9AA3AF)),
                                const SizedBox(width: 3),
                                Text(
                                  '${bill.participants.length}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF9AA3AF)),
                                ),
                                const SizedBox(width: 10),
                                // Date
                                const Icon(Icons.calendar_today_outlined,
                                    size: 13, color: Color(0xFF9AA3AF)),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormat('d MMM').format(bill.date),
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF9AA3AF)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }
}
