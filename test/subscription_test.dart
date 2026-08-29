import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pocketday/core/constants/app_constants.dart';
import 'package:pocketday/data/models/subscription_model.dart';
import 'package:pocketday/data/repositories/subscription_repository.dart';
import 'package:pocketday/data/repositories/transaction_repository.dart';
import 'package:pocketday/features/subscriptions/providers/subscription_provider.dart';
import 'package:pocketday/features/transactions/providers/transactions_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pocketday_phase7_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.transactionsBox);
    await Hive.openBox(AppConstants.budgetBox);
    await Hive.openBox(AppConstants.goalsBox);
    await Hive.openBox(AppConstants.subscriptionsBox);
    await Hive.openBox(AppConstants.processedAutoExpensesBox);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('SubscriptionModel Normalization & Date Edge Cases', () {
    test('Monthly equivalent calculation works for all billing cycles', () {
      final weekly = SubscriptionModel(
        id: 's1',
        name: 'News',
        amount: 199.0,
        billingCycle: SubscriptionBillingCycle.weekly,
        nextPaymentDate: DateTime.now(),
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // (199 * 52) / 12 = 862.3333...
      expect(weekly.calculateMonthlyEquivalent(), closeTo(862.33, 0.1));

      final monthly = SubscriptionModel(
        id: 's2',
        name: 'Netflix',
        amount: 649.0,
        billingCycle: SubscriptionBillingCycle.monthly,
        nextPaymentDate: DateTime.now(),
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(monthly.calculateMonthlyEquivalent(), 649.0);

      final quarterly = SubscriptionModel(
        id: 's3',
        name: 'Magazine',
        amount: 900.0,
        billingCycle: SubscriptionBillingCycle.quarterly,
        nextPaymentDate: DateTime.now(),
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(quarterly.calculateMonthlyEquivalent(), 300.0);

      final yearly = SubscriptionModel(
        id: 's4',
        name: 'Amazon Prime',
        amount: 1200.0,
        billingCycle: SubscriptionBillingCycle.yearly,
        nextPaymentDate: DateTime.now(),
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(yearly.calculateMonthlyEquivalent(), 100.0);
    });

    test(
      'Safe next payment date calculation handles month-end & leap years correctly',
      () {
        // 31 Jan 2025 + 1 month -> 28 Feb 2025
        final jan31 = DateTime(2025, 1, 31);
        final nextMonthly = SubscriptionModel.calculateNextDate(
          jan31,
          SubscriptionBillingCycle.monthly,
        );
        expect(nextMonthly.year, 2025);
        expect(nextMonthly.month, 2);
        expect(nextMonthly.day, 28);

        // 29 Feb 2024 (leap year) + 1 year -> 28 Feb 2025
        final feb29Leap = DateTime(2024, 2, 29);
        final nextYearlyLeap = SubscriptionModel.calculateNextDate(
          feb29Leap,
          SubscriptionBillingCycle.yearly,
        );
        expect(nextYearlyLeap.year, 2025);
        expect(nextYearlyLeap.month, 2);
        expect(nextYearlyLeap.day, 28);

        // 30 April + 1 month -> 30 May
        final apr30 = DateTime(2025, 4, 30);
        final nextMay = SubscriptionModel.calculateNextDate(
          apr30,
          SubscriptionBillingCycle.monthly,
        );
        expect(nextMay.month, 5);
        expect(nextMay.day, 30);
      },
    );

    test(
      'Date-aware status calculation returns correct active/expired detail',
      () {
        final refDate = DateTime(2026, 8, 29, 10, 0);
        final activeSub = SubscriptionModel(
          id: 's_act',
          name: 'Spotify',
          amount: 119.0,
          billingCycle: SubscriptionBillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 9, 10, 10, 0),
          startDate: DateTime(2026, 8, 10, 10, 0),
          status: SubscriptionStatus.active,
          createdAt: refDate,
          updatedAt: refDate,
        );
        expect(activeSub.isCurrentlyActive(refDate), true);
        expect(activeSub.calculateStatusDetail(refDate), 'Renews in 12 days');

        final expiredSub = SubscriptionModel(
          id: 's_exp',
          name: 'Old Gym',
          amount: 1500.0,
          billingCycle: SubscriptionBillingCycle.monthly,
          nextPaymentDate: DateTime(2026, 8, 24, 10, 0),
          startDate: DateTime(2026, 7, 24, 10, 0),
          status: SubscriptionStatus.active,
          createdAt: refDate,
          updatedAt: refDate,
        );
        expect(expiredSub.isCurrentlyActive(refDate), false);
        expect(expiredSub.calculateStatusDetail(refDate), 'Expired');
      },
    );
  });

  group('Subscription Automatic Expense & Idempotency Tests', () {
    test('Automatic expense OFF does NOT create transactions', () async {
      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            SubscriptionRepositoryImpl(),
          ),
          transactionRepositoryProvider.overrideWithValue(
            TransactionRepositoryImpl(),
          ),
        ],
      );

      final notifier = container.read(subscriptionProvider.notifier);

      await notifier.addSubscription(
        name: 'Manual Netflix',
        amount: 649.0,
        billingCycle: SubscriptionBillingCycle.monthly,
        nextPaymentDate: DateTime.now(),
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        category: 'Entertainment',
        paymentMethod: 'UPI',
        status: SubscriptionStatus.active,
        autoRecordExpense: false, // OFF
      );

      notifier.processAutoExpenses();

      final txns = container.read(transactionsProvider).transactions;
      expect(
        txns.where((t) => t.title.contains('Manual Netflix')).isEmpty,
        true,
      );
    });

    test(
      'Automatic expense ON creates exactly ONE transaction and is idempotent across restarts',
      () async {
        final container = ProviderContainer(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(
              SubscriptionRepositoryImpl(),
            ),
            transactionRepositoryProvider.overrideWithValue(
              TransactionRepositoryImpl(),
            ),
          ],
        );

        final notifier = container.read(subscriptionProvider.notifier);

        await notifier.addSubscription(
          name: 'Auto Spotify',
          amount: 119.0,
          billingCycle: SubscriptionBillingCycle.monthly,
          nextPaymentDate: DateTime.now(),
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          category: 'Entertainment',
          paymentMethod: 'UPI',
          status: SubscriptionStatus.active,
          autoRecordExpense: true, // ON
        );

        notifier.processAutoExpenses();

        var txns = container.read(transactionsProvider).transactions;
        final autoTxns = txns
            .where((t) => t.title == 'Auto Spotify Payment')
            .toList();
        expect(autoTxns.length, 1);
        expect(autoTxns.first.amount, 119.0);

        // Re-triggering processAutoExpenses or reloading should produce ZERO additional transactions
        notifier.processAutoExpenses();
        notifier.processAutoExpenses();

        txns = container.read(transactionsProvider).transactions;
        expect(txns.where((t) => t.title == 'Auto Spotify Payment').length, 1);
      },
    );
  });

  group('Subscription CRUD & Filtering', () {
    test('Add, search, filter, and delete subscriptions', () async {
      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            SubscriptionRepositoryImpl(),
          ),
          transactionRepositoryProvider.overrideWithValue(
            TransactionRepositoryImpl(),
          ),
        ],
      );

      final notifier = container.read(subscriptionProvider.notifier);

      await notifier.addSubscription(
        name: 'Netflix',
        amount: 649.0,
        billingCycle: SubscriptionBillingCycle.monthly,
        nextPaymentDate: DateTime.now().add(const Duration(days: 10)),
        startDate: DateTime.now(),
        category: 'Entertainment',
        paymentMethod: 'UPI',
        status: SubscriptionStatus.active,
      );

      var state = container.read(subscriptionProvider);
      expect(state.subscriptions.length, 1);

      notifier.setSearchQuery('Netflix');
      expect(
        container.read(subscriptionProvider).filteredSubscriptions.length,
        1,
      );

      notifier.setSearchQuery('Gym');
      expect(
        container.read(subscriptionProvider).filteredSubscriptions.length,
        0,
      );

      notifier.setSearchQuery('');
      final sub = state.subscriptions.first;
      await notifier.deleteSubscription(sub.id);

      state = container.read(subscriptionProvider);
      expect(state.subscriptions.isEmpty, true);
    });
  });
}
