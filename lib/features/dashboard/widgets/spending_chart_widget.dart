import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';

class SpendingChartWidget extends StatelessWidget {
  final double income;
  final double expense;

  const SpendingChartWidget({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final total = (income + expense) > 0 ? (income + expense) : 1.0;
    final incomePercentage = ((income / total) * 100).round();
    final expensePercentage = ((expense / total) * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending & Income Overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.income,
                          value: income > 0 ? income : 1,
                          title: '$incomePercentage%',
                          radius: 32,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppColors.expense,
                          value: expense > 0 ? expense : 1,
                          title: '$expensePercentage%',
                          radius: 32,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChartLegend(
                        context: context,
                        color: AppColors.income,
                        label: 'Income',
                        value: '\$${income.toStringAsFixed(0)}',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildChartLegend(
                        context: context,
                        color: AppColors.expense,
                        label: 'Expense',
                        value: '\$${expense.toStringAsFixed(0)}',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend({
    required BuildContext context,
    required Color color,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
