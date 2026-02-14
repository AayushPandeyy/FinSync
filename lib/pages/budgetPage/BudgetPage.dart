import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/enums/budget/BudgetType.dart';
import 'package:finance_tracker/enums/transaction/TransactionType.dart';
import 'package:finance_tracker/service/BudgetFirestoreService.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
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

  Map<String, String> getCurrentDateInfo() {
    final DateTime now = DateTime.now();

    final String monthYear = DateFormat('MMMM yyyy').format(now);

    final String fullDate = DateFormat('EEEE MMM d yyyy').format(now);

    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final int weekNumber = ((now.day + firstDayOfMonth.weekday - 1) / 7).ceil();

    return {
      'monthYear': monthYear,
      'fullDate': fullDate,
      'week': 'Week $weekNumber'
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

      final isInMonth = !transactionDate.isBefore(startOfMonth) &&
          !transactionDate.isAfter(endOfMonth);

      if (!isInMonth) continue;

      if (transaction['type'] == 'EXPENSE') {
        final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
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
            final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
            total += amount;
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
            final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
            total += amount;
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            left: 28,
            right: 28,
            top: 28,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                budgetId == null ? "Set $type Budget" : "Edit $type Budget",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.currency_rupee,
                        color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: "Enter budget amount",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 15),
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                        // Create new budget
                        await _budgetService.addMonthlyWeeklyOrDailyBudget(
                          uid,
                          amount,
                          budgetType,
                        );
                      } else {
                        // Edit existing budget
                        await _budgetService.editBudget(
                          uid,
                          budgetId,
                          amount,
                          budgetType,
                        );
                      }

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    budgetId == null ? 'Set Budget' : 'Update Budget',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
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
        stream: _budgetService.getBudget(uid),
        builder: (context, budgetSnapshot) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: TransactionFirestoreService()
                .getTransactionsBasedOnType(uid, TransactionType.EXPENSE.name),
            builder: (context, transactionsSnapshot) {
              Map<String, String> currentDateInfo = getCurrentDateInfo();

              // Loading state
              if (budgetSnapshot.connectionState == ConnectionState.waiting ||
                  transactionsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Get all budgets
              final budgets = budgetSnapshot.data ?? [];

              // Find specific budget types
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

              // Extract budget amounts and IDs
              final monthlyBudget =
                  (monthlyBudgetData?['amount'] as num?)?.toDouble();
              final monthlyBudgetId = monthlyBudgetData?['budgetId'] as String?;

              final weeklyBudget =
                  (weeklyBudgetData?['amount'] as num?)?.toDouble();
              final weeklyBudgetId = weeklyBudgetData?['budgetId'] as String?;

              final dailyLimit =
                  (dailyBudgetData?['amount'] as num?)?.toDouble();
              final dailyBudgetId = dailyBudgetData?['budgetId'] as String?;

              // Get transactions and calculate spent amounts
              final transactions = transactionsSnapshot.data ?? [];
              final monthlySpent = _calculateMonthlySpent(transactions);
              final weeklySpent = _calculateWeeklySpent(transactions);
              final dailySpent = _calculateDailySpent(transactions);

              return Column(
                children: [
                  Container(
                    height: 1,
                    color: const Color(0xFFF0F0F0),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        BudgetCard(
                          title: 'Monthly Budget',
                          budget: monthlyBudget,
                          spent: monthlySpent,
                          subtitle: currentDateInfo['monthYear'] ?? '',
                          onTap: () => _showSetBudgetDialog(
                              'Monthly', monthlyBudgetId, monthlyBudget),
                        ),
                        const SizedBox(height: 16),
                        BudgetCard(
                          title: 'Weekly Budget',
                          budget: weeklyBudget,
                          spent: weeklySpent,
                          subtitle: currentDateInfo['week'] ?? '',
                          onTap: () => _showSetBudgetDialog(
                              'Weekly', weeklyBudgetId, weeklyBudget),
                        ),
                        const SizedBox(height: 16),
                        BudgetCard(
                          title: 'Daily Limit',
                          budget: dailyLimit,
                          spent: dailySpent,
                          subtitle: currentDateInfo['fullDate'] ?? '',
                          onTap: () => _showSetBudgetDialog(
                              'Daily', dailyBudgetId, dailyLimit),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
