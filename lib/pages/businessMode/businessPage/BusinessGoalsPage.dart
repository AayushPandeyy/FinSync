import 'package:finance_tracker/pages/personalMode/goalsPage/GoalsPage.dart';
import 'package:finance_tracker/widgets/common/StandardAppBar.dart';
import 'package:flutter/material.dart';

class BusinessGoalsPage extends StatelessWidget {
  const BusinessGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      appBar: const StandardAppBar(
        title: 'Business Goals',
        subtitle: 'Milestone-based planning',
        useCustomDesign: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GoalHint(title: 'Save for equipment'),
            const SizedBox(height: 8),
            const _GoalHint(title: 'Open new branch'),
            const SizedBox(height: 8),
            const _GoalHint(title: 'Hire a team member'),
            const SizedBox(height: 8),
            const _GoalHint(title: 'Launch product'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Goals Module'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalHint extends StatelessWidget {
  final String title;

  const _GoalHint({required this.title});

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
