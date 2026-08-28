import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';

class DashboardBudgetProgressWidget extends ConsumerWidget {
  const DashboardBudgetProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(dashboardProvider);

    if (state.isLoading) {
      return const SizedBox.shrink();
    }

    final limit = state.monthlyBudget;
    final spent = state.currentMonthExpense;
    final remaining = limit - spent;
    final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final percentText = (percent * 100).toStringAsFixed(0);

    // Determine color based on threshold
    Color statusColor;
    if (spent > limit) {
      statusColor = AppColors.expense;
    } else if (percent >= 0.90) {
      statusColor = Colors.orange;
    } else if (percent >= 0.70) {
      statusColor = Colors.amber;
    } else {
      statusColor = AppColors.primary;
    }

    return AppCard(
      onTap: () {
        // Navigate to Budget tab (index 2)
        ref.read(navigationProvider.notifier).state = 2;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget Progress',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$percentText% used',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(spent)} spent of ${CurrencyFormatter.format(limit)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                spent > limit
                    ? '${CurrencyFormatter.format(spent - limit)} over'
                    : '${CurrencyFormatter.format(remaining)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: spent > limit ? AppColors.expense : statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(
                    height: 6,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
