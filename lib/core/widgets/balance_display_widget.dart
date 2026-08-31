// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: balance_display_widget.dart
//
// Purpose:
// Overflow-safe monetary balance text renderer wrapped in a FittedBox.
//
// Responsibilities:
// - Render formatted currency text using CurrencyFormatter.
// - Scale text down dynamically (`BoxFit.scaleDown`) on small device screens to eliminate RenderFlex overflows.
//
// Data Flow:
// double amount → CurrencyFormatter.format() → FittedBox(Text)
//
// Important Rules:
// - Use BalanceDisplayWidget anywhere large currency amounts could overflow card boundaries.
//
// Main Operations:
// - BalanceDisplayWidget(amount, style, symbol)
// ============================================================

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
