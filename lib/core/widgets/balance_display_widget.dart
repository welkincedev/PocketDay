import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import '../constants/app_constants.dart';

/// A display widget for rendering currency amounts in a consistent,
/// overflow-safe way. Wraps the formatted value in a [FittedBox] so
/// it scales down on narrow screens instead of overflowing.
class BalanceDisplayWidget extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String symbol;

  const BalanceDisplayWidget({
    super.key,
    required this.amount,
    this.style,
    this.symbol = AppConstants.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle =
        style ??
        Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        CurrencyFormatter.format(amount, symbol: symbol),
        style: textStyle,
      ),
    );
  }
}
