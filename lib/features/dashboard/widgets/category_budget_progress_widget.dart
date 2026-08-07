import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';

class CategoryBudgetProgressWidget extends StatelessWidget {
  const CategoryBudgetProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {
        'name': 'Food & Dining',
        'spent': 4250.0,
        'budget': 8000.0,
        'color': const Color(0xFFF59E0B),
        'icon': Icons.restaurant_rounded,
      },
      {
        'name': 'Shopping',
        'spent': 2100.0,
        'budget': 5000.0,
        'color': const Color(0xFFEC4899),
        'icon': Icons.shopping_bag_rounded,
      },
      {
        'name': 'Transportation',
        'spent': 1200.0,
        'budget': 3000.0,
        'color': const Color(0xFF3B82F6),
        'icon': Icons.directions_bus_rounded,
      },
      {
        'name': 'Bills & Utilities',
        'spent': 3400.0,
        'budget': 6000.0,
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.receipt_long_rounded,
      },
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Budget Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((cat) {
            final spent = cat['spent'] as double;
            final budget = cat['budget'] as double;
            final progress = (spent / budget).clamp(0.0, 1.0);
            final color = cat['color'] as Color;
            final icon = cat['icon'] as IconData;

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
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${spent.toInt()} / ₹${budget.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
