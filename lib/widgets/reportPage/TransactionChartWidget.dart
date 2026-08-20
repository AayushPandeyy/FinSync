import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionChartWidget extends StatefulWidget {
  final String uid;

  const TransactionChartWidget({
    super.key,
    required this.uid,
  });

  @override
  State<TransactionChartWidget> createState() => _TransactionChartWidgetState();
}

class _TransactionChartWidgetState extends State<TransactionChartWidget> {
  bool _showExpenses = true;
  late final Future<Map<String, Map<String, double>>> _chartFuture;

  @override
  void initState() {
    super.initState();
    _chartFuture =
        TransactionFirestoreService().getTransactionsGroupedByDay(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, double>>>(
      future: _chartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 250,
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4A90E2))),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No weekly data available',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final expenseData = data['expense'] ?? {};
        final incomeData = data['income'] ?? {};
        final chartData = _showExpenses ? expenseData : incomeData;
        final chartColor =
            _showExpenses ? const Color(0xFFFF6B6B) : const Color(0xFF4ADE80);
        final chartColorLight =
            _showExpenses ? const Color(0xFFFFB4B4) : const Color(0xFFA7F3D0);

        final now = DateTime.now();
        final List<DateTime> last7Days =
            List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

        double maxY = 0;
        final List<BarChartGroupData> barGroups = [];

        for (int i = 0; i < last7Days.length; i++) {
          final dayKey = DateFormat('yyyy-MM-dd').format(last7Days[i]);
          final amount = chartData[dayKey] ?? 0.0;
          if (amount > maxY) maxY = amount;
          final isToday = DateUtils.isSameDay(last7Days[i], now);

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: isToday ? 24 : 18,
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [chartColor, chartColorLight],
                  ),
                ),
              ],
            ),
          );
        }

        maxY = maxY == 0 ? 100 : maxY * 1.3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Last 7 Days',
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
                          () => setState(() => _showExpenses = true)),
                      _buildToggle(
                          'Income',
                          !_showExpenses,
                          const Color(0xFF4ADE80),
                          () => setState(() => _showExpenses = false)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
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
                        color: Colors.grey.withOpacity(0.08), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= last7Days.length)
                            return const SizedBox();
                          final day = last7Days[value.toInt()];
                          final isToday = DateUtils.isSameDay(day, now);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              isToday
                                  ? 'Today'
                                  : DateFormat('E').format(day).substring(0, 3),
                              style: TextStyle(
                                color: isToday ? chartColor : Colors.grey[500],
                                fontSize: 11,
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return Text(_formatAmount(value),
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500));
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1A1A2E),
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      getTooltipItem: (group, gIdx, rod, rIdx) {
                        final day = last7Days[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('EEE, MMM d').format(day)}\n',
                          TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(
                              text: _formatAmount(rod.toY),
                              style: TextStyle(
                                  color: chartColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
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

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toInt().toString();
  }
}
