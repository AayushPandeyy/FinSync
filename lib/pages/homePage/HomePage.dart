import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/transaction/TransactionType.dart';
import 'package:finance_tracker/pages/IOUpage/IOUPage.dart';
import 'package:finance_tracker/pages/accountsPage/AccountSettingsPage.dart';
import 'package:finance_tracker/pages/analyticsPage/ReportPage.dart';
import 'package:finance_tracker/pages/budgetPage/BudgetPage.dart';
import 'package:finance_tracker/pages/goalsPage/GoalsPage.dart';
import 'package:finance_tracker/pages/monthlySummaryPage/MonthlySummaryPage.dart';
import 'package:finance_tracker/pages/walletsPage/WalletsPage.dart';
import 'package:finance_tracker/pages/homePage/TransactionsBasedOnTypePage.dart';
import 'package:finance_tracker/pages/transactionsPage/SeeAllTransactionsPage.dart';
import 'package:finance_tracker/pages/homePage/AddTransactionPage.dart';
import 'package:finance_tracker/service/AuthFirestoreService.dart';
import 'package:finance_tracker/service/ConnectivityService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/service/UserFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/DialogBox.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TransactionFirestoreService service = TransactionFirestoreService();
  final UserFirestoreService userService = UserFirestoreService();
  FirebaseAuth auth = FirebaseAuth.instance;
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _showExpenses = true; // Toggle between expenses and income

  @override
  void initState() {
    super.initState();

    initCurrency();

    // Initialize banner ad
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

  void initCurrency() async {
    await CurrencyService.initializeCurrency();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currUser = FirebaseAuth.instance.currentUser;

    // If user is not logged in, return empty container
    if (currUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: StreamBuilder(
        stream: userService.getUserDataByEmail(currUser.email!),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Scaffold(
              backgroundColor: const Color(0xfff8f8fa),
              body: Center(
                child: LottieBuilder.asset("assets/lottiejson/loading.json"),
              ),
            );
          }

          final data = snapshot.data![0];

          // Initialize currency symbol in SharedPreferences if not already set
          final preferredCurrency =
              data["preferredCurrency"]?.toString() ?? 'NPR';
          CurrencyService.setCurrencyFromCode(preferredCurrency);

          return Scaffold(
            backgroundColor: const Color(0xfff8f8fa),
            appBar: StandardAppBar(
              title: "Hello ${data["username"]} :)",
              useCustomDesign: true,
              leading: SizedBox.shrink(),
              actions: [
                IconButton(
                    onPressed: () async {
                      final isOnline =
                          await ConnectivityService.ensureConnected(
                        context,
                        actionDescription: 'add a transaction',
                      );
                      if (!isOnline) return;

                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTransactionPage(),
                        ),
                      );

                      if (result == true && mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Transaction saved successfully.'),
                            ),
                          );
                      }
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF1A1A1A))),
                IconButton(
                  onPressed: () async {
                    final confirmed = await DialogBox().showConfirmationDialog(
                      context,
                      title: 'Confirm Logout',
                      message:
                          'You are about to logout. Are you sure you want to continue?',
                      confirmText: 'Logout',
                      cancelText: 'Cancel',
                      isDangerous: false,
                    );

                    if (confirmed) {
                      AuthFirestoreService().logout();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/auth',
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Unified Balance Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildUnifiedBalanceCard(
                        totalBalance: (data["totalBalance"] as num).toDouble(),
                        income: (data["income"] as num).toDouble(),
                        expense: (data["expense"] as num).toDouble(),
                        username: data["username"]?.toString() ?? "User",
                      ),
                    ),

                    // Services section header

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Weekly Insights",
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
                              color: const Color(0xFFE74C3C),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildWeeklyExpensesChart(currUser.uid),

                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Services",
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

                    SizedBox(height: 20),

                    // Feature boxes section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: [
                            _buildFeatureBox(
                              context,
                              title: "Transactions",
                              subtitle: "View all transactions",
                              icon: Icons.receipt_long,
                              accentColor: const Color(0xFF4A90E2),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SeeAllTransactionsPage(),
                                  ),
                                );
                              },
                            ),
                            _buildFeatureBox(
                              context,
                              title: "Goals",
                              subtitle: "Your financial goals",
                              icon: Icons.savings,
                              accentColor: const Color(0xFFE67E22),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GoalsPage(),
                                  ),
                                );
                              },
                            ),
                            _buildFeatureBox(
                              context,
                              title: "Analytics",
                              subtitle: "View insights",
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
                              title: "Budget",
                              subtitle: "Set your budget",
                              icon: Icons.pie_chart,
                              accentColor: const Color(0xFF16A085),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BudgetPage()));
                              },
                            ),
                            _buildFeatureBox(
                              context,
                              title: "IOU",
                              subtitle: "Track money you owe or are owed",
                              icon: Icons.receipt_long,
                              accentColor: const Color(0xFF3498DB),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => IOUPage()));
                              },
                            ),
                            _buildFeatureBox(
                              context,
                              title: "Account",
                              subtitle: "Your Personal Account Information",
                              icon: Icons.person,
                              accentColor: const Color(0xFF9B59B6),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AccountSettingsPage())).then((_) {
                                  // Refresh currency when returning from settings
                                  setState(() {
                                    initCurrency();
                                  });
                                });
                              },
                            ),
                            _buildFeatureBox(
                              context,
                              title: "Summary",
                              subtitle: "Your month at a glance",
                              icon: Icons.calendar_month_rounded,
                              accentColor: const Color(0xFF8E44AD),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MonthlySummaryPage()));
                              },
                            ),
                            _buildFeatureBox(
                              context,
                              title: "Wallets",
                              subtitle: "Cash, Bank & Digital",
                              icon: Icons.account_balance_wallet,
                              accentColor: const Color(0xFF2ECC71),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const WalletsPage()));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Weekly Expenses Chart Section

                    const SizedBox(height: 24),
                    if (_isBannerAdLoaded)
                      Center(
                        child: Container(
                          width: _bannerAd.size.width.toDouble(),
                          height: _bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
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
          // Decorative circles
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

          // Main content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Balance Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Balance",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          totalBalance.toString(),
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

                // Divider
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

                // Income and Expense Row
                Row(
                  children: [
                    // Income
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to transactions page filtered by income
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
                          label: "Income",
                          amount: income,
                          color: const Color(0xFF4ADE80),
                          iconBackgroundColor:
                              const Color(0xFF4ADE80).withOpacity(0.2),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Expense
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to transactions page filtered by expense
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
                          label: "Expense",
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

                // Card Holder Name (like credit card)
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
            amount.toString(),
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
                    "Last 7 Days",
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
                              "₹${value.toInt()}",
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
                            "$dayName\n",
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: "₹${rod.toY.toStringAsFixed(0)}",
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
