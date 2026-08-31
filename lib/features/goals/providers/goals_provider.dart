// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: goals_provider.dart
//
// Purpose:
// Riverpod StateNotifier managing financial goal entities and listening to transaction progress updates.
//
// Responsibilities:
// - Read and maintain list of target goals from Hive `goalsBox`.
// - Listen to `transactionsProvider` updates so goal progress calculations update dynamically.
// - Create, update, and delete goals via `GoalRepository`.
// - Nullify `goalId` references in `transactionsBox` upon goal deletion to avoid orphaned goal links.
//
// Data Flow:
// Goal UI / TransactionsProvider → GoalsNotifier → GoalRepository → Hive (`goalsBox`)
//
// Important Rules:
// - Deleting a goal unlinks (nullifies `goalId`) all associated transactions rather than deleting the transactions.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../transactions/providers/transactions_provider.dart';

/// Immutable state container for the Goals feature.
///
/// [goals] is the persisted list of [GoalModel] objects.
/// [transactions] is a copy of the current transaction list, injected from
/// [transactionsProvider] so that goal calculations can react to any
/// transaction add / edit / delete without extra plumbing.
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
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
}
