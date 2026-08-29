import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/hive_service.dart';
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

  void updateTransactions(List<TransactionModel> txns) {
    state = state.copyWith(transactions: txns);
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final goals = await _repo.getGoals();
      // Default sorting: active goals first, then by creation date desc
      // (Wait, we can dynamically sort based on completeness by evaluating transactions!)
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
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
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

      // Nullify goalId in linked transactions
      final txBox = HiveService.transactionsBox;
      for (var key in txBox.keys) {
        final item = txBox.get(key);
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          if (map['goalId'] == id) {
            map['goalId'] = null;
            await txBox.put(key, map);
          }
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
