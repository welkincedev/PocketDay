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
          // Top Row: Section title on the left, remaining balance on the right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Monthly Budget',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  spent > limit
                      ? '${CurrencyFormatter.format(spent - limit)} Over'
                      : '${CurrencyFormatter.format(remaining)} Left',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: spent > limit ? AppColors.expense : statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Middle Row: Full-width LinearProgressIndicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom Row: Spent amount on the left, budget limit target on the right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${CurrencyFormatter.format(spent)} spent',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Target: ${CurrencyFormatter.format(limit)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
