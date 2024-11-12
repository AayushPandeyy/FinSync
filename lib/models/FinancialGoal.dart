class FinancialGoal {
  final String id;
  final String title;
  final String description;
  final int targetAmount;
  final double currentAmount;
  final DateTime deadline;

  const FinancialGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });
}