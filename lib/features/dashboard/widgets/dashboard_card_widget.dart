import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/balance_display_widget.dart';

class DashboardCardWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final hideBalance = ref.watch(hideBalanceProvider);
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
          // Total Balance Header & Visibility Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalBalance.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.white.withAlpha(200),
                ),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: Icon(
                  hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(hideBalanceProvider.notifier).toggle();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Total Balance Amount (FittedBox prevents any text overflow)
          BalanceDisplayWidget(
            amount: balance,
            isHidden: hideBalance,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Subtle Divider
          Container(
            height: 1,
            color: Colors.white.withAlpha(30),
          ),
          const SizedBox(height: 16),

          // Metrics Container Row (Income, Expense, Remaining Budget)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: AppStrings.monthlyIncome,
                  amount: income,
                  icon: Icons.arrow_downward_rounded,
                  accentColor: const Color(0xFFA7F3D0), // Light Emerald
                  isHidden: hideBalance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: AppStrings.monthlyExpense,
                  amount: expense,
                  icon: Icons.arrow_upward_rounded,
                  accentColor: const Color(0xFFFCA5A5), // Light Red
                  isHidden: hideBalance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: AppStrings.remainingBudget,
                  amount: budgetRemaining,
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: const Color(0xFFBAE6FD), // Light Blue
                  isHidden: hideBalance,
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
    required double amount,
    required IconData icon,
    required Color accentColor,
    required bool isHidden,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha(220),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          BalanceDisplayWidget(
            amount: amount,
            isHidden: isHidden,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
