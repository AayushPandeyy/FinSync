import 'package:finance_tracker/pages/businessMode/businessPage/BusinessGoalsPage.dart';
import 'package:finance_tracker/pages/businessMode/businessPage/BusinessIncomeExpensePage.dart';
import 'package:finance_tracker/pages/businessMode/clientsPage/ClientsPage.dart';
import 'package:finance_tracker/pages/businessMode/businessPage/DepartmentBudgetPage.dart';
import 'package:finance_tracker/pages/businessMode/businessPage/InvoiceManagementPage.dart';
import 'package:finance_tracker/pages/personalMode/walletsPage/WalletsPage.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:flutter/material.dart';

class BusinessModeBody extends StatelessWidget {
  const BusinessModeBody({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final currency = CurrencyService.getCurrencySymbolSync();
    final revenue = _asDouble(data['income']);
    final expenses = _asDouble(data['expense']);
    final walletBalance = _asDouble(data['totalBalance']);
    final netProfit = revenue - expenses;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletsPage(),
                  ),
                );
              },
              child: _buildBusinessWalletCard(
                currency: currency,
                balance: walletBalance,
                receivable: revenue * 0.28,
                payable: expenses * 0.21,
              ),
            ),
            const SizedBox(height: 16),
            _buildBusinessSectionTitle('Profit & Loss Dashboard'),
            const SizedBox(height: 10),
            _buildProfitLossCard(
              currency: currency,
              revenue: revenue,
              expenses: expenses,
              netProfit: netProfit,
            ),
            const SizedBox(height: 16),
            _buildBusinessSectionTitle('Business Services'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                _buildFeatureBox(
                  context,
                  title: 'Revenue & Expense',
                  subtitle: 'Track business cash flow',
                  icon: Icons.stacked_line_chart_rounded,
                  accentColor: const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessIncomeExpensePage(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context,
                  title: 'Clients',
                  subtitle: 'Manage your business clients',
                  icon: Icons.groups_rounded,
                  accentColor: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientsPage(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context,
                  title: 'Department Budgets',
                  subtitle: 'Marketing, product, event budgets',
                  icon: Icons.pie_chart_outline_rounded,
                  accentColor: const Color(0xFFEA580C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DepartmentBudgetPage(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context,
                  title: 'Business Goals',
                  subtitle: 'Plan milestones and track progress',
                  icon: Icons.flag_outlined,
                  accentColor: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessGoalsPage(),
                      ),
                    );
                  },
                ),
                _buildFeatureBox(
                  context,
                  title: 'Invoices',
                  subtitle: 'Create, track, share, and remind',
                  icon: Icons.receipt_long_rounded,
                  accentColor: const Color(0xFFDC2626),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvoiceManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildBusinessWalletCard({
    required String currency,
    required double balance,
    required double receivable,
    required double payable,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Business Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Receivable\n$currency ${receivable.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Payable\n$currency ${payable.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossCard({
    required String currency,
    required double revenue,
    required double expenses,
    required double netProfit,
  }) {
    final trends = <double>[0.45, 0.72, 0.66, 0.58, 0.83, 0.79];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Net Profit: $currency ${netProfit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: netProfit >= 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
              const Icon(Icons.insights_rounded, color: Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Revenue $currency ${revenue.toStringAsFixed(2)} • Expenses $currency ${expenses.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Monthly trend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trends
                  .map(
                    (value) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FractionallySizedBox(
                          heightFactor: value,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withOpacity(0.75),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Top spending: Operations, Salaries, Marketing',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
}
