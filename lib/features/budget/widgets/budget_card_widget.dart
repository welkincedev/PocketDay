import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';

class BudgetCardWidget extends StatelessWidget {
  final String title;
  final double budgetAmount;
  final double spentAmount;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  const BudgetCardWidget({
    super.key,
    required this.title,
    required this.budgetAmount,
    required this.spentAmount,
    this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final remaining = budgetAmount - spentAmount;
    final percent = budgetAmount > 0 ? (spentAmount / budgetAmount) : 0.0;
    final displayPercent = (percent * 100).toStringAsFixed(0);

    // Determine status & styling
    Color statusColor;
    String statusText;

    if (percent >= 1.0) {
      statusColor = AppColors.expense;
      statusText = budgetAmount > 0
          ? 'Over budget by ${CurrencyFormatter.format(spentAmount - budgetAmount)}'
          : 'Budget is ₹0';
    } else if (percent >= 0.90) {
      statusColor = Colors.orange;
      statusText =
          'Almost used up • ${CurrencyFormatter.format(remaining)} remaining';
    } else if (percent >= 0.70) {
      statusColor = Colors.amber;
      statusText =
          'Getting close • ${CurrencyFormatter.format(remaining)} remaining';
    } else {
      statusColor = AppColors.primary;
      statusText =
          'On track • ${CurrencyFormatter.format(remaining)} remaining';
    }

    // Cap visual progress at 100%
    final visualProgressValue = percent.clamp(0.0, 1.0);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? statusColor).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor ?? statusColor),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (percent >= 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Exceeded',
                    style: TextStyle(
                      color: AppColors.expense,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (percent >= 0.90)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Critical',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Limit',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(budgetAmount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(spentAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: percent >= 1.0
                          ? AppColors.expense
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Progress Bar with indicator track background
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                FractionallySizedBox(
                  widthFactor: visualProgressValue,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Footer info: percentage and descriptive warning text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: percent >= 1.0
                      ? AppColors.expense
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                ),
              ),
              Text(
                '$displayPercent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
