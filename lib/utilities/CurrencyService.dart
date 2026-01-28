import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _currencyCodeKey = 'currency_code';
  static const String _defaultCurrencySymbol = 'Rs';
  static const String _defaultCurrencyCode = 'NPR';

  // In-memory cache for currency symbol (loaded once, reused)
  static String? _cachedSymbol;
  static bool _isLoading = false;

  // Currency code to symbol mapping
  static final Map<String, String> _currencyMap = {
    'NPR': 'Rs',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  /// Get currency symbol from SharedPreferences or return default
  /// Caches the result in memory for faster subsequent access
  static Future<String> getCurrencySymbol() async {
    // Return cached value if available
    if (_cachedSymbol != null) {
      return _cachedSymbol!;
    }

    // Prevent multiple simultaneous loads
    if (_isLoading) {
      // Wait a bit and retry
      await Future.delayed(const Duration(milliseconds: 100));
      if (_cachedSymbol != null) {
        return _cachedSymbol!;
      }
    }

    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedSymbol = prefs.getString(_currencySymbolKey) ?? _defaultCurrencySymbol;
      return _cachedSymbol!;
    } catch (e) {
      _cachedSymbol = _defaultCurrencySymbol;
      return _cachedSymbol!;
    } finally {
      _isLoading = false;
    }
  }

  /// Get currency code from SharedPreferences or return default
  static Future<String> getCurrencyCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currencyCodeKey) ?? _defaultCurrencyCode;
    } catch (e) {
      return _defaultCurrencyCode;
    }
  }

  /// Set currency symbol and code in SharedPreferences based on currency code
  /// Also updates the in-memory cache
  static Future<void> setCurrencyFromCode(String currencyCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final symbol = _currencyMap[currencyCode] ?? _defaultCurrencySymbol;
      await prefs.setString(_currencySymbolKey, symbol);
      await prefs.setString(_currencyCodeKey, currencyCode);

      
      // Update cache
      _cachedSymbol = symbol;
    } catch (e) {
      print('Error saving currency: $e');
    }
  }

  /// Set currency symbol directly (for backward compatibility)
  static Future<void> setCurrencySymbol(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencySymbolKey, symbol);
    } catch (e) {
      print('Error saving currency symbol: $e');
    }
  }

  /// Get currency symbol synchronously (returns cached value or default)
  /// Use this for immediate access. Make sure to call getCurrencySymbol() first
  /// to load and cache the value from SharedPreferences
  static String getCurrencySymbolSync() {
    return _cachedSymbol ?? _defaultCurrencySymbol;
  }

  /// Initialize currency symbol by loading from SharedPreferences
  /// Call this once at app startup or when user logs in
  static Future<void> initializeCurrency() async {
    if (_cachedSymbol == null) {
      await getCurrencySymbol();
    }
  }

  /// Clear stored currency (useful for logout)
  static Future<void> clearCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currencySymbolKey);
      await prefs.remove(_currencyCodeKey);
      // Clear cache
      _cachedSymbol = null;
    } catch (e) {
      print('Error clearing currency: $e');
    }
  }
}
