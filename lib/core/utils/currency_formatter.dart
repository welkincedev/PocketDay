import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    String symbol = AppConstants.currencySymbol,
    bool isHidden = false,
  }) {
    if (isHidden) return '••••••';
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '$symbol ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCompact(
    double amount, {
    String symbol = AppConstants.currencySymbol,
    bool isHidden = false,
  }) {
    if (isHidden) return '••••';
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '$symbol ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
