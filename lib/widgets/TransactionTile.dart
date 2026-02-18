import 'package:finance_tracker/utilities/Categories.dart';
import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final DateTime date;
  final double amount;
  final String type;
  final String category;
  final String wallet;

  const TransactionTile({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    bool isExpense = type == 'EXPENSE';

    IconData categoryIcon = Icons.shopping_bag;
    try {
      final categoryItem = Categories().categories.firstWhere(
            (cat) => cat.name == category,
            orElse: () => Categories().categories.first,
          );
      categoryIcon = categoryItem.icon;
    } catch (e) {
      categoryIcon = Icons.help_outline;
    }

    final textColor =
        isExpense ? const Color(0xFFE63946) : const Color(0xFF06D6A0);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.01,
      ),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: textColor.withOpacity(0.3),
            width: 2,
          ),
          bottom: BorderSide(
            color: textColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            categoryIcon,
            color: textColor.withOpacity(0.7),
            size: width * 0.06,
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
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: width * 0.008),
                Text(
                  DateFormat("d MMM yyyy").format(date),
                  style: TextStyle(
                    fontSize: width * 0.032,
                    color: const Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Amount + category + wallet badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FutureBuilder<String>(
                future: CurrencyService.getCurrencySymbol(),
                builder: (context, snapshot) {
                  final symbol = snapshot.data ?? 'Rs';
                  return Text(
                    "${isExpense ? '−' : '+'} $symbol ${amount.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: textColor,
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              SizedBox(height: width * 0.008),
              Text(
                category,
                style: TextStyle(
                  fontSize: width * 0.028,
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: width * 0.01),
              // 👇 Wallet badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.022,
                  vertical: width * 0.008,
                ),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: textColor.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: width * 0.028,
                      color: textColor.withOpacity(0.7),
                    ),
                    SizedBox(width: width * 0.012),
                    Text(
                      wallet,
                      style: TextStyle(
                        fontSize: width * 0.026,
                        color: textColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
