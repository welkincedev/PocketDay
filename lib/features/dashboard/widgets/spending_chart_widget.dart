import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/dashboard_provider.dart';
import '../../budget/providers/budget_provider.dart';

class SpendingChartWidget extends ConsumerWidget {
  final double income;
  final double expense;

  const SpendingChartWidget({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardState = ref.watch(dashboardProvider);
    final budgetState = ref.watch(budgetProvider);

    final limit = dashboardState.monthlyBudget;
    final spent = dashboardState.currentMonthExpense;
    final budgetUsedPercentage = limit > 0
        ? ((spent / limit) * 100).round()
        : 0;

    final categorySpending = budgetState.categorySpending;
    // We only care about category keys (strings, excluding null which is overall spending)
    final activeCategories = categorySpending.entries
        .where((e) => e.key != null && e.value > 0)
        .toList();

    List<PieChartSectionData> sections = [];

    if (activeCategories.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          value: 1.0,
          radius: 28,
          showTitle: false,
        ),
      );
    } else {
      for (var entry in activeCategories) {
        final categoryId = entry.key!;
        final amount = entry.value;
        final categoryMeta = AppConstants.defaultCategories.firstWhere(
          (cat) => cat['id'] == categoryId,
          orElse: () => {'color': AppColors.primary},
        );
        final color = categoryMeta['color'] as Color;

        sections.add(
          PieChartSectionData(
            color: color,
            value: amount,
            radius: 28,
            showTitle: false,
          ),
        );
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Analytics',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(
                Icons.pie_chart_outline_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Donut Chart with Centered Indicator
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius:
                          52, // Expanded inner radius to make room for indicator
                      sections: sections,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$budgetUsedPercentage%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Budget Used',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category Legend below the chart detailing categories using ₹ formatting
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: activeCategories.isEmpty
                ? Text(
                    'No expenses logged for this month yet.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: activeCategories.map((entry) {
                      final categoryId = entry.key!;
                      final amount = entry.value;
                      final categoryMeta = AppConstants.defaultCategories
                          .firstWhere(
                            (cat) => cat['id'] == categoryId,
                            orElse: () => {
                              'name': categoryId,
                              'icon': Icons.category_rounded,
                              'color': AppColors.primary,
                            },
                          );
                      final name = categoryMeta['name'] as String;
                      final color = categoryMeta['color'] as Color;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$name: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(amount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
