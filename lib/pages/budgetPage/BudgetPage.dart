import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/budget/BudgetType.dart';
import 'package:finance_tracker/enums/transaction/TransactionType.dart';
import 'package:finance_tracker/service/BudgetFirestoreService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/widgets/budgetPage/BuildBudgetCard.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final BudgetFirestoreService _budgetService = BudgetFirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String _currencySymbol = 'Rs';

  late final Stream<List<Map<String, dynamic>>> _budgetStream;
  late final Stream<List<Map<String, dynamic>>> _transactionStream;

  @override
  void initState() {
    super.initState();
    _budgetStream = _budgetService.getBudget(uid);
    _transactionStream = TransactionFirestoreService()
        .getTransactionsBasedOnType(uid, TransactionType.EXPENSE.name);
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) setState(() => _currencySymbol = symbol);
  }

  Map<String, String> getCurrentDateInfo() {
    final DateTime now = DateTime.now();
    final String monthYear = DateFormat('MMMM yyyy').format(now);
    final String fullDate = DateFormat('EEEE, MMM d').format(now);
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final int weekNumber = ((now.day + firstDayOfMonth.weekday - 1) / 7).ceil();
    return {
      'monthYear': monthYear,
      'fullDate': fullDate,
      'week': 'Week $weekNumber',
    };
  }

  double _calculateMonthlySpent(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth =
        DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    double total = 0.0;
    for (var transaction in transactions) {
      if (transaction['date'] == null) continue;
      final transactionDate = (transaction['date'] as Timestamp).toDate();
      if (!transactionDate.isBefore(startOfMonth) &&
          !transactionDate.isAfter(endOfMonth)) {
        if (transaction['type'] == 'EXPENSE') {
          total += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return total;
  }

  double _calculateWeeklySpent(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek =
        startOfWeekDay.add(const Duration(days: 6, hours: 23, minutes: 59));
    double total = 0.0;
    for (var transaction in transactions) {
      if (transaction['date'] != null) {
        final transactionDate = (transaction['date'] as Timestamp).toDate();
        if (transactionDate
                .isAfter(startOfWeekDay.subtract(const Duration(seconds: 1))) &&
            transactionDate
                .isBefore(endOfWeek.add(const Duration(seconds: 1)))) {
          if (transaction['type'] == 'EXPENSE') {
            total += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }
    return total;
  }

  double _calculateDailySpent(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
        startOfDay.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    double total = 0.0;
    for (var transaction in transactions) {
      if (transaction['date'] != null) {
        final transactionDate = (transaction['date'] as Timestamp).toDate();
        if (transactionDate
                .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            transactionDate
                .isBefore(endOfDay.add(const Duration(seconds: 1)))) {
          if (transaction['type'] == 'EXPENSE') {
            total += (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }
    return total;
  }

  void _showSetBudgetDialog(
      String type, String? budgetId, double? currentBudget) {
    final TextEditingController controller = TextEditingController(
      text: currentBudget?.toStringAsFixed(0) ?? '',
    );
    final isEditing = budgetId != null;
    final Color accentColor;
    final IconData headerIcon;

    switch (type) {
      case 'Monthly':
        accentColor = const Color(0xFF4A90E2);
        headerIcon = Icons.calendar_month_rounded;
        break;
      case 'Weekly':
        accentColor = const Color(0xFFE67E22);
        headerIcon = Icons.view_week_rounded;
        break;
      default:
        accentColor = const Color(0xFF9B59B6);
        headerIcon = Icons.today_rounded;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(headerIcon, color: accentColor, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                isEditing ? 'Edit $type Budget' : 'Set $type Budget',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEditing
                    ? 'Update or remove your $type spending limit'
                    : 'Set a $type spending limit to stay on track',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Amount input
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currencySymbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text);
                    if (amount != null && amount > 0) {
                      BudgetType budgetType;
                      if (type == 'Monthly') {
                        budgetType = BudgetType.MONTHLY;
                      } else if (type == 'Weekly') {
                        budgetType = BudgetType.WEEKLY;
                      } else {
                        budgetType = BudgetType.DAILY;
                      }

                      if (budgetId == null) {
                        await _budgetService.addMonthlyWeeklyOrDailyBudget(
                            uid, amount, budgetType);
                      } else {
                        await _budgetService.editBudget(
                            uid, budgetId, amount, budgetType);
                      }

                      if (mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Update Budget' : 'Set Budget',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Remove budget button (only when editing)
              if (isEditing) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      _showRemoveBudgetConfirmation(type, budgetId);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: const Color(0xFFDC2626).withOpacity(0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: const Color(0xFFDC2626).withOpacity(0.8)),
                        const SizedBox(width: 8),
                        const Text(
                          'Remove Budget',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showRemoveBudgetConfirmation(String type, String budgetId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Remove Budget?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your $type budget will be removed. You can always set it up again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _budgetService.deleteBudget(uid, budgetId);
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Budgets',
        subtitle: 'Manage your spending limits',
        useCustomDesign: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _budgetStream,
        builder: (context, budgetSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _transactionStream,
            builder: (context, transactionsSnapshot) {
              if (budgetSnapshot.connectionState == ConnectionState.waiting ||
                  transactionsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
                );
              }

              final budgets = budgetSnapshot.data ?? [];
              final transactions = transactionsSnapshot.data ?? [];
              final currentDateInfo = getCurrentDateInfo();

              Map<String, dynamic>? monthlyBudgetData;
              Map<String, dynamic>? weeklyBudgetData;
              Map<String, dynamic>? dailyBudgetData;

              for (var budget in budgets) {
                switch (budget['type']) {
                  case 'MONTHLY':
                    monthlyBudgetData = budget;
                    break;
                  case 'WEEKLY':
                    weeklyBudgetData = budget;
                    break;
                  case 'DAILY':
                    dailyBudgetData = budget;
                    break;
                }
              }

              final monthlyBudget =
                  (monthlyBudgetData?['amount'] as num?)?.toDouble();
              final monthlyBudgetId = monthlyBudgetData?['budgetId'] as String?;
              final weeklyBudget =
                  (weeklyBudgetData?['amount'] as num?)?.toDouble();
              final weeklyBudgetId = weeklyBudgetData?['budgetId'] as String?;
              final dailyLimit =
                  (dailyBudgetData?['amount'] as num?)?.toDouble();
              final dailyBudgetId = dailyBudgetData?['budgetId'] as String?;

              final monthlySpent = _calculateMonthlySpent(transactions);
              final weeklySpent = _calculateWeeklySpent(transactions);
              final dailySpent = _calculateDailySpent(transactions);

              // Compute overview totals
              final totalBudget = (monthlyBudget ?? 0);
              final totalSpent = monthlySpent;
              final budgetsSet = [
                if (monthlyBudget != null) 'Monthly',
                if (weeklyBudget != null) 'Weekly',
                if (dailyLimit != null) 'Daily',
              ];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  // Overview card
                  _buildOverviewCard(
                    totalBudget: totalBudget,
                    totalSpent: totalSpent,
                    budgetsSet: budgetsSet.length,
                    monthName: currentDateInfo['monthYear'] ?? '',
                  ),

                  const SizedBox(height: 28),

                  // Section header
                  _buildSectionHeader('Your Budgets'),

                  const SizedBox(height: 16),

                  // Monthly
                  BudgetCard(
                    title: 'Monthly Budget',
                    budget: monthlyBudget,
                    spent: monthlySpent,
                    subtitle: currentDateInfo['monthYear'] ?? '',
                    icon: Icons.calendar_month_rounded,
                    accentColor: const Color(0xFF4A90E2),
                    onTap: () => _showSetBudgetDialog(
                        'Monthly', monthlyBudgetId, monthlyBudget),
                  ),

                  const SizedBox(height: 12),

                  // Weekly
                  BudgetCard(
                    title: 'Weekly Budget',
                    budget: weeklyBudget,
                    spent: weeklySpent,
                    subtitle: currentDateInfo['week'] ?? '',
                    icon: Icons.view_week_rounded,
                    accentColor: const Color(0xFFE67E22),
                    onTap: () => _showSetBudgetDialog(
                        'Weekly', weeklyBudgetId, weeklyBudget),
                  ),

                  const SizedBox(height: 12),

                  // Daily
                  BudgetCard(
                    title: 'Daily Limit',
                    budget: dailyLimit,
                    spent: dailySpent,
                    subtitle: currentDateInfo['fullDate'] ?? '',
                    icon: Icons.today_rounded,
                    accentColor: const Color(0xFF9B59B6),
                    onTap: () => _showSetBudgetDialog(
                        'Daily', dailyBudgetId, dailyLimit),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─── Overview Card ──────────────────────────────────────────────

  Widget _buildOverviewCard({
    required double totalBudget,
    required double totalSpent,
    required int budgetsSet,
    required String monthName,
  }) {
    final remaining = totalBudget - totalSpent;
    final progress =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

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
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
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
                          'Spending Overview',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          monthName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$budgetsSet/3 active',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Total spent
                Text(
                  '$_currencySymbol ${totalSpent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalBudget > 0
                      ? 'of $_currencySymbol ${totalBudget.toStringAsFixed(0)} total budget'
                      : 'No monthly budgets set yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                if (totalBudget > 0) ...[
                  const SizedBox(height: 20),

                  // Progress bar
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: progress >= 0.9
                                ? const Color(0xFFFF6B6B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Remaining + percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            remaining >= 0
                                ? Icons.check_circle_outline_rounded
                                : Icons.warning_amber_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            remaining >= 0
                                ? '$_currencySymbol ${remaining.toStringAsFixed(0)} remaining'
                                : '$_currencySymbol ${remaining.abs().toStringAsFixed(0)} over budget',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
