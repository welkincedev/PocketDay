import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/goal_model.dart';

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

    String? dateText;
    if (goal.targetDate != null) {
      final now = DateTime.now();
      final difference = goal.targetDate!.difference(now);
      if (difference.isNegative) {
        dateText = 'Target passed';
      } else {
        final months = (difference.inDays / 30).round();
        if (months <= 0) {
          dateText = '${difference.inDays} days left';
        } else {
          dateText = '$months months left';
        }
      }
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Emoji Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: stateColor.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stateColor.withAlpha(40),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  goal.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),

              // Goal name and target date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${DateFormat('MMM yyyy').format(goal.targetDate!)} • $dateText',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Percentage status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percentVal.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: stateColor,
                    ),
                  ),
                  if (isCompleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: stateColor),
                        const SizedBox(width: 2),
                        Text(
                          'Reached',
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
          const SizedBox(height: 16),

          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progressVal,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(stateColor),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(currentAmount)} of ${CurrencyFormatter.format(goal.targetAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                isCompleted
                    ? 'Goal achieved!'
                    : '${CurrencyFormatter.format(remainingAmount)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? stateColor
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
