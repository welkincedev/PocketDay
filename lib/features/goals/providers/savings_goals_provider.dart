// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: savings_goals_provider.dart
//
// Purpose:
// StateNotifier and state snapshot class for explicit `SavingsGoalModel` entities.
//
// Responsibilities:
// - Load and maintain savings goals list sorted by active vs completed status.
// - Perform CRUD operations on savings goals.
// - Support `addSavings(goalId, amount)` and `removeSavings(goalId, amount)` balance modifications.
//
// Data Flow:
// Savings Goals UI → SavingsGoalsNotifier → SavingsGoalRepository → Hive (`goalsBox`)
//
// Important Rules:
// - Sorts active incomplete goals first followed by completed goals.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../../data/repositories/savings_goal_repository.dart';

class SavingsGoalsState {
  final List<SavingsGoalModel> goals;
  final bool isLoading;
  final String? error;

  SavingsGoalsState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
  });

  SavingsGoalsState copyWith({
    List<SavingsGoalModel>? goals,
    bool? isLoading,
    String? error,
  }) {
    return SavingsGoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final savingsGoalsProvider =
    StateNotifierProvider<SavingsGoalsNotifier, SavingsGoalsState>((ref) {
      final repo = ref.watch(savingsGoalRepositoryProvider);
      return SavingsGoalsNotifier(repo);
    });

class SavingsGoalsNotifier extends StateNotifier<SavingsGoalsState> {
  final SavingsGoalRepository _repo;

  SavingsGoalsNotifier(this._repo) : super(SavingsGoalsState()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    if (state.goals.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final goals = await _repo.getGoals();
      goals.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required String emoji,
    DateTime? targetDate,
  }) async {
    final newGoal = SavingsGoalModel(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      targetAmount: targetAmount,
      savedAmount: 0.0,
      emoji: emoji,
      targetDate: targetDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repo.saveGoal(newGoal);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    final updated = goal.copyWith(updatedAt: DateTime.now());
    try {
      await _repo.saveGoal(updated);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repo.deleteGoal(id);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addSavings(String goalId, double amount) async {
    try {
      final goal = state.goals.firstWhere((g) => g.id == goalId);
      final newSavedAmount = goal.savedAmount + amount;
      final updated = goal.copyWith(
        savedAmount: newSavedAmount,
        updatedAt: DateTime.now(),
      );
      await _repo.saveGoal(updated);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeSavings(String goalId, double amount) async {
    try {
      final goal = state.goals.firstWhere((g) => g.id == goalId);
      final newSavedAmount = (goal.savedAmount - amount) > 0
          ? (goal.savedAmount - amount)
          : 0.0;
      final updated = goal.copyWith(
        savedAmount: newSavedAmount,
        updatedAt: DateTime.now(),
      );
      await _repo.saveGoal(updated);
      await loadGoals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
