// ============================================================
// PocketDay — dashboardProvider
// ============================================================
//
// Purpose:
// Home dashboard state notifier deriving metrics (balance, period income, period expenses, budget progress) reactively from memory state.
//
// Responsibilities:
// - Maintain DashboardState snapshot for DashboardScreen.
// - Listen to transactionsProvider, budgetProvider, and financialMonthProvider state changes.
// - Calculate total income, total expense, net balance, current financial period spending, and period budget in memory ($O(N)$ speed).
// - Expose recent 5 transactions for quick view widgets.
// - Avoid duplicate Firestore network requests on app startup and form updates.
//
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../budget/providers/budget_provider.dart';
import '../../budget/providers/financial_month_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

/// Immutable snapshot of the Dashboard's derived financial data.
/// All metrics are computed in memory to prevent redundant Firestore network queries.
class DashboardState {
  final double totalIncome;
  final double totalExpense;
  final double monthlyBudget;
  final double currentMonthExpense;
  final double periodIncome;
  final double periodExpense;
  final List<TransactionModel> recentTransactions;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.monthlyBudget = 0.0,
    this.currentMonthExpense = 0.0,
    this.periodIncome = 0.0,
    this.periodExpense = 0.0,
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
    double? periodIncome,
    double? periodExpense,
    List<TransactionModel>? recentTransactions,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currentMonthExpense: currentMonthExpense ?? this.currentMonthExpense,
      periodIncome: periodIncome ?? this.periodIncome,
      periodExpense: periodExpense ?? this.periodExpense,
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
  final notifier = DashboardNotifier(txnRepo, budgetRepo);

  // Listen to transactions and budgets state to recalculate metrics in memory without extra network calls
  ref.listen(transactionsProvider, (previous, next) {
    notifier.updateTransactions(next.transactions);
  });

  ref.listen(budgetProvider, (previous, next) {
    notifier.updateBudgets(next.allBudgets);
  });

  ref.listen(financialMonthProvider, (previous, next) {
    notifier.updateFinancialMonth(next);
  });

  final initialTxns = ref.read(transactionsProvider).transactions;
  final initialBudgets = ref.read(budgetProvider).allBudgets;
  final initialFinMonth = ref.read(financialMonthProvider);
  notifier.updateFinancialMonth(initialFinMonth);
  if (initialTxns.isNotEmpty || initialBudgets.isNotEmpty) {
    notifier.updateAll(initialTxns, initialBudgets);
  }

  return notifier;
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final TransactionRepository _txnRepo;
  final BudgetRepository _budgetRepo;

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  FinancialMonthState _financialMonth = const FinancialMonthState();

  DashboardNotifier(this._txnRepo, this._budgetRepo)
      : super(DashboardState()) {
    loadDashboardData();
  }

  void updateFinancialMonth(FinancialMonthState finMonth) {
    _financialMonth = finMonth;
    _recalculate();
  }

  void clearData() {
    _txnRepo.clearLocalData();
    _budgetRepo.clearLocalData();
    _transactions = [];
    _budgets = [];
    state = DashboardState();
  }

  Future<void> loadDashboardData() async {
    if (state.recentTransactions.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final txns = await _txnRepo.getTransactions();
      final budgets = await _budgetRepo.getBudgets();
      _transactions = txns;
      _budgets = budgets;
      _recalculate();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Load Dashboard', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage:
              "Couldn't load dashboard data. Please check your connection and try again.",
        ),
      );
    }
  }

  void updateTransactions(List<TransactionModel> txns) {
    _transactions = txns;
    _recalculate();
  }

  void updateBudgets(List<BudgetModel> budgets) {
    _budgets = budgets;
    _recalculate();
  }

  void updateAll(List<TransactionModel> txns, List<BudgetModel> budgets) {
    _transactions = txns;
    _budgets = budgets;
    _recalculate();
  }

  void _recalculate() {
    double allTimeIncome = 0.0;
    double allTimeExpense = 0.0;
    double currentPeriodExp = 0.0;
    double currentPeriodInc = 0.0;

    final currentPeriod = _financialMonth.currentPeriod;
    final currentCycleKey = currentPeriod.cycleKey;

    for (var txn in _transactions) {
      if (txn.type == TransactionType.income) {
        allTimeIncome += txn.amount;
        if (currentPeriod.contains(txn.date)) {
          currentPeriodInc += txn.amount;
        }
      } else {
        allTimeExpense += txn.amount;
        if (currentPeriod.contains(txn.date)) {
          currentPeriodExp += txn.amount;
        }
      }
    }

    double monthlyBudgetVal = 0.0;
    for (var b in _budgets) {
      if (b.month == currentCycleKey && b.categoryId == null) {
        monthlyBudgetVal = b.amount;
        break;
      }
    }

    state = state.copyWith(
      totalIncome: allTimeIncome,
      totalExpense: allTimeExpense,
      periodIncome: currentPeriodInc,
      periodExpense: currentPeriodExp,
      monthlyBudget: monthlyBudgetVal,
      currentMonthExpense: currentPeriodExp,
      recentTransactions: _transactions.take(5).toList(),
      isLoading: false,
    );
  }

  Future<void> addTransaction(TransactionModel txn) async {
    // In-memory recalculation occurs automatically via the transactionsProvider listener.
  }
}
