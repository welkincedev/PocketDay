// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: transactions_test.dart
//
// Purpose:
// Unit test suite for `TransactionsNotifier` filtering, search, sorting, and CRUD operations.
//
// Responsibilities:
// - Verify category, type, and live text search query filtering.
// - Verify sorting by date and amount.
// - Verify adding, updating, and deleting transactions in Hive `transactionsBox`.
//
// Data Flow:
// Mock Transactions Box → ProviderContainer → TransactionsNotifier → Test Assertions
// ============================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pocketday/core/constants/app_constants.dart';
import 'package:pocketday/data/models/transaction_model.dart';
import 'package:pocketday/data/repositories/transaction_repository.dart';
import 'package:pocketday/features/transactions/providers/transactions_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pocketday_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.userBox);
    final box = await Hive.openBox(AppConstants.transactionsBox);
    await box.clear();
    final bBox = await Hive.openBox(AppConstants.budgetBox);
    await bBox.clear();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('TransactionsNotifier filters and sorts correctly', () async {
    // Populate test fixture transactions
    final txnBox = Hive.box(AppConstants.transactionsBox);
    final testTxns = [
      TransactionModel(
        id: 'txn_1',
        title: 'Monthly Salary',
        amount: 65000.00,
        type: TransactionType.income,
        categoryId: 'salary',
        categoryName: 'Salary',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: 'txn_2',
        title: 'Blinkit Groceries',
        amount: 1450.00,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food & Dining',
        date: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      TransactionModel(
        id: 'txn_3',
        title: 'Netflix Subscription',
        amount: 649.00,
        type: TransactionType.expense,
        categoryId: 'entertainment',
        categoryName: 'Entertainment',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'txn_4',
        title: 'Freelance UI Project',
        amount: 18500.00,
        type: TransactionType.income,
        categoryId: 'freelance',
        categoryName: 'Freelance',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: 'txn_5',
        title: 'Starbucks Coffee',
        amount: 420.00,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food & Dining',
        date: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      TransactionModel(
        id: 'txn_6',
        title: 'Uber Auto Ride',
        amount: 210.00,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'Transportation',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
    await txnBox.putAll({for (var t in testTxns) t.id: t.toMap()});

    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          TransactionRepositoryImpl(),
        ),
      ],
    );

    // Trigger initialization and wait for constructor loading to finish to avoid re-entrance race conditions
    container.read(transactionsProvider.notifier);
    while (container.read(transactionsProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    var state = container.read(transactionsProvider);

    expect(state.transactions.length, 6);
    expect(state.filteredTransactions.length, 6);

    // Filter by type: Income
    container
        .read(transactionsProvider.notifier)
        .setSelectedType(TransactionType.income);
    state = container.read(transactionsProvider);
    expect(
      state.filteredTransactions.every((t) => t.type == TransactionType.income),
      true,
    );
    expect(state.filteredTransactions.length, 2); // Salary, Freelance

    // Clear type filter, filter by Category: Food
    container.read(transactionsProvider.notifier).setSelectedType(null);
    container.read(transactionsProvider.notifier).setSelectedCategory('food');
    state = container.read(transactionsProvider);
    expect(
      state.filteredTransactions.every((t) => t.categoryId == 'food'),
      true,
    );
    expect(state.filteredTransactions.length, 2); // Blinkit, Starbucks

    // Search query: swiggy (should match nothing) vs blinkit (matches Blinkit Groceries)
    container.read(transactionsProvider.notifier).setSelectedCategory(null);
    container.read(transactionsProvider.notifier).setSearchQuery('blinkit');
    state = container.read(transactionsProvider);
    expect(state.filteredTransactions.length, 1);
    expect(state.filteredTransactions.first.title, 'Blinkit Groceries');

    // Reset filters
    container.read(transactionsProvider.notifier).resetFilters();
    state = container.read(transactionsProvider);
    expect(state.filteredTransactions.length, 6);

    // Sort by Amount Descending
    container
        .read(transactionsProvider.notifier)
        .setSortBy(TransactionSortBy.amountDesc);
    state = container.read(transactionsProvider);
    expect(state.filteredTransactions[0].amount, 65000.0); // Salary
    expect(
      state.filteredTransactions[1].amount,
      18500.0,
    ); // Freelance UI Project
    expect(state.filteredTransactions[5].amount, 210.0); // Uber Auto Ride
  });

  test('TransactionsNotifier add, update, delete works', () async {
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          TransactionRepositoryImpl(),
        ),
      ],
    );

    // Trigger initialization and wait for constructor loading to finish to avoid re-entrance race conditions
    container.read(transactionsProvider.notifier);
    while (container.read(transactionsProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    var state = container.read(transactionsProvider);
    final initialCount = state.transactions.length;

    // Add transaction
    final newTxn = TransactionModel(
      id: 'test_txn_99',
      title: 'Coffee Test',
      amount: 150.0,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Food & Dining',
      date: DateTime.now(),
    );

    await container
        .read(transactionsProvider.notifier)
        .updateTransaction(newTxn); // update doubles as add since it uses put
    state = container.read(transactionsProvider);
    expect(state.transactions.length, initialCount + 1);
    expect(state.transactions.any((t) => t.id == 'test_txn_99'), true);

    // Update transaction title
    final updatedTxn = TransactionModel(
      id: 'test_txn_99',
      title: 'Gourmet Coffee',
      amount: 180.0,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Food & Dining',
      date: DateTime.now(),
    );

    await container
        .read(transactionsProvider.notifier)
        .updateTransaction(updatedTxn);
    state = container.read(transactionsProvider);
    final stored = state.transactions.firstWhere((t) => t.id == 'test_txn_99');
    expect(stored.title, 'Gourmet Coffee');
    expect(stored.amount, 180.0);

    // Delete transaction
    await container
        .read(transactionsProvider.notifier)
        .deleteTransaction('test_txn_99');
    state = container.read(transactionsProvider);
    expect(state.transactions.length, initialCount);
    expect(state.transactions.any((t) => t.id == 'test_txn_99'), false);
  });
}
