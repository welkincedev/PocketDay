// ============================================================================
// PocketDay
// File: savings_goals_provider.dart
// Purpose: Savings goals state notifier managing saved amounts and target progress.
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_error_handler.dart';
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
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Load Savings Goals', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't load your savings goals. Please try again.",
        ),
      );
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
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Add Savings Goal', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't save your savings goal. Please try again.",
        ),
      );
    }
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    final updated = goal.copyWith(updatedAt: DateTime.now());
    try {
      await _repo.saveGoal(updated);
      await loadGoals();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Update Savings Goal', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't save your savings goal. Please try again.",
        ),
      );
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repo.deleteGoal(id);
      await loadGoals();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Delete Savings Goal', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't delete your savings goal. Please try again.",
        ),
      );
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
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Add Savings', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't save your savings goal. Please try again.",
        ),
      );
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
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Remove Savings', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't update your savings goal. Please try again.",
        ),
      );
    }
  }
}
