// ============================================================
// PocketDay — dashboardProvider
// ============================================================
//
// Purpose:
// Home dashboard state notifier deriving metrics (balance, monthly income, monthly expenses, budget progress) reactively from memory state.
//
// Responsibilities:
// - Maintain DashboardState snapshot for DashboardScreen.
// - Listen to transactionsProvider and budgetProvider state changes.
// - Calculate total income, total expense, net balance, current month spending, and overall monthly budget in memory ($O(N)$ speed).
// - Expose recent 5 transactions for quick view widgets.
// - Avoid duplicate Firestore network requests on app startup and form updates.
//
// Data Flow:
// TransactionsProvider & BudgetProvider → ref.listen() → DashboardNotifier._recalculate() → DashboardState → DashboardScreen UI
//
// Important Rules:
// - Derived Financial Metrics: Metrics are computed dynamically in memory without issuing separate query requests to Cloud Firestore.
// - Listening Architecture: Uses ref.listen() on transactionsProvider and budgetProvider to react instantly to transaction adds, edits, or deletes.
//
// Main Operations:
// - loadDashboardData() — Fetches initial transaction and budget state on cold startup.
// - updateTransactions(txns) — Receives updated transaction list from transactionsProvider listener and triggers _recalculate().
// - updateBudgets(budgets) — Receives updated budget list from budgetProvider listener and triggers _recalculate().
// - _recalculate() — Iterates in-memory transaction list to sum income, expenses, and current month spending in $O(N)$ time.
//
// Dependencies / Collaborators:
// - TransactionRepository — Primary data repository for financial transactions.
// - BudgetRepository — Primary data repository for monthly budget limits.
// - transactionsProvider — Riverpod provider supplying active transaction list.
// - budgetProvider — Riverpod provider supplying active budget targets list.
//
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../budget/providers/budget_provider.dart';
import '../../transactions/providers/transactions_provider.dart';

/// Immutable snapshot of the Dashboard's derived financial data.
/// All metrics are computed in memory to prevent redundant Firestore network queries.
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
      final notifier = DashboardNotifier(txnRepo, budgetRepo);

      // Listen to transactions and budgets state to recalculate metrics in memory without extra network calls
      ref.listen(transactionsProvider, (previous, next) {
        notifier.updateTransactions(next.transactions);
      });

      ref.listen(budgetProvider, (previous, next) {
        notifier.updateBudgets(next.allBudgets);
      });

      final initialTxns = ref.read(transactionsProvider).transactions;
      final initialBudgets = ref.read(budgetProvider).allBudgets;
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
          defaultMessage: "Couldn't load dashboard data. Please check your connection and try again.",
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
    // Perform in-memory calculation of totals in O(N) time.
    // Derived values (total balance, monthly income, monthly expenses) are calculated dynamically
    // from local provider lists, ensuring instant UI updates without incurring Cloud Firestore read costs.
    double income = 0.0;
    double expense = 0.0;
    double currentMonthExp = 0.0;
    final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());

    for (var txn in _transactions) {
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

    double monthlyBudgetVal = 0.0;
    for (var b in _budgets) {
      if (b.month == currentMonthStr && b.categoryId == null) {
        monthlyBudgetVal = b.amount;
        break;
      }
    }

    state = state.copyWith(
      totalIncome: income,
      totalExpense: expense,
      monthlyBudget: monthlyBudgetVal,
      currentMonthExpense: currentMonthExp,
      recentTransactions: _transactions.take(5).toList(),
      isLoading: false,
    );
  }

  Future<void> addTransaction(TransactionModel txn) async {
    await _txnRepo.addTransaction(txn);
    // In-memory update will trigger automatically via transactionsProvider listener
  }
}
