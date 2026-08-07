import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state_widget.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navGoals),
      ),
      body: const EmptyStateWidget(
        icon: Icons.savings_rounded,
        title: 'Savings Goals Tracker',
        description: 'Track custom savings targets and milestones in Phase 6.',
      ),
    );
  }
}
