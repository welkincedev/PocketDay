import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/hive_service.dart';
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
    HiveService.goalsBox.listenable().addListener(_onGoalsBoxChanged);
  }

  void _onGoalsBoxChanged() {
    loadGoals();
  }

  @override
  void dispose() {
    HiveService.goalsBox.listenable().removeListener(_onGoalsBoxChanged);
    super.dispose();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final goals = await _repo.getGoals();
      // Default sorting: active goals first, then by progress desc, then by date desc
      goals.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1; // Active goals first
        }
        return b.createdAt.compareTo(a.createdAt); // Creation order descending
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    final updated = goal.copyWith(updatedAt: DateTime.now());
    try {
      await _repo.saveGoal(updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _repo.deleteGoal(id);
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
