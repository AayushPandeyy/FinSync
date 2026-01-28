import 'package:finance_tracker/models/FinancialGoal.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinancialGoalWidget extends StatefulWidget {
  final FinancialGoal goal;

  const FinancialGoalWidget({
    super.key,
    required this.goal,
  });

  @override
  State<FinancialGoalWidget> createState() => _FinancialGoalWidgetState();
}

class _FinancialGoalWidgetState extends State<FinancialGoalWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  String _currencySymbol = 'Rs';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return const Color(0xFF06D6A0); // Green - Complete
    if (progress >= 0.75) return const Color(0xFF4A90E2); // Blue - Almost there
    if (progress >= 0.5) return const Color(0xFFFFA500); // Orange - Halfway
    return const Color(0xFFE63946); // Red - Just started
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.goal.currentAmount / widget.goal.targetAmount).clamp(0.0, 1.0);
    final daysLeft = widget.goal.deadline.difference(DateTime.now()).inDays;
    final remaining = widget.goal.targetAmount - widget.goal.currentAmount;
    final progressColor = _getProgressColor(progress);

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(
              color: progressColor.withOpacity(0.3),
              width: 4,
            ),
            bottom: BorderSide(
              color: progressColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.goal.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% • ${daysLeft > 0 ? '$daysLeft days left' : 'Overdue'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress indicator circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: progressColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: progressColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_currencySymbol ${widget.goal.currentAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_currencySymbol ${widget.goal.targetAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            
            // Expanded Details
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Divider
                  Container(
                    height: 1,
                    color: const Color(0xFFF0F0F0),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Description
                  if (widget.goal.description.isNotEmpty) ...[
                    Text(
                      widget.goal.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Stats Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          'Remaining',
                          '$_currencySymbol ${remaining > 0 ? remaining.toStringAsFixed(0) : '0'}',
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'Deadline',
                          DateFormat('MMM dd, yyyy').format(widget.goal.deadline),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'Daily Target',
                          daysLeft > 0 
                              ? '$_currencySymbol ${(remaining / daysLeft).toStringAsFixed(0)}/day'
                              : 'Goal ended',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }
}