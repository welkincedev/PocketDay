// ============================================================================
// PocketDay
// File: transactions_provider.dart
// Purpose: Transaction filtering, search, sorting, and CRUD state management.
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';

enum TransactionSortBy { dateDesc, dateAsc, amountDesc, amountAsc }

class TransactionsState {
  final List<TransactionModel> transactions;
  final List<TransactionModel> filteredTransactions;
  final String searchQuery;
  final String? selectedCategoryId;
  final TransactionType? selectedType;
  final DateTimeRange? selectedDateRange;
  final String datePreset; // 'all', 'today', 'week', 'month', 'custom'
  final TransactionSortBy sortBy;
  final bool isLoading;
  final String? error;

  TransactionsState({
    this.transactions = const [],
    this.filteredTransactions = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedType,
    this.selectedDateRange,
    this.datePreset = 'all',
    this.sortBy = TransactionSortBy.dateDesc,
    this.isLoading = false,
    this.error,
  });

  TransactionsState copyWith({
    List<TransactionModel>? transactions,
    List<TransactionModel>? filteredTransactions,
    String? searchQuery,
    String? selectedCategoryId,
    TransactionType? selectedType,
    DateTimeRange? selectedDateRange,
    String? datePreset,
    TransactionSortBy? sortBy,
    bool? isLoading,
    String? error,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedType: selectedType ?? this.selectedType,
      selectedDateRange: selectedDateRange ?? this.selectedDateRange,
      datePreset: datePreset ?? this.datePreset,
      sortBy: sortBy ?? this.sortBy,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
      final repo = ref.watch(transactionRepositoryProvider);
      return TransactionsNotifier(repo);
    });

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionRepository _repo;

  TransactionsNotifier(this._repo) : super(TransactionsState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (state.transactions.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final txns = await _repo.getTransactions();
      state = state.copyWith(transactions: txns, isLoading: false);
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setSelectedCategory(String? categoryId) {
    state = TransactionsState(
      transactions: state.transactions,
      searchQuery: state.searchQuery,
      selectedCategoryId: categoryId,
      selectedType: state.selectedType,
      selectedDateRange: state.selectedDateRange,
      datePreset: state.datePreset,
      sortBy: state.sortBy,
      isLoading: state.isLoading,
      error: state.error,
    );
    _applyFilters();
  }

  void setSelectedType(TransactionType? type) {
    state = TransactionsState(
      transactions: state.transactions,
      searchQuery: state.searchQuery,
      selectedCategoryId: state.selectedCategoryId,
      selectedType: type,
      selectedDateRange: state.selectedDateRange,
      datePreset: state.datePreset,
      sortBy: state.sortBy,
      isLoading: state.isLoading,
      error: state.error,
    );
    _applyFilters();
  }

  void setSelectedDateRange(DateTimeRange? range) {
    state = TransactionsState(
      transactions: state.transactions,
      searchQuery: state.searchQuery,
      selectedCategoryId: state.selectedCategoryId,
      selectedType: state.selectedType,
      selectedDateRange: range,
      datePreset: range == null ? 'all' : 'custom',
      sortBy: state.sortBy,
      isLoading: state.isLoading,
      error: state.error,
    );
    _applyFilters();
  }

  void setDatePreset(String preset) {
    state = state.copyWith(datePreset: preset);
    if (preset == 'custom') {
      // Custom presets are handled by opening picker
    } else {
      final now = DateTime.now();
      DateTime start;
      DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      if (preset == 'today') {
        start = DateTime(now.year, now.month, now.day);
        state = TransactionsState(
          transactions: state.transactions,
          searchQuery: state.searchQuery,
          selectedCategoryId: state.selectedCategoryId,
          selectedType: state.selectedType,
          selectedDateRange: DateTimeRange(start: start, end: end),
          datePreset: 'today',
          sortBy: state.sortBy,
          isLoading: state.isLoading,
          error: state.error,
        );
      } else if (preset == 'week') {
        final weekday = now.weekday;
        final monday = now.subtract(Duration(days: weekday - 1));
        start = DateTime(monday.year, monday.month, monday.day);
        state = TransactionsState(
          transactions: state.transactions,
          searchQuery: state.searchQuery,
          selectedCategoryId: state.selectedCategoryId,
          selectedType: state.selectedType,
          selectedDateRange: DateTimeRange(start: start, end: end),
          datePreset: 'week',
          sortBy: state.sortBy,
          isLoading: state.isLoading,
          error: state.error,
        );
      } else if (preset == 'month') {
        start = DateTime(now.year, now.month, 1);
        state = TransactionsState(
          transactions: state.transactions,
          searchQuery: state.searchQuery,
          selectedCategoryId: state.selectedCategoryId,
          selectedType: state.selectedType,
          selectedDateRange: DateTimeRange(start: start, end: end),
          datePreset: 'month',
          sortBy: state.sortBy,
          isLoading: state.isLoading,
          error: state.error,
        );
      } else if (preset == 'all') {
        state = TransactionsState(
          transactions: state.transactions,
          searchQuery: state.searchQuery,
          selectedCategoryId: state.selectedCategoryId,
          selectedType: state.selectedType,
          selectedDateRange: null,
          datePreset: 'all',
          sortBy: state.sortBy,
          isLoading: state.isLoading,
          error: state.error,
        );
      }
      _applyFilters();
    }
  }

  void setSortBy(TransactionSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
    _applyFilters();
  }

  void resetFilters() {
    state = TransactionsState(
      transactions: state.transactions,
      searchQuery: '',
      selectedCategoryId: null,
      selectedType: null,
      selectedDateRange: null,
      datePreset: 'all',
      sortBy: TransactionSortBy.dateDesc,
      isLoading: state.isLoading,
      error: state.error,
    );
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<TransactionModel>.from(state.transactions);

    // 1. Search Query
    if (state.searchQuery.trim().isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      list = list.where((t) {
        return t.title.toLowerCase().contains(query) ||
            (t.notes?.toLowerCase().contains(query) ?? false) ||
            t.categoryName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Category
    if (state.selectedCategoryId != null) {
      list = list
          .where((t) => t.categoryId == state.selectedCategoryId)
          .toList();
    }

    // 3. Type (Income/Expense)
    if (state.selectedType != null) {
      list = list.where((t) => t.type == state.selectedType).toList();
    }

    // 4. Date Range
    if (state.selectedDateRange != null) {
      final range = state.selectedDateRange!;
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
        999,
      );
      list = list
          .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
          .toList();
    }

    // 5. Sorting
    switch (state.sortBy) {
      case TransactionSortBy.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionSortBy.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortBy.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortBy.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    state = state.copyWith(filteredTransactions: list);
  }

  Future<void> addTransaction(TransactionModel txn) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.addTransaction(txn);
      await loadTransactions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.updateTransaction(txn);
      await loadTransactions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteTransaction(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repo.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
