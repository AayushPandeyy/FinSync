import 'package:finance_tracker/enums/transaction/TransactionType.dart';
import 'package:finance_tracker/models/Category.dart';
import 'package:finance_tracker/models/TransactionTemplate.dart';
import 'package:finance_tracker/pages/homePage/AddTransactionPage.dart';
import 'package:finance_tracker/pages/personalMode/templatesPage/QuickAddTemplateSheet.dart';
import 'package:finance_tracker/pages/personalMode/templatesPage/TemplatesPage.dart';
import 'package:finance_tracker/service/TemplateFirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/pages/personalMode/IOUpage/IOUPage.dart';
import 'package:finance_tracker/pages/common/accountsPage/AccountSettingsPage.dart';
import 'package:finance_tracker/pages/personalMode/analyticsPage/ReportPage.dart';
import 'package:finance_tracker/pages/personalMode/budgetPage/BudgetPage.dart';
import 'package:finance_tracker/pages/personalMode/friendsPage/FriendsPage.dart';
import 'package:finance_tracker/pages/personalMode/goalsPage/GoalsPage.dart';
import 'package:finance_tracker/pages/homePage/ServicesListPage.dart';
import 'package:finance_tracker/pages/homePage/TransactionsBasedOnTypePage.dart';
import 'package:finance_tracker/pages/personalMode/monthlySummaryPage/MonthlySummaryPage.dart';
import 'package:finance_tracker/pages/personalMode/transactionsPage/SeeAllTransactionsPage.dart';
import 'package:finance_tracker/pages/personalMode/walletsPage/WalletsPage.dart';
import 'package:finance_tracker/pages/personalMode/transferPage/TransferPage.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

class PersonalModeBody extends StatefulWidget {
  const PersonalModeBody({
    super.key,
    required this.data,
    required this.currUser,
    required this.bannerAd,
    required this.isBannerAdLoaded,
    required this.onAccountSettingsReturn,
    required this.currencyRefreshSignal,
  });

  final Map<String, dynamic> data;
  final User currUser;
  final BannerAd bannerAd;
  final bool isBannerAdLoaded;
  final Future<void> Function() onAccountSettingsReturn;
  final int currencyRefreshSignal;

  @override
  State<PersonalModeBody> createState() => _PersonalModeBodyState();
}

class _PersonalModeBodyState extends State<PersonalModeBody> {
  final TransactionFirestoreService service = TransactionFirestoreService();
  final TemplateFirestoreService templateService = TemplateFirestoreService();
  bool _showExpenses = true;
  String _currencySymbol = 'Rs';

