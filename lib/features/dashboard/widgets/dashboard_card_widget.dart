import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/balance_display_widget.dart';
import '../../../core/utils/currency_formatter.dart';

/// The hero balance card shown at the top of the Dashboard.
///
/// Displays the user's total balance (income − expenses for the current month)
/// with an income/expense breakdown beneath a divider. The gradient adapts to
/// the active theme.
class DashboardCardWidget extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final double budgetRemaining;

  const DashboardCardWidget({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.budgetRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF059669), const Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balance label
          Text(
            AppStrings.totalBalance.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white.withAlpha(180),
            ),
          ),
          const SizedBox(height: 6),

          // Balance amount
          BalanceDisplayWidget(
            amount: balance,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'monospace',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: Colors.white.withAlpha(30)),
          const SizedBox(height: 16),

          // Income / Expense breakdown
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: AppStrings.monthlyIncome,
                  value: CurrencyFormatter.formatCompact(income),
                  icon: Icons.arrow_downward_rounded,
                  accentColor: const Color(0xFFA7F3D0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: AppStrings.monthlyExpense,
                  value: CurrencyFormatter.formatCompact(expense),
                  icon: Icons.arrow_upward_rounded,
                  accentColor: const Color(0xFFFCA5A5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(220),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
