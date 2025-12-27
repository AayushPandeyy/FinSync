import 'package:finance_tracker/enums/TransactionType.dart';
import 'package:finance_tracker/pages/homePage/TransactionsBasedOnTypePage.dart';
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
    
    // Minimalistic colors
    final textColor = isExpense
        ? const Color(0xFFE63946)
        : const Color(0xFF06D6A0);

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
        height: height * 0.20,
        width: width * 0.43,
        padding: EdgeInsets.all(width * 0.05),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Icon(
              isExpense
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: textColor.withOpacity(0.7),
              size: width * 0.07,
            ),
            
            SizedBox(height: height * 0.015),
            
            // Label
            Text(
              isExpense ? "Expense" : "Income",
              style: TextStyle(
                color: const Color(0xFF666666),
                fontSize: width * 0.032,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: height * 0.005),
            
            // Amount
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                "Rs ${balance.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: width * 0.065,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            
            const Spacer(),
            
            // View indicator
            Text(
              "View all →",
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: width * 0.028,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}