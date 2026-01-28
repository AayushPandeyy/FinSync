import 'package:finance_tracker/utilities/CurrencyService.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format amount with currency symbol from SharedPreferences
  /// Returns formatted string like "Rs 1,000" or "$ 1,000"
  static Future<String> formatAmount(double amount) async {
    final symbol = await CurrencyService.getCurrencySymbol();
    return NumberFormat.currency(symbol: '$symbol ').format(amount);
  }

  /// Format amount with currency symbol (simple string concatenation)
  /// Returns formatted string like "Rs 1000" or "$ 1000"
  static Future<String> formatAmountSimple(double amount) async {
    final symbol = await CurrencyService.getCurrencySymbol();
    return '$symbol ${amount.toStringAsFixed(0)}';
  }

  /// Format amount with currency symbol (with decimal places)
  /// Returns formatted string like "Rs 1,000.50" or "$ 1,000.50"
  static Future<String> formatAmountWithDecimals(double amount, {int decimals = 2}) async {
    final symbol = await CurrencyService.getCurrencySymbol();
    return '$symbol ${amount.toStringAsFixed(decimals)}';
  }

  /// Get currency symbol asynchronously
  static Future<String> getSymbol() async {
    return await CurrencyService.getCurrencySymbol();
  }

  /// Format amount with currency symbol synchronously (uses default if not loaded)
  /// This is a fallback - prefer async versions
  static String formatAmountSync(double amount) {
    final symbol = CurrencyService.getCurrencySymbolSync();
    return '$symbol ${amount.toStringAsFixed(0)}';
  }
}
