import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionPieChartsWidget extends StatelessWidget {
  const TransactionPieChartsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService()
          .getTransactionsOfUser(FirebaseAuth.instance.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator.adaptive(
              backgroundColor: Colors.yellow,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error loading data: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No transaction data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Process data for pie charts
        Map<String, double> incomeByCategory = {};
        Map<String, double> expenseByCategory = {};

        for (var transaction in snapshot.data!) {
          final amount = transaction['amount']?.toDouble() ?? 0.0;
          final category = transaction['category'] ?? 'Other';
          final type = transaction['type'];

          if (type == 'INCOME') {
            incomeByCategory[category] =
                (incomeByCategory[category] ?? 0) + amount;
          } else if (type == 'EXPENSE') {
            expenseByCategory[category] =
                (expenseByCategory[category] ?? 0) + amount;
          }
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Income Pie Chart
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Income Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                        height: 240,
                        child: _buildPieChart(
                          incomeByCategory,
                          Colors.green,
                          'income',
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildLegend(incomeByCategory, Colors.green),
                    ],
                  ),
                ),
              ),

              // Expense Pie Chart
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Expense Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                        height: 240,
                        child: _buildPieChart(
                          expenseByCategory,
                          Colors.red,
                          'expense',
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildLegend(expenseByCategory, Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart(
      Map<String, double> data, MaterialColor baseColor, String type) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No $type transactions',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final total =
        data.values.isNotEmpty ? data.values.reduce((a, b) => a + b) : 0.0;
    final List<PieChartSectionData> sections = [];

    int colorIndex = 0;
    data.forEach((category, amount) {
      final percentage = (amount / total) * 100;
      sections.add(
        PieChartSectionData(
          color: baseColor[((colorIndex + 3) * 100)],
          value: percentage,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildLegend(Map<String, double> data, MaterialColor baseColor) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final total =
        data.values.isNotEmpty ? data.values.reduce((a, b) => a + b) : 0.0;
    int colorIndex = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = baseColor[((colorIndex + 3) * 100)];
        colorIndex++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.key}: ${NumberFormat.currency(
                symbol: 'Rs ',
                decimalDigits: 2,
              ).format(entry.value)} (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
