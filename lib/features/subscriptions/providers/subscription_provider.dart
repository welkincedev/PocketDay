// ============================================================================
// PocketDay
// File: subscription_provider.dart
// Purpose: Subscriptions state notifier managing recurring expense trackers & auto-recording.
// Architecture: Presentation / State Management Layer
// State Management: Riverpod
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../transactions/providers/transactions_provider.dart';

/// Immutable state container for the Subscriptions feature.
class SubscriptionState {
  final List<SubscriptionModel> subscriptions;
  final String searchQuery;
  final String statusFilter; // 'all', 'active', 'paused', 'cancelled'
  final String sortBy; // 'next_payment', 'amount_desc', 'amount_asc', 'name'
  final bool isLoading;
  final String? error;

  SubscriptionState({
    this.subscriptions = const [],
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.sortBy = 'next_payment',
    this.isLoading = false,
    this.error,
  });

  SubscriptionState copyWith({
    List<SubscriptionModel>? subscriptions,
    String? searchQuery,
    String? statusFilter,
    String? sortBy,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sortBy: sortBy ?? this.sortBy,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Active subscriptions only (evaluated dynamically).
  List<SubscriptionModel> get activeSubscriptions =>
      subscriptions.where((s) => s.isCurrentlyActive()).toList();

  /// Total normalized monthly recurring cost for active subscriptions.
  double get totalMonthlyRecurring {
    return activeSubscriptions.fold(
      0.0,
      (sum, s) => sum + s.calculateMonthlyEquivalent(),
    );
  }

  /// Active subscriptions sorted by next payment date ascending.
  List<SubscriptionModel> get upcomingPayments {
    final list = List<SubscriptionModel>.from(activeSubscriptions);
    list.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return list;
  }

  /// Subscriptions filtered by search query and status filter, sorted by [sortBy].
  List<SubscriptionModel> get filteredSubscriptions {
    var result = List<SubscriptionModel>.from(subscriptions);

    // Apply status filter
    if (statusFilter != 'all') {
      if (statusFilter == 'active') {
        result = result.where((s) => s.isCurrentlyActive()).toList();
      } else {
        result = result.where((s) => s.status.name == statusFilter).toList();
      }
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((s) {
        final nameMatch = s.name.toLowerCase().contains(q);
        final categoryMatch = s.category.toLowerCase().contains(q);
        final methodMatch = s.paymentMethod.toLowerCase().contains(q);
        return nameMatch || categoryMatch || methodMatch;
      }).toList();
    }

    // Apply sorting
    switch (sortBy) {
      case 'next_payment':
        result.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
        break;
      case 'amount_desc':
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'name':
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return result;
  }
}

/// Riverpod provider for subscription state.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      final repo = ref.watch(subscriptionRepositoryProvider);
      return SubscriptionNotifier(repo, ref);
    });

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionRepository _repo;
  final Ref _ref;
  final Set<String> _processedAutoKeys = {};

  SubscriptionNotifier(this._repo, this._ref) : super(SubscriptionState()) {
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    if (state.subscriptions.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final list = await _repo.getSubscriptions();
      state = state.copyWith(subscriptions: list, isLoading: false);
      await processAutoExpenses();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Load Subscriptions', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't load your subscriptions. Please try again.",
        ),
      );
    }
  }

  Future<void> processAutoExpenses() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var sub in state.subscriptions) {
      if (!sub.autoRecordExpense) continue;
      if (!sub.isCurrentlyActive(now)) continue;

      final due = DateTime(
        sub.nextPaymentDate.year,
        sub.nextPaymentDate.month,
        sub.nextPaymentDate.day,
      );

      final diffDays = due.difference(today).inDays;
      if (diffDays <= 0) {
        final periodKey = '${due.year}_${due.month}_${due.day}';
        final autoKey = 'auto_exp_${sub.id}_$periodKey';

        if (!_processedAutoKeys.contains(autoKey)) {
          _processedAutoKeys.add(autoKey);

          final txn = TransactionModel(
            id: 'txn_auto_${sub.id}_$periodKey',
            title: '${sub.name} Payment',
            amount: sub.amount,
            type: TransactionType.expense,
            categoryId: 'bills',
            categoryName: 'Bills & Utilities',
            date: now,
            notes: 'Automatic subscription payment for ${sub.name}',
          );

          await _ref.read(transactionsProvider.notifier).updateTransaction(txn);
        }
      }
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  Future<void> addSubscription({
    required String name,
    required double amount,
    required SubscriptionBillingCycle billingCycle,
    required DateTime nextPaymentDate,
    required DateTime startDate,
    required String category,
    required String paymentMethod,
    required SubscriptionStatus status,
    bool autoRecordExpense = false,
    String? notes,
  }) async {
    final now = DateTime.now();
    final model = SubscriptionModel(
      id: 'sub_${now.millisecondsSinceEpoch}',
      name: name.trim(),
      amount: amount,
      billingCycle: billingCycle,
      nextPaymentDate: nextPaymentDate,
      startDate: startDate,
      category: category,
      paymentMethod: paymentMethod,
      status: status,
      autoRecordExpense: autoRecordExpense,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repo.saveSubscription(model);
      await loadSubscriptions();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Add Subscription', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't save this subscription. Please try again.",
        ),
      );
    }
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    final updated = subscription.copyWith(updatedAt: DateTime.now());
    try {
      await _repo.saveSubscription(updated);
      await loadSubscriptions();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Update Subscription', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't save this subscription. Please try again.",
        ),
      );
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _repo.deleteSubscription(id);
      await loadSubscriptions();
    } catch (e, stackTrace) {
      AppErrorHandler.logError('Delete Subscription', e, stackTrace);
      state = state.copyWith(
        error: AppErrorHandler.toUserMessage(
          e,
          defaultMessage: "Couldn't delete this subscription. Please try again.",
        ),
      );
    }
  }
}
