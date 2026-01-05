import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/pages/homePage/TransactionsBasedOnTypePage.dart';
import 'package:flutter/material.dart';

class BalanceDisplayBox extends StatefulWidget {
  final double balance;
  final TransactionType type;
  const BalanceDisplayBox({
    super.key,
    required this.type,
    required this.balance,
  });

  @override
  State<BalanceDisplayBox> createState() => _BalanceDisplayBoxState();
}

class _BalanceDisplayBoxState extends State<BalanceDisplayBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScaleFactor = MediaQuery.textScalerOf(context);
    final width = size.width;
    final height = size.height;

    bool isExpense = widget.type == TransactionType.EXPENSE;

    // Glassmorphic gradient design
    final primaryColor =
        isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4);

    final secondaryColor =
        isExpense ? const Color(0xFFFF8E53) : const Color(0xFF44A08D);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionsBasedOnTypePage(
              type: isExpense ? "EXPENSE" : "INCOME",
            ),
          ),
        );
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: height * 0.24,
          width: width * 0.43,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.1),
                secondaryColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(_isPressed ? 0.15 : 0.08),
                blurRadius: _isPressed ? 8 : 12,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Animated background circles
                Positioned(
                  top: -width * 0.15,
                  right: -width * 0.1,
                  child: Container(
                    width: width * 0.35,
                    height: width * 0.35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withOpacity(0.15),
                          primaryColor.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -width * 0.1,
                  left: -width * 0.05,
                  child: Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          secondaryColor.withOpacity(0.1),
                          secondaryColor.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with gradient background
                      Container(
                        padding: EdgeInsets.all(width * 0.025),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isExpense
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: Colors.white,
                          size: width * 0.05,
                        ),
                      ),

                      SizedBox(height: height * 0.02),

                      // Label
                      Text(
                        isExpense ? "Expense" : "Income",
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: width * 0.032,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.linear(
                          textScaleFactor.scale(1.0).clamp(1.0, 1.3),
                        ),
                      ),

                      SizedBox(height: height * 0.008),

                      // Amount with auto-sizing
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    "Rs ${widget.balance.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: width * 0.068,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    textScaler: TextScaler.linear(
                                      textScaleFactor
                                          .scale(1.0)
                                          .clamp(1.0, 1.2),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: height * 0.008),

                      // View indicator with gradient
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            ).createShader(bounds),
                            child: Text(
                              "View all",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.028,
                                fontWeight: FontWeight.w600,
                              ),
                              textScaler: TextScaler.linear(
                                textScaleFactor.scale(1.0).clamp(1.0, 1.3),
                              ),
                            ),
                          ),
                          SizedBox(width: width * 0.01),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            ).createShader(bounds),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: width * 0.035,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
