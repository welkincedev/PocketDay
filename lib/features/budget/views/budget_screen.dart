import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state_widget.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navBudget),
      ),
      body: const EmptyStateWidget(
        icon: Icons.pie_chart_rounded,
        title: 'Monthly Budget Planning',
        description: 'Category budget management and spending alerts will be configured in Phase 5.',
      ),
    );
  }
}
