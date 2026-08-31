// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: budget_test.dart
//
// Purpose:
// Unit test suite for Budget CRUD, overall/category monthly limits, and dynamic spending calculations.
//
// Responsibilities:
// - Verify budget creation, update, and deletion in Hive `budgetBox`.
// - Verify income exclusion and accurate category spending aggregation from transactions.
//
// Data Flow:
// Mock Hive Boxes → ProviderContainer → BudgetNotifier → Test Assertions
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketday/data/models/budget_model.dart';
import 'package:pocketday/data/models/transaction_model.dart';
import 'package:pocketday/data/repositories/budget_repository.dart';
import 'package:pocketday/data/repositories/transaction_repository.dart';
import 'package:pocketday/features/budget/providers/budget_provider.dart';
import 'package:pocketday/features/transactions/providers/transactions_provider.dart';

void main() {

  test('Budget CRUD and calculations works correctly', () async {
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          TransactionRepositoryImpl(),
        ),
        budgetRepositoryProvider.overrideWithValue(BudgetRepositoryImpl()),
      ],
    );

    // Wait for TransactionsNotifier constructor to finish loading seed transactions
    container.read(transactionsProvider.notifier);
    while (container.read(transactionsProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Set selected month to a specific month matching transactions (e.g. August 2026)
    final targetMonth = DateTime(2026, 8, 1);
    container.read(budgetProvider.notifier).setSelectedMonth(targetMonth);

    // Initial state check
    var state = container.read(budgetProvider);
    expect(state.allBudgets.isEmpty, true);
    expect(state.currentBudgets.isEmpty, true);

    // 1. Create Overall Budget
    final overallBudget = BudgetModel(
      id: 'b_overall_1',
      amount: 20000.0,
      month: '2026-08',
      categoryId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await container.read(budgetProvider.notifier).saveBudget(overallBudget);

    // Wait for listener to propagate
    state = container.read(budgetProvider);
    expect(state.allBudgets.length, 1);
    expect(state.currentBudgets.length, 1);
    expect(state.currentBudgets.first.amount, 20000.0);
    expect(state.currentBudgets.first.categoryId, null);

    // 2. Create Category Budget
    final foodBudget = BudgetModel(
      id: 'b_food_1',
      amount: 5000.0,
      month: '2026-08',
      categoryId: 'food',
      categoryName: 'Food & Dining',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await container.read(budgetProvider.notifier).saveBudget(foodBudget);

    state = container.read(budgetProvider);
    expect(state.allBudgets.length, 2);
    expect(state.currentBudgets.length, 2);

    // 3. Test spent calculations from seed transactions
    // Inject some manual transaction models to the transactions notifier
    final t1 = TransactionModel(
      id: 't_f1',
      title: 'Lunch',
      amount: 450.0,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Food & Dining',
      date: DateTime(2026, 8, 15),
    );
    final t2 = TransactionModel(
      id: 't_f2',
      title: 'Uber Auto',
      amount: 200.0,
      type: TransactionType.expense,
      categoryId: 'transport',
      categoryName: 'Transportation',
      date: DateTime(2026, 8, 16),
    );
    final t3 = TransactionModel(
      id: 't_f3',
      title: 'Salary Deposit',
      amount: 60000.0,
      type: TransactionType.income,
      categoryId: 'salary',
      categoryName: 'Salary',
      date: DateTime(2026, 8, 1),
    );

    await container.read(transactionsProvider.notifier).addTransaction(t1);
    await container.read(transactionsProvider.notifier).addTransaction(t2);
    await container.read(transactionsProvider.notifier).addTransaction(t3);

    // Trigger notifier reload
    await container.read(transactionsProvider.notifier).loadTransactions();
    state = container.read(budgetProvider);

    // Verify category spending calculations
    final foodSpent = state.categorySpending['food'] ?? 0.0;
    expect(foodSpent, 450.0); // t1 Food expense (450.0)

    // Overall spent must be 650.0 (t1 Food 450.0 + t2 Transport 200.0)
    final overallSpent = state.categorySpending[null] ?? 0.0;
    expect(overallSpent, 650.0);

    // 4. Update Budget
    final updatedFoodBudget = foodBudget.copyWith(amount: 6000.0);
    await container.read(budgetProvider.notifier).saveBudget(updatedFoodBudget);

    state = container.read(budgetProvider);
    final foodLimit = state.currentBudgets
        .firstWhere((b) => b.categoryId == 'food')
        .amount;
    expect(foodLimit, 6000.0);

    // 5. Delete Budget
    await container.read(budgetProvider.notifier).deleteBudget('b_overall_1');
    state = container.read(budgetProvider);
    expect(state.allBudgets.length, 1);
    expect(state.currentBudgets.length, 1);
    expect(state.currentBudgets.first.categoryId, 'food');
  });
}
