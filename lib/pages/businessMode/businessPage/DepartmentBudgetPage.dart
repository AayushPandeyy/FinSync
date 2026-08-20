import 'package:finance_tracker/pages/personalMode/budgetPage/BudgetPage.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:flutter/material.dart';

class DepartmentBudgetPage extends StatelessWidget {
  const DepartmentBudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: const StandardAppBar(
        title: 'Department Budgets',
        subtitle: 'Segmented budget planning',
        useCustomDesign: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BudgetHint(title: 'Marketing budget'),
            const SizedBox(height: 8),
            const _BudgetHint(title: 'Product development budget'),
            const SizedBox(height: 8),
            const _BudgetHint(title: 'Event budget'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudgetPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Budget Module'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetHint extends StatelessWidget {
  final String title;

  const _BudgetHint({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
