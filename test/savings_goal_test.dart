// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: savings_goal_test.dart
//
// Purpose:
// Unit test suite for `SavingsGoalModel` progress calculations and `SavingsGoalsNotifier` state management.
//
// Responsibilities:
// - Verify percentage rate and progress bar values.
// - Verify deposit (`addSavings`) and withdrawal (`removeSavings`) operations.
//
// Data Flow:
// Mock Savings Goals Box → ProviderContainer → SavingsGoalsNotifier → Test Assertions
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketday/data/models/savings_goal_model.dart';
import 'package:pocketday/data/repositories/savings_goal_repository.dart';
import 'package:pocketday/features/goals/providers/savings_goals_provider.dart';

void main() {

  test(
    'SavingsGoalModel calculates progress and completed status correctly',
    () {
      // 0% progress
      final goal1 = SavingsGoalModel(
        id: 'g1',
        name: 'New Phone',
        targetAmount: 10000.0,
        savedAmount: 0.0,
        emoji: '📱',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(goal1.progress, 0.0);
      expect(goal1.percentage, 0.0);
      expect(goal1.remainingAmount, 10000.0);
      expect(goal1.isCompleted, false);

      // Partial progress (53%)
      final goal2 = goal1.copyWith(savedAmount: 5300.0);
      expect(goal2.progress, 0.53);
      expect(goal2.percentage, 53.0);
      expect(goal2.remainingAmount, 4700.0);
      expect(goal2.isCompleted, false);

      // 100% progress
      final goal3 = goal1.copyWith(savedAmount: 10000.0);
      expect(goal3.progress, 1.0);
      expect(goal3.percentage, 100.0);
      expect(goal3.remainingAmount, 0.0);
      expect(goal3.isCompleted, true);

      // Above 100% progress (109%)
      final goal4 = goal1.copyWith(savedAmount: 10900.0);
      expect(goal4.progress, 1.0); // Clamped physically to 1.0
      expect(
        goal4.percentage,
        closeTo(109.0, 0.0001),
      ); // True percentage preserved
      expect(goal4.remainingAmount, 0.0);
      expect(goal4.isCompleted, true);
    },
  );

  test('SavingsGoal CRUD and provider operations work correctly', () async {
    final container = ProviderContainer(
      overrides: [
        savingsGoalRepositoryProvider.overrideWithValue(
          SavingsGoalRepositoryImpl(),
        ),
      ],
    );

    // Initial state check
    var state = container.read(savingsGoalsProvider);
    expect(state.goals.isEmpty, true);

    // 1. Create savings goal
    await container
        .read(savingsGoalsProvider.notifier)
        .addGoal(
          name: 'Trip to Goa',
          targetAmount: 25000.0,
          emoji: '✈️',
          targetDate: DateTime(2026, 12, 1),
        );

    state = container.read(savingsGoalsProvider);
    expect(state.goals.length, 1);
    final firstGoal = state.goals.first;
    expect(firstGoal.name, 'Trip to Goa');
    expect(firstGoal.targetAmount, 25000.0);
    expect(firstGoal.emoji, '✈️');
    expect(firstGoal.savedAmount, 0.0);

    // 2. Add savings
    await container
        .read(savingsGoalsProvider.notifier)
        .addSavings(firstGoal.id, 5000.0);
    state = container.read(savingsGoalsProvider);
    expect(state.goals.first.savedAmount, 5000.0);
    expect(state.goals.first.remainingAmount, 20000.0);
    expect(state.goals.first.progress, 0.20);

    // 3. Remove savings
    await container
        .read(savingsGoalsProvider.notifier)
        .removeSavings(firstGoal.id, 2000.0);
    state = container.read(savingsGoalsProvider);
    expect(state.goals.first.savedAmount, 3000.0);

    // 4. Update goal details
    final goalToUpdate = state.goals.first.copyWith(
      name: 'Trip to Maldives',
      targetAmount: 80000.0,
    );
    await container
        .read(savingsGoalsProvider.notifier)
        .updateGoal(goalToUpdate);
    state = container.read(savingsGoalsProvider);
    expect(state.goals.first.name, 'Trip to Maldives');
    expect(state.goals.first.targetAmount, 80000.0);

    // 5. Delete goal
    await container
        .read(savingsGoalsProvider.notifier)
        .deleteGoal(firstGoal.id);
    state = container.read(savingsGoalsProvider);
    expect(state.goals.isEmpty, true);
  });
}
