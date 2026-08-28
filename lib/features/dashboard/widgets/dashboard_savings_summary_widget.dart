import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../goals/providers/savings_goals_provider.dart';
import '../providers/navigation_provider.dart';

class DashboardSavingsSummaryWidget extends ConsumerWidget {
  const DashboardSavingsSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(savingsGoalsProvider);

    if (state.isLoading || state.goals.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeGoals = state.goals.where((g) => !g.isCompleted).toList();

    double totalSaved = 0.0;
    double totalTarget = 0.0;
    for (var goal in state.goals) {
      totalSaved += goal.savedAmount;
      totalTarget += goal.targetAmount;
    }

    final overallPercent = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
    final overallPercentText = (overallPercent * 100).toStringAsFixed(0);

    return AppCard(
      onTap: () {
        // Navigate to Savings Goals tab (index 3)
        ref.read(navigationProvider.notifier).state = 3;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Goals',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${activeGoals.length} active',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(totalSaved)} saved of ${CurrencyFormatter.format(totalTarget)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                '$overallPercentText% saved',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: overallPercent,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
