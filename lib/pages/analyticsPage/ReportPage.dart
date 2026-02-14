import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/service/TransactionFirestoreService.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:finance_tracker/widgets/reportPage/TransactionChartWidget.dart';
import 'package:finance_tracker/widgets/reportPage/TransactionPieChartWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _currencySymbol = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) {
      setState(() {
        _currencySymbol = symbol;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: StandardAppBar(
        title: 'Analytics',
        subtitle: 'Your financial insights',
        useCustomDesign: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 1. Monthly Transaction Summary Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionHeader('Monthly Summary'),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildMonthlySummaryChart(uid),
            ),

            const SizedBox(height: 32),

            // 2. Weekly Bar Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionHeader('Weekly Trends'),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: TransactionChartWidget(uid: uid),
              ),
            ),

            const SizedBox(height: 32),

            // 3. Category Pie Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionHeader('Category Breakdown'),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: const TransactionPieChartsWidget(),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Shared Helpers ─────────────────────────────────────────────

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

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

  // ─── Monthly Summary Chart ─────────────────────────────────────

  Widget _buildMonthlySummaryChart(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TransactionFirestoreService().getTransactionsOfUser(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 340,
            decoration: _cardDecoration(),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 200,
            decoration: _cardDecoration(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_rounded,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No transactions this month',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }

        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        // Aggregate daily income & expense for the current month
        Map<int, double> dailyIncome = {};
        Map<int, double> dailyExpense = {};
        double totalIncome = 0;
        double totalExpense = 0;
        int txCount = 0;

        for (var tx in snapshot.data!) {
          if (tx['date'] == null) continue;
          final date = (tx['date'] as Timestamp).toDate();
          if (date.isBefore(startOfMonth) || date.isAfter(endOfMonth)) continue;

          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final day = date.day;
          txCount++;

          if (tx['type'] == 'INCOME') {
            dailyIncome[day] = (dailyIncome[day] ?? 0) + amount;
            totalIncome += amount;
          } else if (tx['type'] == 'EXPENSE') {
            dailyExpense[day] = (dailyExpense[day] ?? 0) + amount;
            totalExpense += amount;
          }
        }

        final netBalance = totalIncome - totalExpense;

        // Build line chart spots
        final List<FlSpot> incomeSpots = [];
        final List<FlSpot> expenseSpots = [];
        double maxY = 0;

        for (int d = 1; d <= now.day; d++) {
          final inc = dailyIncome[d] ?? 0;
          final exp = dailyExpense[d] ?? 0;
          incomeSpots.add(FlSpot(d.toDouble(), inc));
          expenseSpots.add(FlSpot(d.toDouble(), exp));
          if (inc > maxY) maxY = inc;
          if (exp > maxY) maxY = exp;
        }

        maxY = maxY == 0 ? 100 : maxY * 1.3;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: month info + stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(now),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$txCount transactions',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: netBalance >= 0
                          ? const Color(0xFF4ADE80).withOpacity(0.12)
                          : const Color(0xFFFF6B6B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${netBalance >= 0 ? '+' : ''}$_currencySymbol ${netBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: netBalance >= 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Summary tiles
              Row(
                children: [
                  _buildMiniStat('Income', totalIncome, const Color(0xFF4ADE80),
                      Icons.arrow_downward_rounded),
                  const SizedBox(width: 12),
                  _buildMiniStat('Expense', totalExpense,
                      const Color(0xFFFF6B6B), Icons.arrow_upward_rounded),
                ],
              ),

              const SizedBox(height: 24),

              // Line chart
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minX: 1,
                    maxX: daysInMonth.toDouble(),
                    minY: 0,
                    maxY: maxY,
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
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: (daysInMonth / 6).ceilToDouble(),
                          getTitlesWidget: (value, meta) {
                            final day = value.toInt();
                            if (day < 1 || day > daysInMonth)
                              return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                day.toString(),
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
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
                            return Text(
                              _formatAmount(value),
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF1A1A2E),
                        tooltipRoundedRadius: 12,
                        tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final isIncome = spot.barIndex == 0;
                            return LineTooltipItem(
                              '${isIncome ? 'Income' : 'Expense'}\n$_currencySymbol ${spot.y.toStringAsFixed(0)}',
                              TextStyle(
                                color: isIncome
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Income line
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: const Color(0xFF4ADE80),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF4ADE80).withOpacity(0.2),
                              const Color(0xFF4ADE80).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // Expense line
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: const Color(0xFFFF6B6B),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFF6B6B).withOpacity(0.2),
                              const Color(0xFFFF6B6B).withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot('Income', const Color(0xFF4ADE80)),
                  const SizedBox(width: 24),
                  _buildLegendDot('Expense', const Color(0xFFFF6B6B)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(
      String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(
                    '$_currencySymbol ${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600])),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toInt().toString();
  }
}
