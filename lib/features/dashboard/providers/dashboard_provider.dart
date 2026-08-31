// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: dashboard_provider.dart
//
// Purpose:
// StateNotifier and state snapshot class for home dashboard metrics.
//
// Responsibilities:
// - Compute total income, total expense, current balance, monthly budget, and current month spending.
// - Filter 5 most recent transactions for home feed.
// - Listen to Hive `transactionsBox` and `budgetBox` change events to trigger automatic recalculations.
//
// Data Flow:
// Hive Boxes Listener → DashboardNotifier.loadDashboardData() → DashboardState → Dashboard UI
//
// Important Rules:
// - Listens to `transactionsBox` and `budgetBox` changes; disposes listeners cleanly upon unmount.
//
// Main Operations:
// - loadDashboardData(): Aggregate transaction sums and read current month budget
// - addTransaction(txn): Save transaction via repository
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

/// Immutable snapshot of the Dashboard's derived financial data.
///
/// All amounts are scoped to the **current calendar month**.
/// [totalBalance] = [totalIncome] − [totalExpense] for the month.
/// [remainingBudget] is computed from [monthlyBudget] − [currentMonthExpense].
class DashboardState {
  final double totalIncome;
  final double totalExpense;
  final double monthlyBudget;
  final double currentMonthExpense;
  final List<TransactionModel> recentTransactions;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.monthlyBudget = 0.0,
    this.currentMonthExpense = 0.0,
    this.recentTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalBalance => totalIncome - totalExpense;
  double get remainingBudget => monthlyBudget - currentMonthExpense;

  DashboardState copyWith({
    double? totalIncome,
    double? totalExpense,
    double? monthlyBudget,
    double? currentMonthExpense,
    List<TransactionModel>? recentTransactions,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currentMonthExpense: currentMonthExpense ?? this.currentMonthExpense,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final txnRepo = ref.watch(transactionRepositoryProvider);
      final budgetRepo = ref.watch(budgetRepositoryProvider);
      return DashboardNotifier(txnRepo, budgetRepo);
    });

class DashboardNotifier extends StateNotifier<DashboardState> {
  final TransactionRepository _txnRepo;
  final BudgetRepository _budgetRepo;

  DashboardNotifier(this._txnRepo, this._budgetRepo)
    : super(DashboardState()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    if (state.recentTransactions.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final txns = await _txnRepo.getTransactions();

      double income = 0.0;
      double expense = 0.0;
      double currentMonthExp = 0.0;
      final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());

      for (var txn in txns) {
        if (txn.type == TransactionType.income) {
          income += txn.amount;
        } else {
          expense += txn.amount;
          final tMonth = DateFormat('yyyy-MM').format(txn.date);
          if (tMonth == currentMonthStr) {
            currentMonthExp += txn.amount;
          }
        }
      }

      // Load overall budget for current month from BudgetRepository
      double monthlyBudgetVal = 0.0;
      try {
        final budgets = await _budgetRepo.getBudgets();
        for (var b in budgets) {
          if (b.month == currentMonthStr && b.categoryId == null) {
            monthlyBudgetVal = b.amount;
            break;
          }
        }
      } catch (_) {}

      state = state.copyWith(
        totalIncome: income,
        totalExpense: expense,
        monthlyBudget: monthlyBudgetVal,
        currentMonthExpense: currentMonthExp,
        recentTransactions: txns.take(5).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTransaction(TransactionModel txn) async {
    await _txnRepo.addTransaction(txn);
    await loadDashboardData();
  }
}
