import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../budget/providers/budget_provider.dart';

class CategoryBudgetProgressWidget extends ConsumerWidget {
  const CategoryBudgetProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetState = ref.watch(budgetProvider);

    final categoryBudgets = budgetState.currentBudgets.where((b) => b.categoryId != null).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Budget Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 18,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categoryBudgets.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No category budgets configured for ${DateFormat('MMMM yyyy').format(budgetState.selectedMonth)}. Go to the Budgets tab to set limit scopes.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ] else ...[
            ...categoryBudgets.map((budget) {
              final spent = budgetState.categorySpending[budget.categoryId] ?? 0.0;
              final progress = budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;

              final catMeta = AppConstants.defaultCategories.firstWhere(
                (c) => c['id'] == budget.categoryId,
                orElse: () => {
                  'name': budget.categoryName ?? 'Other',
                  'color': AppColors.primary,
                  'icon': Icons.category_rounded,
                },
              );

              final color = catMeta['color'] as Color;
              final icon = catMeta['icon'] as IconData;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 16, color: color),
                            const SizedBox(width: 8),
                            Text(
                              catMeta['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${spent.toInt()} / ₹${budget.amount.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: spent > budget.amount
                                ? AppColors.expense
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          spent > budget.amount ? AppColors.expense : color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
