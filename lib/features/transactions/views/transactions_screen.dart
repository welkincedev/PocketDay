// ============================================================
// PocketDay — TransactionsScreen
// ============================================================
//
// Purpose:
// Primary financial transactions history view providing full-text search, category/type filtering,
// date-based grouping, transaction detail viewing, editing, and deletion.
//
// Responsibilities:
// - Render complete transaction feed sorted descending by date.
// - Render real-time search input bar for title/category/notes searching.
// - Render type filter tabs (All, Income, Expenses) and category filter bottom sheet launcher.
// - Open AddTransactionBottomSheet for creating new transactions via floating action button.
// - Open TransactionDetailBottomSheet for viewing, editing, or deleting existing transactions.
//
// Data Flow:
// Cloud Firestore → TransactionRepository → transactionsProvider → TransactionsScreen UI → Item Details / Filters
//
// Navigation Flow:
// AppMainNavigationScreen Tab 1 → TransactionsScreen → TransactionDetailBottomSheet / AddTransactionBottomSheet
//
// Important Rules:
// - All transaction modifications (add/edit/delete) write to Cloud Firestore via TransactionRepository and pop sheet immediately.
// - Empty states render clean illustrations when no transactions match active search or filter criteria.
//
// Main Operations:
// - build(context, ref) — Listens to transactionsProvider state and renders search bar, filters, and transaction list.
//
// Dependencies / Collaborators:
// - transactionsProvider — Riverpod provider owning transaction list, search query, and category filters.
// - TransactionItemTile — ListItem widget rendering single transaction details.
// - TransactionDetailBottomSheet — Detail sheet for transaction inspection and deletion.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/transaction_model.dart';
import '../../dashboard/widgets/add_transaction_bottom_sheet.dart';
import '../../dashboard/widgets/transaction_item_tile.dart';
import '../providers/transactions_provider.dart';
import '../widgets/transaction_detail_bottom_sheet.dart';
import '../widgets/transactions_filter_bottom_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetailBottomSheet(BuildContext context, TransactionModel txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailBottomSheet(transaction: txn),
    );
  }

  void _openAddTransactionFlow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Add Transaction',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.income,
                    ),
                  ),
                  title: const Text(
                    'Add Income',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Salary, Freelance, Investment, etc.'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAddTransactionSheet(context, TransactionType.income);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                  title: const Text(
                    'Add Expense',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Food, Shopping, Bills, Travel, etc.'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openAddTransactionSheet(context, TransactionType.expense);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAddTransactionSheet(BuildContext context, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(
        initialType: type,
        onAdd: (txn) {
          ref.read(transactionsProvider.notifier).updateTransaction(txn);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasActiveFilters =
        state.selectedCategoryId != null ||
        state.selectedType != null ||
        state.selectedDateRange != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navTransactions),
        elevation: 0,
        actions: [
          if (hasActiveFilters || _searchController.text.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                ref.read(transactionsProvider.notifier).resetFilters();
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  color: AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
            ),
            child: Row(
              children: [
                // Search Input Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref
                            .read(transactionsProvider.notifier)
                            .setSearchQuery(val);
                      },
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(transactionsProvider.notifier)
                                      .setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Filter Button
                Material(
                  color: hasActiveFilters
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            const TransactionsFilterBottomSheet(),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasActiveFilters
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: hasActiveFilters
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transactions Scroll Feed (Complete history list, no limit of 5)
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredTransactions.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      icon:
                          (hasActiveFilters ||
                              _searchController.text.isNotEmpty)
                          ? Icons.search_off_rounded
                          : Icons.receipt_long_rounded,
                      title:
                          (hasActiveFilters ||
                              _searchController.text.isNotEmpty)
                          ? 'No matches'
                          : AppStrings.noTransactionsYet,
                      description:
                          (hasActiveFilters ||
                              _searchController.text.isNotEmpty)
                          ? 'No transactions found with the active filters.'
                          : 'Your transactions will be listed here.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: state.filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final txn = state.filteredTransactions[index];
                      return TransactionItemTile(
                        transaction: txn,
                        onTap: () => _showDetailBottomSheet(context, txn),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransactionFlow(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
