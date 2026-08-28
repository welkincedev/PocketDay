import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/services/hive_service.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';


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
    this.monthlyBudget = 50000.0,
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

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return DashboardNotifier(repo);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final TransactionRepository _repo;

  DashboardNotifier(this._repo) : super(DashboardState()) {
    loadDashboardData();
    HiveService.transactionsBox.listenable().addListener(_onBoxChanged);
    HiveService.budgetBox.listenable().addListener(_onBoxChanged);
  }

  void _onBoxChanged() {
    loadDashboardData();
  }

  @override
  void dispose() {
    HiveService.transactionsBox.listenable().removeListener(_onBoxChanged);
    HiveService.budgetBox.listenable().removeListener(_onBoxChanged);
    super.dispose();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final txns = await _repo.getTransactions();

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

      // Load overall budget for current month from Hive
      double monthlyBudgetVal = 50000.0; // default fallback
      final budgetBox = HiveService.budgetBox;
      for (var item in budgetBox.values) {
        if (item is Map) {
          final b = BudgetModel.fromMap(Map<String, dynamic>.from(item));
          if (b.month == currentMonthStr && b.categoryId == null) {
            monthlyBudgetVal = b.amount;
            break;
          }
        }
      }

      state = state.copyWith(
        totalIncome: income,
        totalExpense: expense,
        monthlyBudget: monthlyBudgetVal,
        currentMonthExpense: currentMonthExp,
        recentTransactions: txns.take(5).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addTransaction(TransactionModel txn) async {
    await _repo.addTransaction(txn);
  }
}
