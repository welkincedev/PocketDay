// ============================================================================
// PocketDay
// File: budget_provider.dart
// Purpose: Monthly budget limits and spending progress state management.
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../transactions/providers/transactions_provider.dart';

class BudgetState {
  final DateTime selectedMonth;
  final List<BudgetModel> allBudgets;
  final List<BudgetModel> currentBudgets;
  final Map<String?, double> categorySpending;
  final bool isLoading;
  final String? error;

  BudgetState({
    required this.selectedMonth,
    this.allBudgets = const [],
    this.currentBudgets = const [],
    this.categorySpending = const {},
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    DateTime? selectedMonth,
    List<BudgetModel>? allBudgets,
    List<BudgetModel>? currentBudgets,
    Map<String?, double>? categorySpending,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      allBudgets: allBudgets ?? this.allBudgets,
      currentBudgets: currentBudgets ?? this.currentBudgets,
      categorySpending: categorySpending ?? this.categorySpending,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((
  ref,
) {
  final repo = ref.watch(budgetRepositoryProvider);
  final notifier = BudgetNotifier(repo);

  // Listen to transactions list changes to update calculations dynamically
  ref.listen(transactionsProvider, (previous, next) {
    notifier.updateTransactions(next.transactions);
  });

  // Fetch initial transactions
  final initialTxns = ref.read(transactionsProvider).transactions;
  notifier.updateTransactions(initialTxns);

  return notifier;
});

class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository _repo;
  List<TransactionModel> _transactions = [];

  BudgetNotifier(this._repo)
    : super(BudgetState(selectedMonth: DateTime.now())) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    if (state.allBudgets.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final budgets = await _repo.getBudgets();
      state = state.copyWith(allBudgets: budgets, isLoading: false);
      _calculateAndApply();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void updateTransactions(List<TransactionModel> txns) {
    _transactions = txns;
    _calculateAndApply();
  }

  void setSelectedMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
    _calculateAndApply();
  }

  void _calculateAndApply() {
    final monthStr = DateFormat('yyyy-MM').format(state.selectedMonth);

    // Filter budgets for the selected month
    final monthlyBudgets = state.allBudgets
        .where((b) => b.month == monthStr)
        .toList();

    // Calculate spending per category
    final Map<String?, double> spending = {};
    double overallSpent = 0.0;

    // Filter transactions for the selected month and type == expense
    final monthlyExpenses = _transactions.where((t) {
      final tMonth = DateFormat('yyyy-MM').format(t.date);
      return tMonth == monthStr && t.type == TransactionType.expense;
    }).toList();

    for (var exp in monthlyExpenses) {
      spending[exp.categoryId] = (spending[exp.categoryId] ?? 0.0) + exp.amount;
      overallSpent += exp.amount;
    }

    spending[null] = overallSpent; // null represents overall budget spent

    state = state.copyWith(
      currentBudgets: monthlyBudgets,
      categorySpending: spending,
    );
  }

  Future<void> saveBudget(BudgetModel budget) async {
    try {
      await _repo.saveBudget(budget);
      await loadBudgets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _repo.deleteBudget(id);
      await loadBudgets();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
