// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: currency_formatter.dart
//
// Purpose:
// Centralized Indian Rupee (₹ en_IN) monetary currency formatter.
//
// Responsibilities:
// - Format standard currency amounts with symbol and 2 decimal places (e.g., `₹ 14,000.00`).
// - Format compact currency amounts for charts and cards (e.g., `₹ 14K`).
//
// Data Flow:
// Numeric amount (double) → CurrencyFormatter.format() → UI Text Widget
//
// Important Rules:
// - Never hardcode raw string concatenation like `'₹' + amount.toString()`; always use CurrencyFormatter.
//
// Main Operations:
// - format(amount): Standard Indian Rupee string formatting
// - formatCompact(amount): Abbreviated formatting for charts
// ============================================================

import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility class for formatting currency values consistently across PocketDay.
///
/// All monetary amounts displayed in the UI should go through this formatter
/// so that locale, symbol, and decimal rules stay consistent in one place.
///
/// Uses Indian locale (en_IN) with the ₹ symbol by default.
class CurrencyFormatter {
  /// Returns a full currency string — e.g. `₹ 14,000.00`.
  static String format(
    double amount, {
    String symbol = AppConstants.currencySymbol,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '$symbol ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Returns a compact/abbreviated currency string — e.g. `₹ 14K`.
  /// Useful in space-constrained UI like chart labels.
  static String formatCompact(
    double amount, {
    String symbol = AppConstants.currencySymbol,
  }) {
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '$symbol ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
