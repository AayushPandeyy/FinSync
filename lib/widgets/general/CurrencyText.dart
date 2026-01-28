import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:flutter/material.dart';

/// A widget that displays an amount with the user's preferred currency symbol
/// Loads currency symbol from SharedPreferences (cached after first load)
class CurrencyText extends StatelessWidget {
  final double amount;
  final int? decimals;
  final TextStyle? style;
  final bool useFormatting; // If true, uses NumberFormat, else simple string

  const CurrencyText({
    super.key,
    required this.amount,
    this.decimals,
    this.style,
    this.useFormatting = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: CurrencyService.getCurrencySymbol(),
      builder: (context, snapshot) {
        final symbol = snapshot.data ?? 'Rs';
        final formattedAmount = decimals != null
            ? amount.toStringAsFixed(decimals!)
            : amount.toStringAsFixed(0);
        return Text(
          "$symbol $formattedAmount",
          style: style,
        );
      },
    );
  }
}
