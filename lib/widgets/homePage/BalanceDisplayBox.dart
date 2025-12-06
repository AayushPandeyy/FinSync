import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/pages/TransactionsBasedOnTypePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BalanceDisplayBox extends StatelessWidget {
  final double balance;
  final TransactionType type;
  const BalanceDisplayBox({
    super.key,
    required this.type,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    
    bool isExpense = type == TransactionType.EXPENSE;
    
    // Color schemes
    final primaryColor = isExpense
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF51CF66);
    final lightColor = isExpense
        ? const Color(0xFFFFE5E5)
        : const Color(0xFFE7F5E7);
    final gradientColors = isExpense
        ? [const Color(0xFFFF6B6B), const Color(0xFFFF8787), const Color(0xFFFFABAB)]
        : [const Color(0xFF51CF66), const Color(0xFF69DB7C), const Color(0xFF8CE99A)];

    return GestureDetector(
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
      child: Container(
        height: height * 0.23,
        width: width * 0.43,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, lightColor.withOpacity(0.3)],
          ),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle top right
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            
            // Decorative circle bottom left
            Positioned(
              bottom: -15,
              left: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.08),
                      primaryColor.withOpacity(0.03),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main content
            Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon with gradient background
                  Container(
                    width: width * 0.15,
                    height: width * 0.15,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.south_rounded
                          : Icons.north_rounded,
                      color: Colors.white,
                      size: width * 0.08,
                    ),
                  ),
                  
                  SizedBox(height: height * 0.015),
                  
                  // Label
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03,
                      vertical: height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isExpense ? "Expense" : "Income",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: height * 0.01),
                  
                  // Amount
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Rs ${balance.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: width * 0.072,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2D3436),
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: height * 0.008),
                  
                  // Tap indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "View all",
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.7),
                          fontSize: width * 0.028,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: width * 0.01),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: primaryColor.withOpacity(0.7),
                        size: width * 0.035,
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