import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:flutter/material.dart';

class InvoiceManagementPage extends StatelessWidget {
  const InvoiceManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: const StandardAppBar(
        title: 'Invoices',
        subtitle: 'Paid and unpaid tracking',
        useCustomDesign: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _InvoiceTile(
            title: 'Create invoices',
            subtitle: 'Add client details, line items, and due dates.',
            icon: Icons.add_card_rounded,
          ),
          SizedBox(height: 10),
          _InvoiceTile(
            title: 'Track paid / unpaid',
            subtitle: 'Monitor status and outstanding balances.',
            icon: Icons.payments_outlined,
          ),
          SizedBox(height: 10),
          _InvoiceTile(
            title: 'Send PDF / share link',
            subtitle: 'Share invoices quickly with clients.',
            icon: Icons.picture_as_pdf_outlined,
          ),
          SizedBox(height: 10),
          _InvoiceTile(
            title: 'Auto reminders',
            subtitle: 'Notify clients before and after due dates.',
            icon: Icons.notifications_active_outlined,
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InvoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Color(0xFFDC2626)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
