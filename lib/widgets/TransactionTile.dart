import 'package:finance_tracker/utilities/Categories.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final DateTime date;
  final double amount;
  final String type;
  final String category;

  const TransactionTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    
    bool isExpense = type == 'EXPENSE';

    // Fetch icon for category
    IconData categoryIcon = Icons.shopping_bag; // Default fallback
    try {
      categoryIcon = Categories().categories.firstWhere(
        (cat) => cat['name'] == category,
        orElse: () => {'icon': Icons.help_outline}
      )['icon'];
    } catch (e) {
      categoryIcon = Icons.help_outline;
    }

    // Color scheme based on transaction type
    final primaryColor = isExpense
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF4ECDC4);
    final lightColor = isExpense
        ? const Color(0xFFFFE5E5)
        : const Color(0xFFE0F7F6);
    final gradientColors = isExpense
        ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
        : [const Color(0xFF4ECDC4), const Color(0xFF44B3AB)];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.015,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            lightColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle gradient accent on the side
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            
            // Main content
            Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Row(
                children: [
                  // Icon container with gradient
                  Container(
                    width: width * 0.14,
                    height: width * 0.14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      categoryIcon,
                      color: Colors.white,
                      size: width * 0.07,
                    ),
                  ),
                  
                  SizedBox(width: width * 0.04),
                  
                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D3436),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: width * 0.01),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: width * 0.035,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(width: width * 0.015),
                            Text(
                              DateFormat("EEE, d MMM").format(date),
                              style: TextStyle(
                                fontSize: width * 0.035,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: width * 0.02),
                  
                  // Amount container
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03,
                          vertical: width * 0.015,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.15),
                              primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpense
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: primaryColor,
                              size: width * 0.04,
                            ),
                            SizedBox(width: width * 0.01),
                            Text(
                              "Rs $amount",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: width * 0.042,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: width * 0.015),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.025,
                          vertical: width * 0.008,
                        ),
                        decoration: BoxDecoration(
                          color: lightColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: width * 0.028,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }
}

