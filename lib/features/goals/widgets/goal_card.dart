import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/goal_model.dart';

/// A card representing a single Goal in the Goals list.
///
/// Displays the goal emoji, name, optional target-date countdown,
/// progress bar, and key financial metrics in a layout that is safe
/// on screens as narrow as 360 px.
///
/// All monetary values are derived from [currentAmount], which is
/// calculated by [GoalsProvider] from linked transactions — this widget
/// only renders, never computes.
class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final double currentAmount;
  final VoidCallback onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.currentAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingAmount = goal.calculateRemainingAmount(currentAmount);
    final progressVal = goal.calculateProgress(currentAmount);
    final percentVal = goal.calculatePercentage(currentAmount);
    final isCompleted = goal.isGoalCompleted(currentAmount);

    final stateColor = isCompleted
        ? AppColors.primary
        : (progressVal >= 0.8 ? Colors.orange : AppColors.primary);

    // Build date line
    String? dateText;
    if (goal.targetDate != null) {
      final now = DateTime.now();
      final difference = goal.targetDate!.difference(now);
      final monthLabel = DateFormat('MMM yyyy').format(goal.targetDate!);
      if (difference.isNegative) {
        dateText = '$monthLabel · past due';
      } else {
        final months = (difference.inDays / 30).round();
        final timeLeft = months <= 0
            ? '${difference.inDays}d left'
            : '${months}mo left';
        dateText = '$monthLabel · $timeLeft';
      }
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Title Row ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Emoji icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: stateColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(goal.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),

              // Name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Percentage badge
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentVal.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: stateColor,
                    ),
                  ),
                  if (isCompleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 11,
                          color: stateColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stateColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Progress Bar ───────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: progressVal,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(stateColor),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ─── Amounts (stacked, not side-by-side) ───────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(currentAmount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'of ${CurrencyFormatter.format(goal.targetAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                Text(
                  '${CurrencyFormatter.format(remainingAmount)} left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Goal achieved!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: stateColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
