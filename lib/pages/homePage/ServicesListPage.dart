import 'package:flutter/material.dart';
import 'package:finance_tracker/pages/transactionsPage/SeeAllTransactionsPage.dart';
import 'package:finance_tracker/pages/goalsPage/GoalsPage.dart';
import 'package:finance_tracker/pages/analyticsPage/ReportPage.dart';
import 'package:finance_tracker/pages/budgetPage/BudgetPage.dart';
import 'package:finance_tracker/pages/IOUpage/IOUPage.dart';
import 'package:finance_tracker/pages/accountsPage/AccountSettingsPage.dart';
import 'package:finance_tracker/pages/monthlySummaryPage/MonthlySummaryPage.dart';
import 'package:finance_tracker/pages/walletsPage/WalletsPage.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';

class ServicesListPage extends StatelessWidget {
  const ServicesListPage({super.key});

  void _openServicePage(BuildContext context, String title) {
    Widget page;
    switch (title) {
      case 'Transactions':
        page = const SeeAllTransactionsPage();
        break;
      case 'Goals':
        page = const GoalsPage();
        break;
      case 'Analytics':
        page = const ReportPage();
        break;
      case 'Budget':
        page = BudgetPage();
        break;
      case 'IOU':
        page = IOUPage();
        break;
      case 'Account':
        page = AccountSettingsPage();
        break;
      case 'Summary':
        page = const MonthlySummaryPage();
        break;
      case 'Wallets':
        page = const WalletsPage();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  static const List<_ServiceItem> _services = [
    _ServiceItem(
      title: 'Transactions',
      subtitle: 'Track all your spending and income entries',
      icon: Icons.receipt_long,
      color: Color(0xFF4A90E2),
    ),
    _ServiceItem(
      title: 'Goals',
      subtitle: 'Set and monitor your financial targets',
      icon: Icons.savings,
      color: Color(0xFFE67E22),
    ),
    _ServiceItem(
      title: 'Analytics',
      subtitle: 'Visual insights and spending breakdowns',
      icon: Icons.analytics,
      color: Color(0xFFE74C3C),
    ),
    _ServiceItem(
      title: 'Budget',
      subtitle: 'Plan monthly limits and control expenses',
      icon: Icons.pie_chart,
      color: Color(0xFF16A085),
    ),
    _ServiceItem(
      title: 'IOU',
      subtitle: 'Manage money you owe and are owed',
      icon: Icons.request_page,
      color: Color(0xFF3498DB),
    ),
    _ServiceItem(
      title: 'Account',
      subtitle: 'Update profile and app preferences',
      icon: Icons.person,
      color: Color(0xFF9B59B6),
    ),
    _ServiceItem(
      title: 'Summary',
      subtitle: 'See your month at a quick glance',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF8E44AD),
    ),
    _ServiceItem(
      title: 'Wallets',
      subtitle: 'Manage cash, bank, and digital balances',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF2ECC71),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(
        title: 'Services',
      ),
      backgroundColor: const Color(0xFFF6F8FA),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openServicePage(context, service.title),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE9EDF2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: service.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(service.icon, color: service.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9AA3AF),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
