import 'package:finance_tracker/pages/common/accountsPage/AccountSettingsPage.dart';
import 'package:finance_tracker/pages/homePage/ServicesListPage.dart';
import 'package:finance_tracker/pages/personalMode/IOUpage/IOUPage.dart';
import 'package:finance_tracker/pages/personalMode/analyticsPage/ReportPage.dart';
import 'package:finance_tracker/pages/personalMode/budgetPage/BudgetPage.dart';
import 'package:finance_tracker/pages/personalMode/friendsPage/FriendsPage.dart';
import 'package:finance_tracker/pages/personalMode/goalsPage/GoalsPage.dart';
import 'package:finance_tracker/pages/personalMode/monthlySummaryPage/MonthlySummaryPage.dart';
import 'package:finance_tracker/pages/personalMode/splitBillsPage/SplitBillsPage.dart';
import 'package:finance_tracker/pages/personalMode/templatesPage/TemplatesPage.dart';
import 'package:finance_tracker/pages/personalMode/transactionsPage/SeeAllTransactionsPage.dart';
import 'package:finance_tracker/pages/personalMode/walletsPage/WalletsPage.dart';
import 'package:finance_tracker/pages/personalMode/transferPage/TransferPage.dart';
import 'package:flutter/material.dart';

class PersonalModeDrawer extends StatelessWidget {
  const PersonalModeDrawer({super.key});

  void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _openService(BuildContext context, String title) {
    switch (title) {
      case 'Transactions':
        _openPage(context, const SeeAllTransactionsPage());
        break;
      case 'Goals':
        _openPage(context, const GoalsPage());
        break;
      case 'Analytics':
        _openPage(context, const ReportPage());
        break;
      case 'Budget':
        _openPage(context, BudgetPage());
        break;
      case 'IOU':
        _openPage(context, IOUPage());
        break;
      case 'Friends':
        _openPage(context, const FriendsPage());
        break;
      case 'Account':
        _openPage(context, AccountSettingsPage());
        break;
      case 'Summary':
        _openPage(context, const MonthlySummaryPage());
        break;
      case 'Wallets':
        _openPage(context, const WalletsPage());
        break;
      case 'Transfer':
        _openPage(context, const TransferPage());
        break;
      case 'All Services':
        _openPage(context, const ServicesListPage());
        break;
      case 'Split Bills':
        _openPage(context, const SplitBillsPage());
        break;
      case 'Templates':
        _openPage(context, const TemplatesPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF6F8FA),
      width: MediaQuery.sizeOf(context).width * 0.84,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A90E2),
                    Color(0xFF16A085),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FinSync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quick access to your personal finance tools.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                children: [
                  _DrawerSectionTitle(
                    title: 'Services',
                  ),
                  const SizedBox(height: 10),
                  _DrawerTile(
                    icon: Icons.receipt_long,
                    title: 'Transactions',
                    color: const Color(0xFF4A90E2),
                    onTap: () => _openService(context, 'Transactions'),
                  ),
                  // Goals is hidden from the menu but still fully implemented —
                  // GoalsPage and its route in _openService remain.
                  // _DrawerTile(
                  //   icon: Icons.savings,
                  //   title: 'Goals',
                  //   color: const Color(0xFFE67E22),
                  //   onTap: () => _openService(context, 'Goals'),
                  // ),
                  _DrawerTile(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    color: const Color(0xFFE74C3C),
                    onTap: () => _openService(context, 'Analytics'),
                  ),
                  _DrawerTile(
                    icon: Icons.pie_chart,
                    title: 'Budget',
                    color: const Color(0xFF16A085),
                    onTap: () => _openService(context, 'Budget'),
                  ),
                  _DrawerTile(
                    icon: Icons.request_page,
                    title: 'IOU',
                    color: const Color(0xFF3498DB),
                    onTap: () => _openService(context, 'IOU'),
                  ),
                  _DrawerTile(
                    icon: Icons.group,
                    title: 'Friends',
                    color: const Color(0xFF3498DB),
                    onTap: () => _openService(context, 'Friends'),
                  ),
                  _DrawerTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'Summary',
                    color: const Color(0xFF8E44AD),
                    onTap: () => _openService(context, 'Summary'),
                  ),
                  _DrawerTile(
                    icon: Icons.account_balance_wallet,
                    title: 'Wallets',
                    color: const Color(0xFF2ECC71),
                    onTap: () => _openService(context, 'Wallets'),
                  ),
                  _DrawerTile(
                    icon: Icons.swap_horiz,
                    title: 'Transfer',
                    color: const Color(0xFF20B894),
                    onTap: () => _openService(context, 'Transfer'),
                  ),
                  // Split Bills is hidden from the menu but still fully
                  // implemented — SplitBillsPage and its route remain.
                  _DrawerTile(
                    icon: Icons.apps_rounded,
                    title: 'Split Bills',
                    color: const Color(0xFF34495E),
                    onTap: () => _openService(context, 'Split Bills'),
                  ),
                  _DrawerTile(
                    icon: Icons.dashboard_customize,
                    title: 'Templates',
                    color: const Color(0xFFF39C12),
                    onTap: () => _openService(context, 'Templates'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9AA3AF),
        ),
      ),
    );
  }
}
