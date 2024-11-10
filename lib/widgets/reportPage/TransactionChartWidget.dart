import 'package:finance_tracker/service/FirestoreService.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionChartWidget extends StatelessWidget {
  final String uid;

  const TransactionChartWidget({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: FirestoreService().getTransactionsGroupedByDay(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
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

        if (!snapshot.hasData ||
            (snapshot.data?['income']?.isEmpty ?? true) &&
                (snapshot.data?['expense']?.isEmpty ?? true)) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No transaction data available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Get all unique dates from both income and expense
        Set<String> allDates = {
          ...snapshot.data!['income']?.keys ?? [],
          ...snapshot.data!['expense']?.keys ?? []
        };
        List<String> sortedDates = allDates.toList()..sort();

        return AspectRatio(
          aspectRatio: 1,
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Weekly Transaction Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxAmount(snapshot.data!),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              String amount = NumberFormat.currency(
                                symbol: 'Rs ',
                                decimalDigits: 2,
                              ).format(rod.toY);
                              String type =
                                  rodIndex == 0 ? 'Income' : 'Expense';
                              return BarTooltipItem(
                                '$type\n$amount',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= sortedDates.length) {
                                  return const SizedBox();
                                }
                                final date =
                                    DateTime.parse(sortedDates[value.toInt()]);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('MM/dd').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  'Rs ${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          sortedDates.length,
                          (index) {
                            final date = sortedDates[index];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: snapshot.data!['income']?[date] ?? 0,
                                  width: 12,
                                  color: Colors.green.shade300,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: snapshot.data!['expense']?[date] ?? 0,
                                  width: 12,
                                  color: Colors.red.shade300,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Income', Colors.green.shade300),
                      const SizedBox(width: 16),
                      _buildLegendItem('Expense', Colors.red.shade300),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  double _getMaxAmount(Map<String, Map<String, double>> data) {
    double maxIncome = 0;
    double maxExpense = 0;

    data['income']?.values.forEach((amount) {
      if (amount > maxIncome) maxIncome = amount;
    });

    data['expense']?.values.forEach((amount) {
      if (amount > maxExpense) maxExpense = amount;
    });

    return (maxIncome > maxExpense ? maxIncome : maxExpense) * 1.2;
  }
}
