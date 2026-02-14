import 'dart:math';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:finance_tracker/utilities/Utilities.dart';
import 'package:flutter/material.dart';

class BudgetCard extends StatefulWidget {
  final String title;
  final double? budget;
  final double spent;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final Color accentColor;

  const BudgetCard({
    Key? key,
    required this.title,
    required this.spent,
    required this.subtitle,
    required this.onTap,
    this.budget,
    this.icon = Icons.account_balance_wallet_rounded,
    this.accentColor = const Color(0xFF4A90E2),
  }) : super(key: key);

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  String _currencySymbol = 'Rs';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
  }

  Future<void> _loadCurrencySymbol() async {
    final symbol = await CurrencyService.getCurrencySymbol();
    if (mounted) setState(() => _currencySymbol = symbol);
  }

  @override
  Widget build(BuildContext context) {
    // CASE 1: Budget is not set
    if (widget.budget == null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // CTA
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        color: widget.accentColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Set',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.accentColor,
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

    // CASE 2: Budget is set
    final progress = (widget.spent / widget.budget!).clamp(0.0, 1.0);
    final remaining = widget.budget! - widget.spent;
    final isOverLimit = widget.spent > widget.budget!;
    final exceededBy = widget.spent - widget.budget!;
    final progressColor =
        Utilities().getProgressColor(widget.spent, widget.budget!);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isOverLimit
              ? Border.all(
                  color: const Color(0xFFDC2626).withOpacity(0.18),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isOverLimit
                  ? const Color(0xFFDC2626).withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: icon + title + ring
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Circular progress ring
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CustomPaint(
                          painter: _CircularProgressPainter(
                            progress: progress,
                            progressColor: progressColor,
                            trackColor: progressColor.withOpacity(0.12),
                            strokeWidth: 5,
                          ),
                        ),
                      ),
                      if (isOverLimit)
                        const Icon(
                          Icons.priority_high_rounded,
                          color: Color(0xFFDC2626),
                          size: 22,
                        )
                      else
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: progressColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress bar
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  'Spent',
                  '$_currencySymbol ${widget.spent.toStringAsFixed(0)}',
                  progressColor,
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey[200],
                ),
                _buildStatItem(
                  'Remaining',
                  '$_currencySymbol ${remaining > 0 ? remaining.toStringAsFixed(0) : '0'}',
                  remaining > 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.grey[200],
                ),
                _buildStatItem(
                  'Budget',
                  '$_currencySymbol ${widget.budget!.toStringAsFixed(0)}',
                  Colors.grey[700]!,
                ),
              ],
            ),

            // Over limit banner
            if (isOverLimit) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Over Budget!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Exceeded by $_currencySymbol ${exceededBy.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFDC2626).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Circular Progress Painter ────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
