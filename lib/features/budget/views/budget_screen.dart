// ============================================================
// PocketDay — BudgetScreen
// ============================================================
//
// Purpose:
// Primary budget and subscriptions section view containing two internal tabs:
// Tab 0: Budget (monthly overall & category limits)
// Tab 1: Subscriptions (recurring payments tracker using SubscriptionsContent)
//
// Responsibilities:
// - Manage TabController for switching between Budget limits and Recurring Subscriptions.
// - Render top persistent month selector bar for active budget target month (YYYY-MM).
// - Render overall monthly summary card and category budget limits list.
// - Render SubscriptionsContent widget directly inside Tab 1 without nested Scaffolds or duplicate FABs.
// - Render dynamic parent Scaffold FloatingActionButton based on active tab index (Add Budget vs Add Subscription).
//
// Data Flow:
// Cloud Firestore → BudgetRepository & SubscriptionRepository → budgetProvider & subscriptionProvider → BudgetScreen UI
//
// Navigation Flow:
// AppMainNavigationScreen Tab 2 → BudgetScreen → Tab 0 (Budget) / Tab 1 (Subscriptions)
//
// Important Rules:
// - Default selected tab MUST be Tab 0 (Budget) every time the section is displayed.
// - Exactly ONE parent Scaffold FAB exists at a time; no nested Scaffolds or duplicate FABs.
//
// Main Operations:
// - build(context, ref) — Manages TabController and renders TabBarView with Budget view and SubscriptionsContent.
// - _openAddBudgetSheet() — Displays modal bottom sheet for creating/editing monthly budgets.
// - _openAddSubscriptionSheet() — Displays modal bottom sheet for creating recurring subscriptions.
//
// Dependencies / Collaborators:
// - budgetProvider — Riverpod state notifier owning monthly budgets and active month selection.
// - subscriptionProvider — Riverpod state notifier owning recurring subscriptions.
// - SubscriptionsContent — Reusable recurring subscription view widget.
// - AddBudgetBottomSheet — Modal bottom sheet for instantiating budgets.
// - AddSubscriptionSheet — Modal bottom sheet for instantiating subscriptions.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/budget_model.dart';
import '../../subscriptions/widgets/add_subscription_sheet.dart';
import '../../subscriptions/widgets/subscriptions_content.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_budget_bottom_sheet.dart';
import '../widgets/budget_card_widget.dart';
import '../widgets/budget_detail_bottom_sheet.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddBudgetSheet(BuildContext context, DateTime selectedMonth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBudgetBottomSheet(month: selectedMonth),
    );
  }

  void _openAddSubscriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSubscriptionSheet(),
    );
  }

  void _showDetailBottomSheet(BuildContext context, BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetDetailBottomSheet(budget: budget),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetProvider);
    final notifier = ref.read(budgetProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Subscriptions'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Budget'),
            Tab(text: 'Subscriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Budget Limits View
          _buildBudgetView(context, state, notifier, isDark),
          // Tab 1: Subscriptions View (Reusable widget, no nested Scaffold)
          const SubscriptionsContent(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              heroTag: 'fab_budget_tab',
              onPressed: () => _openAddBudgetSheet(context, state.selectedMonth),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : FloatingActionButton.extended(
              heroTag: 'fab_subscriptions_tab',
              onPressed: () => _openAddSubscriptionSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Subscription'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildBudgetView(
    BuildContext context,
    BudgetState state,
    BudgetNotifier notifier,
    bool isDark,
  ) {
    BudgetModel? overallBudget;
    try {
      overallBudget = state.currentBudgets.firstWhere(
        (b) => b.categoryId == null,
      );
    } catch (_) {
      overallBudget = null;
    }

    final categoryBudgets = state.currentBudgets
        .where((b) => b.categoryId != null)
        .toList();

    return Column(
      children: [
        // Persistent Month Selector
        _buildMonthSelector(context, state, notifier, isDark),

        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.currentBudgets.isEmpty
              ? _buildEmptyState(context, state.selectedMonth)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Overall Budget Summary Card
                    if (overallBudget != null) ...[
                      _buildSectionHeader(context, 'Monthly Summary', isDark),
                      BudgetCardWidget(
                        title: 'Overall Limit',
                        budgetAmount: overallBudget.amount,
                        spentAmount: state.categorySpending[null] ?? 0.0,
                        icon: Icons.all_inclusive_rounded,
                        iconColor: AppColors.primary,
                        onTap: () =>
                            _showDetailBottomSheet(context, overallBudget!),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildSectionHeader(context, 'Monthly Summary', isDark),
                      _buildAddOverallPrompt(
                        context,
                        state.selectedMonth,
                        isDark,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 2. Category Budgets Section
                    if (categoryBudgets.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Category Limits', isDark),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryBudgets.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final budget = categoryBudgets[index];
                          final spent =
                              state.categorySpending[budget.categoryId] ??
                              0.0;
                          final catMeta = AppConstants.defaultCategories
                              .firstWhere(
                                (c) => c['id'] == budget.categoryId,
                                orElse: () => {
                                  'icon': Icons.category_rounded,
                                  'color': AppColors.primary,
                                },
                              );
                          return BudgetCardWidget(
                            title: budget.categoryName ?? '',
                            budgetAmount: budget.amount,
                            spentAmount: spent,
                            icon: catMeta['icon'] as IconData,
                            iconColor: catMeta['color'] as Color,
                            onTap: () =>
                                _showDetailBottomSheet(context, budget),
                          );
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(
    BuildContext context,
    BudgetState state,
    BudgetNotifier notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              final prev = DateTime(
                state.selectedMonth.year,
                state.selectedMonth.month - 1,
                1,
              );
              notifier.setSelectedMonth(prev);
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(state.selectedMonth),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final next = DateTime(
                state.selectedMonth.year,
                state.selectedMonth.month + 1,
                1,
              );
              notifier.setSelectedMonth(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildAddOverallPrompt(
    BuildContext context,
    DateTime selectedMonth,
    bool isDark,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.all_inclusive_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No Overall Limit Set',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Set an overall monthly budget to track your complete spending pace and remain on target.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openAddBudgetSheet(context, selectedMonth),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Set Overall Budget'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DateTime selectedMonth) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateWidget(
              icon: Icons.pie_chart_rounded,
              title:
                  'No budget for ${DateFormat('MMMM').format(selectedMonth)}',
              description:
                  'Set spending limits for this month to monitor your category expenses.',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openAddBudgetSheet(context, selectedMonth),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set Monthly Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
