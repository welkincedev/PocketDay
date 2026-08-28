import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/savings_goal_model.dart';
import '../providers/savings_goals_provider.dart';
import 'add_savings_bottom_sheet.dart';
import 'add_savings_goal_bottom_sheet.dart';

class SavingsGoalDetailBottomSheet extends ConsumerWidget {
  final SavingsGoalModel goal;

  const SavingsGoalDetailBottomSheet({
    super.key,
    required this.goal,
  });

  void _openAddSavingsSheet(BuildContext context) {
    Navigator.pop(context); // Close details sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSavingsBottomSheet(goal: goal),
    );
  }

  void _openEditGoalSheet(BuildContext context) {
    Navigator.pop(context); // Close details sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSavingsGoalBottomSheet(goalToEdit: goal),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
          title: const Text('Delete Savings Goal?'),
          content: const Text(
            'Are you sure you want to delete this savings goal? Your regular transactions will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(savingsGoalsProvider.notifier).deleteGoal(goal.id);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail sheet
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.expense),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressVal = goal.progress;
    final percentVal = goal.percentage;
    final isCompleted = goal.isCompleted;

    final stateColor = isCompleted
        ? AppColors.primary
        : (progressVal >= 0.8 ? Colors.orange : AppColors.primary);

    String? dateText;
    String? neededMonthlyText;
    if (goal.targetDate != null) {
      final now = DateTime.now();
      final difference = goal.targetDate!.difference(now);
      if (difference.isNegative) {
        dateText = 'Target date passed';
      } else {
        final days = difference.inDays;
        final months = (days / 30).ceil();
        dateText = months <= 0 ? '$days days remaining' : '$months months remaining';

        if (months > 0 && goal.remainingAmount > 0) {
          final monthlyAmount = goal.remainingAmount / months;
          neededMonthlyText = '${CurrencyFormatter.format(monthlyAmount)}/month needed';
        }
      }
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Emoji + Title
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: stateColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    goal.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: stateColor),
                            const SizedBox(width: 4),
                            Text(
                              'Goal reached!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: stateColor,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text(
                          'In progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Summary Block
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCompleted ? 'Target Achieved' : 'Progress Rate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '${percentVal.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: stateColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: progressVal,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(stateColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(goal.savedAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Target',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(goal.targetAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date Calculations block (if exists)
            if (goal.targetDate != null) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.alarm_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target: ${DateFormat('MMMM yyyy').format(goal.targetDate!)} ($dateText)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (neededMonthlyText != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              neededMonthlyText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Add Savings action button
            if (!isCompleted) ...[
              AppButton(
                text: '+ Add Savings',
                onPressed: () => _openAddSavingsSheet(context),
              ),
              const SizedBox(height: 12),
            ],

            // Bottom controls actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Edit Goal',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _openEditGoalSheet(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Delete Goal',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
