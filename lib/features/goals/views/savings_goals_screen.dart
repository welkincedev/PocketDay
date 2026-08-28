import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/savings_goals_provider.dart';
import '../widgets/add_savings_goal_bottom_sheet.dart';
import '../widgets/savings_goal_card.dart';
import '../widgets/savings_goal_detail_bottom_sheet.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  void _openAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSavingsGoalBottomSheet(),
    );
  }

  void _openDetailSheet(BuildContext context, widgetRef) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SavingsGoalDetailBottomSheet(goal: widgetRef),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsGoalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeGoals = state.goals.where((g) => !g.isCompleted).toList();
    final completedGoals = state.goals.where((g) => g.isCompleted).toList();

    Widget body;
    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.goals.isEmpty) {
      body = EmptyStateWidget(
        title: "Nothing you're saving for yet.",
        description: "Create a goal and give your money somewhere to go.",
        icon: Icons.savings_outlined,
        actionText: 'Create Goal',
        onActionPressed: () => _openAddGoalSheet(context),
      );
    } else {
      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeGoals.isNotEmpty) ...[
                  Text(
                    'Active Goals',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeGoals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = activeGoals[index];
                      return SavingsGoalCard(
                        goal: goal,
                        onTap: () => _openDetailSheet(context, goal),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                ],
                if (completedGoals.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Completed Goals',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedGoals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = completedGoals[index];
                      return Opacity(
                        opacity: 0.75, // Subdued look for completed goals
                        child: SavingsGoalCard(
                          goal: goal,
                          onTap: () => _openDetailSheet(context, goal),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          if (state.goals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _openAddGoalSheet(context),
            ),
        ],
      ),
      body: body,
      floatingActionButton: state.goals.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _openAddGoalSheet(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