  /// How many templates the home page surfaces before "See all".
  static const int _homeTemplateCount = 3;

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
  }

  @override
  void didUpdateWidget(covariant PersonalModeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currencyRefreshSignal != widget.currencyRefreshSignal) {
      _loadCurrencySymbol();
    }
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    print('Loaded currency symbol: $symbol');
    if (!mounted) return;
    setState(() {
      _currencySymbol = symbol;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildUnifiedBalanceCard(
              totalBalance: (widget.data['totalBalance'] as num).toDouble(),
              income: (widget.data['income'] as num).toDouble(),
              expense: (widget.data['expense'] as num).toDouble(),
              username: widget.data['username']?.toString() ?? 'User',
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Add Income',
                    icon: Icons.add_circle_outline_rounded,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddTransactionPage(transactionType: 'income'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Add Expense',
                    icon: Icons.remove_circle_outline_rounded,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEE2E2),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionPage(
                            transactionType: 'expense'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickAddTemplates(widget.currUser.uid),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildRecentTransactions(widget.currUser.uid),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServicesListPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  _buildFeatureBox(
                    context,
                    title: 'Transactions',
                    subtitle: 'View all transactions',
                    icon: Icons.receipt_long,
                    accentColor: const Color(0xFF4A90E2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SeeAllTransactionsPage(),
                        ),
                      );
                    },
                  ),
                  // _buildFeatureBox(
                  //   context,
                  //   title: 'Goals',
                  //   subtitle: 'Your financial goals',
                  //   icon: Icons.savings,
                  //   accentColor: const Color(0xFFE67E22),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const GoalsPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  _buildFeatureBox(
                    context,
                    title: 'Analytics',
                    subtitle: 'View insights',
                    icon: Icons.analytics,
                    accentColor: const Color(0xFFE74C3C),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportPage(),
                        ),
                      );
                    },
                  ),
                  _buildFeatureBox(
                    context,
                    title: 'Budget',
                    subtitle: 'Set your budget',
                    icon: Icons.pie_chart,
                    accentColor: const Color(0xFF16A085),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetPage(),
                        ),
                      );
                    },
                  ),
                  // _buildFeatureBox(
                  //   context,
                  //   title: 'IOU',
                  //   subtitle: 'Track money you owe or are owed',
                  //   icon: Icons.receipt_long,
                  //   accentColor: const Color(0xFF3498DB),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => IOUPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  // _buildFeatureBox(
                  //   context,
                  //   title: 'Friends',
                  //   subtitle: 'Manage your friend connections',
                  //   icon: Icons.group,
                  //   accentColor: const Color(0xFF3498DB),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => FriendsPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  // _buildFeatureBox(
                  //   context,
                  //   title: 'Account',
                  //   subtitle: 'Your Personal Account Information',
                  //   icon: Icons.person,
                  //   accentColor: const Color(0xFF9B59B6),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => AccountSettingsPage(),
                  //       ),
                  //     ).then((_) async {
                  //       await widget.onAccountSettingsReturn();
                  //       if (!mounted) return;
                  //       setState(() {});
                  //     });
                  //   },
                  // ),
                  // _buildFeatureBox(
                  //   context,
                  //   title: 'Summary',
                  //   subtitle: 'Your month at a glance',
                  //   icon: Icons.calendar_month_rounded,
                  //   accentColor: const Color(0xFF8E44AD),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const MonthlySummaryPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  _buildFeatureBox(
                    context,
                    title: 'Wallets',
                    subtitle: 'Cash, Bank & Digital',
                    icon: Icons.account_balance_wallet,
                    accentColor: const Color(0xFF2ECC71),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WalletsPage(),
                        ),
                      );
                    },
                  ),
                  // _buildFeatureBox(
                  //   context,
                  //   title: 'Transfer',
                  //   subtitle: 'Transfer money between your wallets',
                  //   icon: Icons.swap_horiz,
                  //   accentColor: const Color(0xFF20B894),
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const TransferPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 56),
          if (widget.isBannerAdLoaded)
            Center(
              child: Container(
                width: widget.bannerAd.size.width.toDouble(),
                height: widget.bannerAd.size.height.toDouble(),
                child: AdWidget(ad: widget.bannerAd),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final Category? match = Categories().categories.cast<Category?>().firstWhere(
          (category) => category?.name == name,
          orElse: () => null,
        );
    return match?.icon ?? Icons.more_horiz;
  }

  /// Opens the same sheet the Templates page uses, so a home-page quick add and
  /// a quick add from the full list behave identically.
  Future<void> _quickAddFromTemplate(TransactionTemplate template) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickAddTemplateSheet(template: template),
    );

    if (added == true && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Transaction added.')));
    }
  }

  /// The newest few templates, as one-tap shortcuts. Templates already stream
  /// newest-first, so this is just the head of that list.
  Widget _buildQuickAddTemplates(String uid) {
    return StreamBuilder<List<TransactionTemplate>>(
      stream: templateService.getTemplatesStream(uid),
      builder: (context, snapshot) {
        // Say nothing until we know whether there are templates — an empty
        // prompt that flashes on every home load would be noise.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final templates =
            (snapshot.data ?? const <TransactionTemplate>[]).take(_homeTemplateCount).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Add',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TemplatesPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'See all',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (templates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCreateTemplateCard(),
              )
            else
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _buildTemplateCard(templates[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTemplateCard(TransactionTemplate template) {
    final isExpense = template.type == 'EXPENSE';
    final accent =
        isExpense ? const Color(0xFFE63946) : const Color(0xFF06D6A0);

    return SizedBox(
      width: 158,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _quickAddFromTemplate(template),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9EDF2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _categoryIcon(template.category),
                        color: accent,
                        size: 19,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isExpense
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: accent,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  template.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTemplateCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TemplatesPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EDF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard_customize,
                  color: Color(0xFFF39C12),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a template',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Save the transactions you add often and post them in one tap.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedBalanceCard({
    required double totalBalance,
    required double income,
    required double expense,
    required String username,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          totalBalance.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionsBasedOnTypePage(
                                type: TransactionType.INCOME.name,
                              ),
                            ),
                          );
                        },
                        child: _buildBalanceItem(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Income',
                          amount: income,
                          color: const Color(0xFF4ADE80),
                          iconBackgroundColor:
                              const Color(0xFF4ADE80).withOpacity(0.2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionsBasedOnTypePage(
                                type: TransactionType.EXPENSE.name,
                              ),
                            ),
                          );
                        },
                        child: _buildBalanceItem(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Expense',
                          amount: expense,
                          color: const Color(0xFFFF6B6B),
                          iconBackgroundColor:
                              const Color(0xFFFF6B6B).withOpacity(0.2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  username.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 7.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required Color iconBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBox(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 40) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getRecentTransactionsOfUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8A94A6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }

        final transactions = snapshot.data!.take(5).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: txn['type'] == 'EXPENSE'
                              ? const Color(0xFFE63946).withOpacity(0.1)
                              : const Color(0xFF06D6A0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          txn['type'] == 'EXPENSE'
                              ? Icons.remove_circle
                              : Icons.add_circle,
                          color: txn['type'] == 'EXPENSE'
                              ? const Color(0xFFE63946)
                              : const Color(0xFF06D6A0),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn['title'] ?? 'Transaction',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (txn['category'] ?? 'Uncategorized') +
                                  ' • ' +
                                  (txn['wallet'] ?? 'Cash'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${txn['type'] == 'EXPENSE' ? '−' : '+'} $_currencySymbol ${(txn['amount'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: txn['type'] == 'EXPENSE'
                              ? const Color(0xFFE63946)
                              : const Color(0xFF06D6A0),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyExpensesChart(String uid) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: service.getTransactionsGroupedByDay(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 280,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final expenseData = data['expense'] ?? {};
        final incomeData = data['income'] ?? {};

        final chartData = _showExpenses ? expenseData : incomeData;
        final chartColor =
            _showExpenses ? const Color(0xFFFF6B6B) : const Color(0xFF4ADE80);
        final chartColorLight =
            _showExpenses ? const Color(0xFFFF8E8E) : const Color(0xFF6EE7A0);

        final now = DateTime.now();
        final List<DateTime> last7Days = List.generate(
          7,
          (index) => now.subtract(Duration(days: 6 - index)),
        );

        final List<BarChartGroupData> barGroups = [];
        double maxY = 0;

        for (int i = 0; i < last7Days.length; i++) {
          final day = last7Days[i];
          final dayKey = DateFormat('yyyy-MM-dd').format(day);
          final amount = chartData[dayKey] ?? 0.0;

          if (amount > maxY) maxY = amount;

          final isToday = DateUtils.isSameDay(day, now);

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: isToday ? 22 : 18,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      chartColor.withOpacity(isToday ? 1 : 0.7),
                      chartColorLight.withOpacity(0.6),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        maxY = maxY * 1.2;
        if (maxY == 0) maxY = 100;

        return Container(
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildToggleButton(
                          label: 'Expenses',
                          isSelected: _showExpenses,
                          color: const Color(0xFFFF6B6B),
                          onTap: () {
                            setState(() => _showExpenses = true);
                          },
                        ),
                        _buildToggleButton(
                          label: 'Income',
                          isSelected: !_showExpenses,
                          color: const Color(0xFF4ADE80),
                          onTap: () {
                            setState(() => _showExpenses = false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: maxY,
                    barGroups: barGroups,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < last7Days.length) {
                              final day = last7Days[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('E').format(day).substring(0, 1),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: maxY / 4,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '₹${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = last7Days[group.x.toInt()];
                          final dayName = DateFormat('EEE').format(day);

                          return BarTooltipItem(
                            '$dayName\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '₹${rod.toY.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: chartColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.15),
        highlightColor: color.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
