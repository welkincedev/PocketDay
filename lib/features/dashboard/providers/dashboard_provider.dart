import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/hive_service.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';


class DashboardState {
  final double totalIncome;
  final double totalExpense;
  final double monthlyBudget;
  final List<TransactionModel> recentTransactions;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.monthlyBudget = 50000.0,
    this.recentTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalBalance => totalIncome - totalExpense;
  double get remainingBudget => monthlyBudget - totalExpense;

  DashboardState copyWith({
    double? totalIncome,
    double? totalExpense,
    double? monthlyBudget,
    List<TransactionModel>? recentTransactions,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
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
    HiveService.transactionsBox.listenable().addListener(_onTransactionsChanged);
  }

  void _onTransactionsChanged() {
    loadDashboardData();
  }

  @override
  void dispose() {
    HiveService.transactionsBox.listenable().removeListener(_onTransactionsChanged);
    super.dispose();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final txns = await _repo.getTransactions();

      double income = 0.0;
      double expense = 0.0;

      for (var txn in txns) {
        if (txn.type == TransactionType.income) {
          income += txn.amount;
        } else {
          expense += txn.amount;
        }
      }

      state = state.copyWith(
        totalIncome: income,
        totalExpense: expense,
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
