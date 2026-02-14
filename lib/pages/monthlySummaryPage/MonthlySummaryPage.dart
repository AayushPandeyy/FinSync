import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/IOU/IOUStatus.dart';
import 'package:finance_tracker/enums/IOU/IOUType.dart';
import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/models/IOU.dart';
import 'package:finance_tracker/service/BudgetFirestoreService.dart';
import 'package:finance_tracker/service/GoalsFirestoreService.dart';
import 'package:finance_tracker/service/IOUFirestoreService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/Utilities.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class MonthlySummaryPage extends StatefulWidget {
  const MonthlySummaryPage({super.key});

  @override
  State<MonthlySummaryPage> createState() => _MonthlySummaryPageState();
}

class _MonthlySummaryPageState extends State<MonthlySummaryPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final TransactionFirestoreService _transactionService =
      TransactionFirestoreService();
  final BudgetFirestoreService _budgetService = BudgetFirestoreService();
  final GoalsFirestoreService _goalsService = GoalsFirestoreService();
  final Ioufirestoreservice _iouService = Ioufirestoreservice();

  late final Stream<List<Map<String, dynamic>>> _transactionStream;
  late final Stream<List<Map<String, dynamic>>> _budgetStream;
  late final Stream<List<Map<String, dynamic>>> _goalsStream;
  late final Stream<List<IOU>> _iouStream;
  late final Stream<double> _savingsStream;

  String _currencySymbol = 'Rs';
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _transactionStream = _transactionService.getTransactionsOfUser(uid);
    _budgetStream = _budgetService.getBudget(uid);
    _goalsStream = _goalsService.getGoalsOfUser(uid);
    _iouStream = _iouService.getIOUsStream(uid);
    _savingsStream = _transactionService.getTotalAmountInACategory("Savings");
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) setState(() => _currencySymbol = symbol);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    if (!_isCurrentMonth) {
      setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      });
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  // ─── Date helpers ────────────────────────────────────────────────

  DateTime get _startOfMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _endOfMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

  bool _isInSelectedMonth(DateTime date) {
    return !date.isBefore(_startOfMonth) && !date.isAfter(_endOfMonth);
  }

  // ─── Transaction helpers ─────────────────────────────────────────

  double _monthlyIncome(List<Map<String, dynamic>> transactions) {
    double total = 0;
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final date = (tx['date'] as Timestamp).toDate();
      if (_isInSelectedMonth(date) && tx['type'] == 'INCOME') {
        total += (tx['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  double _monthlyExpense(List<Map<String, dynamic>> transactions) {
    double total = 0;
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final date = (tx['date'] as Timestamp).toDate();
      if (_isInSelectedMonth(date) && tx['type'] == 'EXPENSE') {
        total += (tx['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  Map<String, double> _categoryBreakdown(
      List<Map<String, dynamic>> transactions) {
    final map = <String, double>{};
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final date = (tx['date'] as Timestamp).toDate();
      if (_isInSelectedMonth(date) && tx['type'] == 'EXPENSE') {
        final cat = tx['category']?.toString() ?? 'Others';
        map[cat] = (map[cat] ?? 0) + ((tx['amount'] as num?)?.toDouble() ?? 0);
      }
    }
    return map;
  }

  Map<String, double> _incomeCategoryBreakdown(
      List<Map<String, dynamic>> transactions) {
    final map = <String, double>{};
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final date = (tx['date'] as Timestamp).toDate();
      if (_isInSelectedMonth(date) && tx['type'] == 'INCOME') {
        final cat = tx['category']?.toString() ?? 'Others';
        map[cat] = (map[cat] ?? 0) + ((tx['amount'] as num?)?.toDouble() ?? 0);
      }
    }
    return map;
  }

  int _transactionCount(List<Map<String, dynamic>> transactions) {
    int count = 0;
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final date = (tx['date'] as Timestamp).toDate();
      if (_isInSelectedMonth(date)) count++;
    }
    return count;
  }

  // ─── Budget spent helpers (_selectedMonth aware) ──────────────

  double _calculateMonthlySpent(List<Map<String, dynamic>> transactions) {
    double total = 0;
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final d = (tx['date'] as Timestamp).toDate();
      if (_isInSelectedMonth(d) && tx['type'] == 'EXPENSE') {
        total += (tx['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  double _calculateWeeklySpent(List<Map<String, dynamic>> transactions) {
    // For past months, show the full month's expenses
    if (!_isCurrentMonth) return _calculateMonthlySpent(transactions);

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek =
        startOfWeekDay.add(const Duration(days: 6, hours: 23, minutes: 59));
    double total = 0;
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final d = (tx['date'] as Timestamp).toDate();
      if (d.isAfter(startOfWeekDay.subtract(const Duration(seconds: 1))) &&
          d.isBefore(endOfWeek.add(const Duration(seconds: 1))) &&
          tx['type'] == 'EXPENSE') {
        total += (tx['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  double _calculateDailySpent(List<Map<String, dynamic>> transactions) {
    // For past months, show the full month's expenses
    if (!_isCurrentMonth) return _calculateMonthlySpent(transactions);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
        startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    double total = 0;
    for (var tx in transactions) {
      if (tx['date'] == null) continue;
      final d = (tx['date'] as Timestamp).toDate();
      if (d.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          d.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
          tx['type'] == 'EXPENSE') {
        total += (tx['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  // ─── Category icon lookup ────────────────────────────────────────

  IconData _getCategoryIcon(String category) {
    final cats = Categories().categories;
    for (var c in cats) {
      if (c.name == category) return c.icon;
    }
    return Icons.more_horiz;
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Monthly Summary',
        subtitle: DateFormat('MMMM yyyy').format(_selectedMonth),
        useCustomDesign: true,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _transactionStream,
          builder: (context, txSnap) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _budgetStream,
              builder: (context, budgetSnap) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _goalsStream,
                  builder: (context, goalsSnap) {
                    return StreamBuilder<List<IOU>>(
                      stream: _iouStream,
                      builder: (context, iouSnap) {
                        return StreamBuilder<double>(
                          stream: _savingsStream,
                          builder: (context, savingsSnap) {
                            final isLoading = !txSnap.hasData;

                            if (isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final transactions = txSnap.data ?? [];
                            final budgets = budgetSnap.data ?? [];
                            final goalsData = goalsSnap.data ?? [];
                            final ious = iouSnap.data ?? [];
                            final savingsAmount = savingsSnap.data ?? 0.0;

                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Month navigator
                                  _buildMonthNavigator(),
                                  const SizedBox(height: 20),

                                  // Section 1: Income vs Expense overview
                                  _buildOverviewCard(transactions),
                                  const SizedBox(height: 28),

                                  // Section 2: Budget utilization
                                  _buildSectionHeader('Budget Utilization',
                                      const Color(0xFF4A90E2)),
                                  const SizedBox(height: 14),
                                  _buildBudgetSection(budgets, transactions),
                                  const SizedBox(height: 28),

                                  // Section 3: Goals progress
                                  _buildSectionHeader('Goals Progress',
                                      const Color(0xFFE67E22)),
                                  const SizedBox(height: 14),
                                  _buildGoalsSection(goalsData, savingsAmount),
                                  const SizedBox(height: 28),

                                  // Section 4: IOUs outstanding
                                  _buildSectionHeader('IOUs Outstanding',
                                      const Color(0xFF16A085)),
                                  const SizedBox(height: 14),
                                  _buildIOUSection(ious),
                                  const SizedBox(height: 28),

                                  // Section 5: Top spending categories
                                  _buildSectionHeader('Top Spending Categories',
                                      const Color(0xFFE74C3C)),
                                  const SizedBox(height: 14),
                                  _buildCategoriesSection(transactions),
                                  const SizedBox(height: 28),

                                  // Section 6: Top income categories
                                  _buildSectionHeader('Top Income Categories',
                                      const Color(0xFF16A34A)),
                                  const SizedBox(height: 14),
                                  _buildIncomeCategoriesSection(transactions),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildMonthNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousMonth,
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: const Color(0xFF1A1A1A),
            splashRadius: 22,
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
              if (_isCurrentMonth)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: _isCurrentMonth ? null : _goToNextMonth,
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 28,
              color:
                  _isCurrentMonth ? Colors.grey[300] : const Color(0xFF1A1A1A),
            ),
            splashRadius: 22,
          ),
        ],
      ),
    );
  }

  // ─── Section 1: Overview Card ────────────────────────────────────

  Widget _buildOverviewCard(List<Map<String, dynamic>> transactions) {
    final income = _monthlyIncome(transactions);
    final expense = _monthlyExpense(transactions);
    final net = income - expense;
    final txCount = _transactionCount(transactions);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -25,
            left: -25,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                // Net balance row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _currencySymbol,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatAmount(net.abs()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: net >= 0
                            ? const Color(0xFF4ADE80).withOpacity(0.2)
                            : const Color(0xFFFF6B6B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            net >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            color: net >= 0
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFFF6B6B),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            net >= 0 ? 'Surplus' : 'Deficit',
                            style: TextStyle(
                              color: net >= 0
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFFFF6B6B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.0),
                    ]),
                  ),
                ),

                const SizedBox(height: 18),

                // Income / Expense / Transactions row
                Row(
                  children: [
                    _buildOverviewStat(
                      Icons.arrow_downward_rounded,
                      'Income',
                      '$_currencySymbol ${_formatAmount(income)}',
                      const Color(0xFF4ADE80),
                    ),
                    const SizedBox(width: 12),
                    _buildOverviewStat(
                      Icons.arrow_upward_rounded,
                      'Expense',
                      '$_currencySymbol ${_formatAmount(expense)}',
                      const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 12),
                    _buildOverviewStat(
                      Icons.receipt_long_rounded,
                      'Txns',
                      txCount.toString(),
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section 2: Budget Utilization ───────────────────────────────

  Widget _buildBudgetSection(List<Map<String, dynamic>> budgets,
      List<Map<String, dynamic>> transactions) {
    if (budgets.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'No budgets set yet',
      );
    }

    // Only show budget utilization for current month
    // (budget periods are relative to "now", not _selectedMonth)
    final monthlySpent = _calculateMonthlySpent(transactions);
    final weeklySpent = _calculateWeeklySpent(transactions);
    final dailySpent = _calculateDailySpent(transactions);

    final List<Widget> items = [];

    for (var budget in budgets) {
      final type = budget['type']?.toString() ?? '';
      final amount = (budget['amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) continue;

      double spent;
      String label;
      Color accent;
      IconData icon;

      switch (type) {
        case 'MONTHLY':
          spent = monthlySpent;
          label = 'Monthly';
          accent = const Color(0xFF4A90E2);
          icon = Icons.calendar_month_rounded;
          break;
        case 'WEEKLY':
          spent = weeklySpent;
          label = 'Weekly';
          accent = const Color(0xFFE67E22);
          icon = Icons.view_week_rounded;
          break;
        case 'DAILY':
          spent = dailySpent;
          label = 'Daily';
          accent = const Color(0xFF9B59B6);
          icon = Icons.today_rounded;
          break;
        default:
          continue;
      }

      final progress = (spent / amount).clamp(0.0, 1.0);
      final isOver = spent > amount;
      final progressColor = Utilities().getProgressColor(spent, amount);

      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isOver
                ? Border.all(color: const Color(0xFFDC2626).withOpacity(0.15))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: accent, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_currencySymbol ${_formatAmount(spent)} / $_currencySymbol ${_formatAmount(amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOver)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Over!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    )
                  else
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: progressColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'No budgets set yet',
      );
    }

    return Column(children: items);
  }

  // ─── Section 3: Goals Progress ───────────────────────────────────

  Widget _buildGoalsSection(
      List<Map<String, dynamic>> goalsData, double savingsAmount) {
    if (goalsData.isEmpty) {
      return _buildEmptyState(
        icon: Icons.savings_outlined,
        message: 'No goals set yet',
      );
    }

    final goals = goalsData.map((g) {
      return FinancialGoal(
        id: g['id'] ?? '',
        title: g['title'] ?? '',
        description: g['description'] ?? '',
        targetAmount: (g['amount'] as num?)?.toDouble() ?? 0,
        currentAmount: savingsAmount,
        deadline: g['deadline'] is Timestamp
            ? (g['deadline'] as Timestamp).toDate()
            : DateTime.now(),
      );
    }).toList();

    // Sort by nearest deadline first
    goals.sort((a, b) => a.deadline.compareTo(b.deadline));

    // Show top 3
    final display = goals.take(3).toList();

    return Column(
      children: display.map((goal) {
        final progress = goal.targetAmount > 0
            ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
            : 0.0;
        final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
        final isCompleted = goal.currentAmount >= goal.targetAmount;
        final isOverdue = daysLeft < 0 && !isCompleted;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              // Mini progress ring
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor:
                            const Color(0xFFE67E22).withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(
                          isCompleted
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFE67E22),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE67E22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$_currencySymbol ${_formatAmount(goal.currentAmount)} / $_currencySymbol ${_formatAmount(goal.targetAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Deadline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF16A34A).withOpacity(0.08)
                      : isOverdue
                          ? const Color(0xFFDC2626).withOpacity(0.08)
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted
                      ? 'Done!'
                      : isOverdue
                          ? 'Overdue'
                          : '${daysLeft}d left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF16A34A)
                        : isOverdue
                            ? const Color(0xFFDC2626)
                            : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Section 4: IOUs Outstanding ─────────────────────────────────

  Widget _buildIOUSection(List<IOU> ious) {
    final pending = ious.where((i) => i.status == IOUStatus.PENDING).toList();

    if (pending.isEmpty) {
      return _buildEmptyState(
        icon: Icons.handshake_outlined,
        message: 'All settled! No pending IOUs',
        isPositive: true,
      );
    }

    final totalOwe = pending
        .where((i) => i.iouType == IOUType.OWE)
        .fold(0.0, (sum, i) => sum + (i.amount - i.settledAmount));
    final totalOwed = pending
        .where((i) => i.iouType == IOUType.OWED)
        .fold(0.0, (sum, i) => sum + (i.amount - i.settledAmount));

    // Show top 3 pending IOUs by amount
    pending.sort((a, b) => b.amount.compareTo(a.amount));
    final display = pending.take(3).toList();

    return Column(
      children: [
        // Summary chips
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'I Owe',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_currencySymbol ${_formatAmount(totalOwe)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF4ADE80).withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Owed to Me',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_currencySymbol ${_formatAmount(totalOwed)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recent pending IOUs
        ...display.map((iou) {
          final isOwe = iou.iouType == IOUType.OWE;
          final remaining = iou.amount - iou.settledAmount;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isOwe
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF4ADE80))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOwe
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: isOwe
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        iou.personName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOwe ? 'You owe' : 'Owes you',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_currencySymbol ${_formatAmount(remaining)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isOwe
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Section 5: Top Spending Categories ──────────────────────────

  Widget _buildCategoriesSection(List<Map<String, dynamic>> transactions) {
    final breakdown = _categoryBreakdown(transactions);

    if (breakdown.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        message: 'No expenses this month',
      );
    }

    // Sort by amount descending
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();
    final totalExpense = sorted.fold(0.0, (sum, e) => sum + e.value);

    // Category colors cycling
    const categoryColors = [
      Color(0xFFE74C3C),
      Color(0xFF3498DB),
      Color(0xFFE67E22),
      Color(0xFF9B59B6),
      Color(0xFF16A085),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: top5.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final proportion =
              totalExpense > 0 ? (cat.value / totalExpense) : 0.0;
          final color = categoryColors[index % categoryColors.length];

          return Padding(
            padding: EdgeInsets.only(bottom: index < top5.length - 1 ? 16 : 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(cat.key),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              cat.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$_currencySymbol ${_formatAmount(cat.value)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: proportion,
                          minHeight: 4,
                          backgroundColor: color.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(proportion * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Section 6: Top Income Categories ────────────────────────────

  Widget _buildIncomeCategoriesSection(
      List<Map<String, dynamic>> transactions) {
    final breakdown = _incomeCategoryBreakdown(transactions);

    if (breakdown.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        message: 'No income this month',
      );
    }

    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();
    final totalIncome = sorted.fold(0.0, (sum, e) => sum + e.value);

    const categoryColors = [
      Color(0xFF16A34A),
      Color(0xFF2DD4BF),
      Color(0xFF4A90E2),
      Color(0xFFE67E22),
      Color(0xFF8B5CF6),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: top5.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final proportion = totalIncome > 0 ? (cat.value / totalIncome) : 0.0;
          final color = categoryColors[index % categoryColors.length];

          return Padding(
            padding: EdgeInsets.only(bottom: index < top5.length - 1 ? 16 : 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(cat.key),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              cat.key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$_currencySymbol ${_formatAmount(cat.value)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: proportion,
                          minHeight: 4,
                          backgroundColor: color.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(proportion * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    bool isPositive = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF16A34A).withOpacity(0.08)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isPositive ? const Color(0xFF16A34A) : Colors.grey[400],
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isPositive ? const Color(0xFF16A34A) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
