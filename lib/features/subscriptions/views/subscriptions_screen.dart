// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: subscriptions_screen.dart
//
// Purpose:
// Main subscriptions management view screen with summary metrics, filter bar, and grid/list layout.
//
// Responsibilities:
// - Render top normalized monthly recurring spend card (`totalMonthlyRecurring`).
// - Render horizontal upcoming payments carousel (`upcomingList`).
// - Filter by status (All, Active, Paused, Cancelled) and live text search query.
// - Render list of `SubscriptionCard` items, dynamically switching to a 2-column grid on wide screens.
//
// Data Flow:
// subscriptionProvider → SubscriptionsScreen → SubscriptionCard / AddSubscriptionSheet
//
// Important Rules:
// - Adaptable layout uses `SliverGrid` with 2 columns when container width >= 600px.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import '../widgets/add_subscription_sheet.dart';
import '../widgets/subscription_card.dart';

/// # Developer Notes
///
/// Subscriptions feature screen for PocketDay (Phase 7).
///
/// Displays digital subscription cards, top summary of recurring spending,
/// upcoming billing section, search & filter controls, and responsive grid layout.
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddSheet(BuildContext context, [SubscriptionModel? toEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSubscriptionSheet(subscriptionToEdit: toEdit),
    );
  }

  void _confirmDelete(BuildContext context, SubscriptionModel sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        title: Text('Delete ${sub.name}?'),
        content: const Text(
          'This will remove the subscription from your PocketDay recurring tracker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(subscriptionProvider.notifier)
                  .deleteSubscription(sub.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(subscriptionProvider);
    final filtered = state.filteredSubscriptions;
    final activeCount = state.activeSubscriptions.length;
    final totalMonthly = state.totalMonthlyRecurring;
    final upcomingList = state.upcomingPayments;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search subscriptions...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(subscriptionProvider.notifier).setSearchQuery(val);
                },
              )
            : const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
            ),
            tooltip: 'Search',
            onPressed: () {
              setState(() {
                if (_showSearch) {
                  _showSearch = false;
                  _searchController.clear();
                  ref.read(subscriptionProvider.notifier).setSearchQuery('');
                } else {
                  _showSearch = true;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort by',
            onSelected: (val) {
              ref.read(subscriptionProvider.notifier).setSortBy(val);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'next_payment',
                child: Text('Next Payment Date'),
              ),
              const PopupMenuItem(
                value: 'amount_desc',
                child: Text('Amount (High to Low)'),
              ),
              const PopupMenuItem(
                value: 'amount_asc',
                child: Text('Amount (Low to High)'),
              ),
              const PopupMenuItem(value: 'name', child: Text('Name (A-Z)')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(subscriptionProvider.notifier).loadSubscriptions();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ─── Summary Header Card ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ]
                                : [
                                    const Color(0xFF0F766E),
                                    const Color(0xFF14B8A6),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.black : AppColors.primary)
                                  .withAlpha(30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'MONTHLY RECURRING SPEND',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withAlpha(190),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$activeCount active',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${CurrencyFormatter.format(totalMonthly)} / mo',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Normalized active recurring payments',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(210),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Status Filter Chips ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              'all',
                              'All (${state.subscriptions.length})',
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip('active', 'Active ($activeCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'paused',
                              'Paused (${state.subscriptions.where((s) => s.status == SubscriptionStatus.paused).length})',
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'cancelled',
                              'Cancelled (${state.subscriptions.where((s) => s.status == SubscriptionStatus.cancelled).length})',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Upcoming Payments Section (if any upcoming active) ───
                  if (upcomingList.isNotEmpty &&
                      state.statusFilter == 'all' &&
                      state.searchQuery.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Text(
                          'UPCOMING PAYMENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 96,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: upcomingList.length,
                          itemBuilder: (context, index) {
                            final sub = upcomingList[index];
                            final diff = sub.nextPaymentDate
                                .difference(DateTime.now())
                                .inDays;
                            String dueText;
                            if (diff < 0) {
                              dueText = 'Overdue';
                            } else if (diff == 0) {
                              dueText = 'Due Today';
                            } else if (diff == 1) {
                              dueText = 'Tomorrow';
                            } else {
                              dueText = 'In $diff days';
                            }

                            return Container(
                              width: 160,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      sub.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.format(sub.amount),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.alarm_rounded,
                                          size: 12,
                                          color: diff <= 3
                                              ? AppColors.expense
                                              : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dueText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: diff <= 3
                                                ? AppColors.expense
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],

                  // ─── Subscriptions List Header ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ALL SUBSCRIPTION CARDS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${filtered.length} items',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Cards Container ───
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 48,
                          horizontal: 20,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.subscriptions_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              state.searchQuery.isNotEmpty ||
                                      state.statusFilter != 'all'
                                  ? 'No subscriptions match your filter.'
                                  : 'No subscriptions tracked yet.',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keep track of recurring payments like Netflix, Spotify, or Gym quietly leaving your wallet.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _openAddSheet(context),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add First Subscription'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isWide)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 210,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final sub = filtered[index];
                          return SubscriptionCard(
                            key: ValueKey(sub.id),
                            subscription: sub,
                            onEdit: () => _openAddSheet(context, sub),
                            onDelete: () => _confirmDelete(context, sub),
                          );
                        }, childCount: filtered.length),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final sub = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SubscriptionCard(
                              key: ValueKey(sub.id),
                              subscription: sub,
                              onEdit: () => _openAddSheet(context, sub),
                              onDelete: () => _confirmDelete(context, sub),
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_subscriptions_screen',
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Subscription'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final current = ref.watch(subscriptionProvider).statusFilter;
    final selected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: selected ? FontWeight.bold : null,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          ref.read(subscriptionProvider.notifier).setStatusFilter(value);
        }
      },
    );
  }
}
