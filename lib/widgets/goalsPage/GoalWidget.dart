import 'package:finance_tracker/models/FinancialGoal.dart';
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
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(_expandAnimation);
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

  @override
  Widget build(BuildContext context) {
    final progress = (widget.goal.currentAmount / widget.goal.targetAmount) > 1
        ? 1.0
        : widget.goal.currentAmount / widget.goal.targetAmount;
    final daysLeft = widget.goal.deadline.difference(DateTime.now()).inDays;
    final progressColor = _getProgressColor(progress);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getGoalIcon(progress),
                      color: progressColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.goal.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toStringAsFixed(1)}% Complete',
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      widget.goal.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Target Amount',
                      NumberFormat.currency(symbol: 'Rs ')
                          .format(widget.goal.targetAmount),
                      Icons.flag,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Current Amount',
                      NumberFormat.currency(symbol: 'Rs ')
                          .format(widget.goal.currentAmount),
                      Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Time Remaining',
                      '$daysLeft days left',
                      Icons.timer,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Deadline',
                      DateFormat('MMM dd, yyyy').format(widget.goal.deadline),
                      Icons.event,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    if (progress < 1) return Colors.blue;
    return Colors.green;
  }

  IconData _getGoalIcon(double progress) {
    if (progress < 0.3) return Icons.sentiment_dissatisfied;
    if (progress < 0.7) return Icons.sentiment_neutral;
    if (progress < 1) return Icons.sentiment_satisfied;
    return Icons.celebration;
  }
}
