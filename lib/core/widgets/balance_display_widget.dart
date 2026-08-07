import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import '../constants/app_constants.dart';

class BalanceDisplayWidget extends StatelessWidget {
  final double amount;
  final bool isHidden;
  final TextStyle? style;
  final String symbol;

  const BalanceDisplayWidget({
    super.key,
    required this.amount,
    required this.isHidden,
    this.style,
    this.symbol = AppConstants.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = style ??
        Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: isHidden ? 2.0 : -0.5,
            );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          CurrencyFormatter.format(amount, symbol: symbol, isHidden: isHidden),
          key: ValueKey<bool>(isHidden),
          style: textStyle,
        ),
      ),
    );
  }
}
