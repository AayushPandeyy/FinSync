import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TransactionPieChartsWidget extends StatefulWidget {
  const TransactionPieChartsWidget({super.key});

  @override
  State<TransactionPieChartsWidget> createState() =>
      _TransactionPieChartsWidgetState();
}

class _TransactionPieChartsWidgetState
    extends State<TransactionPieChartsWidget> {
  bool _showExpenses = true;
  int _touchedIndex = -1;
  late final Stream<List<Map<String, dynamic>>> _transactionStream;

  @override
  void initState() {
    super.initState();
    _transactionStream = TransactionFirestoreService()
        .getTransactionsOfUser(FirebaseAuth.instance.currentUser!.uid);
  }

  static const List<Color> _chartColors = [
    Color(0xFF4A90E2),
    Color(0xFFE74C3C),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFF3498DB),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFFCDDC39),
    Color(0xFF795548),
    Color(0xFF9E9E9E),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _transactionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4A90E2))),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_rounded,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No data available',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }

        Map<String, double> incomeByCategory = {};
        Map<String, double> expenseByCategory = {};

        for (var transaction in snapshot.data!) {
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          final category = transaction['category']?.toString() ?? 'Other';
          final type = transaction['type']?.toString();

          if (type == 'INCOME') {
            incomeByCategory[category] =
                (incomeByCategory[category] ?? 0) + amount;
          } else if (type == 'EXPENSE') {
            expenseByCategory[category] =
                (expenseByCategory[category] ?? 0) + amount;
          }
        }

        final currentData =
            _showExpenses ? expenseByCategory : incomeByCategory;

        if (currentData.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                _showExpenses ? 'No expense data' : 'No income data',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          );
        }

        // Sort by amount descending
        final sortedEntries = currentData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = sortedEntries.fold(0.0, (sum, e) => sum + e.value);

        return Column(
          children: [
            // Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('By Category',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800])),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggle(
                          'Expense',
                          _showExpenses,
                          const Color(0xFFFF6B6B),
                          () => setState(() {
                                _showExpenses = true;
                                _touchedIndex = -1;
                              })),
                      _buildToggle(
                          'Income',
                          !_showExpenses,
                          const Color(0xFF4ADE80),
                          () => setState(() {
                                _showExpenses = false;
                                _touchedIndex = -1;
                              })),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pie chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 3,
                  centerSpaceRadius: 50,
                  startDegreeOffset: -90,
                  sections: List.generate(sortedEntries.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final entry = sortedEntries[i];
                    final percentage = (entry.value / total) * 100;
                    return PieChartSectionData(
                      color: _chartColors[i % _chartColors.length],
                      value: entry.value,
                      title:
                          isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
                      radius: isTouched ? 45 : 35,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Legend list
            ...List.generate(sortedEntries.length, (i) {
              final entry = sortedEntries[i];
              final percentage = (entry.value / total) * 100;
              final isTouched = i == _touchedIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isTouched
                      ? _chartColors[i % _chartColors.length].withOpacity(0.08)
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTouched
                        ? _chartColors[i % _chartColors.length].withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _chartColors[i % _chartColors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isTouched ? FontWeight.w700 : FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _chartColors[i % _chartColors.length],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildToggle(
      String label, bool isSelected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : Colors.grey[500],
            )),
      ),
    );
  }
}
