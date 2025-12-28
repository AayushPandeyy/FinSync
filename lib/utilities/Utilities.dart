import 'dart:ui';

class Utilities {
  Color getProgressColor(double spent, double budget) {
    final percentage = (spent / budget);
    if (percentage >= 1.0) return const Color(0xFFE63946);
    if (percentage >= 0.8) return const Color(0xFFFFA500);
    if (percentage >= 0.5) return const Color(0xFF4A90E2);
    return const Color(0xFF06D6A0);
  }
}