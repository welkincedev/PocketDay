// ============================================================================
// PocketDay
// File: goals_provider.dart
// Purpose: Financial goals state notifier listening to transaction progress updates.
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../transactions/providers/transactions_provider.dart';

/// Immutable state container for the Goals feature.
class GoalsState {
  final List<GoalModel> goals;
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;

  GoalsState({
    this.goals = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  GoalsState copyWith({
    List<GoalModel>? goals,
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return GoalsState(
      goals: goals ?? this.goals,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  final notifier = GoalsNotifier(repo);

  ref.listen(transactionsProvider, (previous, next) {
    notifier.updateTransactions(next.transactions);
  });

  final initialTxns = ref.read(transactionsProvider).transactions;
  notifier.updateTransactions(initialTxns);

  return notifier;
});

class GoalsNotifier extends StateNotifier<GoalsState> {
  final GoalRepository _repo;

  GoalsNotifier(this._repo) : super(GoalsState()) {
    loadGoals();
  }

  void updateTransactions(List<TransactionModel> txns) {
    state = state.copyWith(transactions: txns);
  }

  Future<void> loadGoals() async {
    if (state.goals.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final goals = await _repo.getGoals();
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Load Goals', e, stackTrace);
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
    final newGoal = GoalModel(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      targetAmount: targetAmount,
      emoji: emoji,
      targetDate: targetDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repo.saveGoal(newGoal);
      await loadGoals();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Add Goal', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't save your savings goal. Please try again.",
        ),
      );
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    final updated = goal.copyWith(updatedAt: DateTime.now());
    try {
      await _repo.saveGoal(updated);
      await loadGoals();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Update Goal', e, stackTrace);
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
      AppErrorHandler.logError('Delete Goal', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't delete your savings goal. Please try again.",
        ),
      );
    }
  }
}
