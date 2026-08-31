// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: savings_goals_screen.dart
//
// Purpose:
// Goals overview tab screen listing active and completed financial targets.
//
// Responsibilities:
// - Render list of active financial goals and completed goals dynamically using `goalsProvider`.
// - Render `GoalCard` for each target goal.
// - Launch goal creation sheet (`CreateGoalSheet`) or navigate to `GoalDetailScreen`.
//
// Data Flow:
// goalsProvider → GoalsScreen → GoalCard → GoalDetailScreen
//
// Important Rules:
// - Completed goals are rendered with subtle 72% opacity.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/goal_model.dart';
import '../providers/goals_provider.dart';
import '../widgets/create_goal_sheet.dart';
import '../widgets/goal_card.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGoalSheet(),
    );
  }

  void _openDetailScreen(BuildContext context, GoalModel goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GoalDetailScreen(goal: goal)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(goalsProvider);
    final transactions = state.transactions;

    // Separate active and completed, computed dynamically
    final activeGoals = state.goals
        .where(
          (g) => !g.isGoalCompleted(g.calculateCurrentAmount(transactions)),
        )
        .toList();
    final completedGoals = state.goals
        .where((g) => g.isGoalCompleted(g.calculateCurrentAmount(transactions)))
        .toList();

    Widget body;

    if (state.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.goals.isEmpty) {
      body = EmptyStateWidget(
        title: "No goals yet.",
        description: "Create a goal and give your money a purpose.",
        icon: Icons.flag_outlined,
        actionText: 'Create Goal',
        onActionPressed: () => _openCreateSheet(context),
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
                    'Active',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeGoals.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = activeGoals[index];
                      final current = goal.calculateCurrentAmount(transactions);
                      return GoalCard(
                        goal: goal,
                        currentAmount: current,
                        onTap: () => _openDetailScreen(context, goal),
                      );
                    },
                  ),
                  if (completedGoals.isNotEmpty) const SizedBox(height: 28),
                ],

                if (completedGoals.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedGoals.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = completedGoals[index];
                      final current = goal.calculateCurrentAmount(transactions);
                      return Opacity(
                        opacity: 0.72,
                        child: GoalCard(
                          goal: goal,
                          currentAmount: current,
                          onTap: () => _openDetailScreen(context, goal),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 80), // FAB clearance
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
