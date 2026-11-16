// ============================================================================
// PocketDay
// File: budget_provider.dart
// Purpose: Monthly budget limits, financial period calculation, and spending progress state management.
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/utils/financial_period.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../transactions/providers/transactions_provider.dart';
import 'financial_month_provider.dart';

class BudgetState {
  final DateTime selectedMonth;
  final FinancialPeriod activePeriod;
  final List<BudgetModel> allBudgets;
  final List<BudgetModel> currentBudgets;
  final Map<String?, double> categorySpending;
  final bool isLoading;
  final String? error;

  BudgetState({
    required this.selectedMonth,
    required this.activePeriod,
    this.allBudgets = const [],
    this.currentBudgets = const [],
    this.categorySpending = const {},
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    DateTime? selectedMonth,
    FinancialPeriod? activePeriod,
    List<BudgetModel>? allBudgets,
    List<BudgetModel>? currentBudgets,
    Map<String?, double>? categorySpending,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      activePeriod: activePeriod ?? this.activePeriod,
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

  // Listen to financial month settings to update calculations dynamically
  ref.listen(financialMonthProvider, (previous, next) {
    notifier.updateFinancialMonth(next);
  });

  // Fetch initial transactions
  final initialTxns = ref.read(transactionsProvider).transactions;
  notifier.updateTransactions(initialTxns);

  // Fetch initial financial month settings
  final initialFinMonth = ref.read(financialMonthProvider);
  notifier.updateFinancialMonth(initialFinMonth);

  return notifier;
});

class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository _repo;
  List<TransactionModel> _transactions = [];
  FinancialMonthState _financialMonth = const FinancialMonthState();

  BudgetNotifier(this._repo)
    : super(BudgetState(
        selectedMonth: DateTime.now(),
        activePeriod: FinancialPeriod.fromDateTime(DateTime.now()),
      )) {
    loadBudgets();
  }

  void updateFinancialMonth(FinancialMonthState financialMonth) {
    _financialMonth = financialMonth;
    _calculateAndApply();
  }

  void clearData() {
    _repo.clearLocalData();
    _transactions = [];
    state = BudgetState(
      selectedMonth: DateTime.now(),
      activePeriod: _financialMonth.currentPeriod,
    );
  }

  Future<void> loadBudgets() async {
    if (state.allBudgets.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final budgets = await _repo.getBudgets();
      state = state.copyWith(allBudgets: budgets, isLoading: false);
      _calculateAndApply();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Load Budgets', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't load your budget. Please try again.",
        ),
      );
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
    final period = _financialMonth.periodForCycle(
      state.selectedMonth.year,
      state.selectedMonth.month,
    );
    final monthStr = period.cycleKey;

    // Filter budgets for the active financial period cycle
    final monthlyBudgets = state.allBudgets
        .where((b) => b.month == monthStr)
        .toList();

    // Calculate spending per category within the active financial period boundaries
    final Map<String?, double> spending = {};
    double overallSpent = 0.0;

    final monthlyExpenses = _transactions.where((t) {
      return period.contains(t.date) && t.type == TransactionType.expense;
    }).toList();

    for (var exp in monthlyExpenses) {
      spending[exp.categoryId] = (spending[exp.categoryId] ?? 0.0) + exp.amount;
      overallSpent += exp.amount;
    }

    spending[null] = overallSpent; // null represents overall budget spent

    state = state.copyWith(
      currentBudgets: monthlyBudgets,
      categorySpending: spending,
      activePeriod: period,
    );
  }

  Future<void> saveBudget(BudgetModel budget) async {
    try {
      await _repo.saveBudget(budget);
      await loadBudgets();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Save Budget', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't save your budget. Please try again.",
        ),
      );
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _repo.deleteBudget(id);
      await loadBudgets();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Delete Budget', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't delete your budget. Please try again.",
        ),
      );
    }
  }
}
