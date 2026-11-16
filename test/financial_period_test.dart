// ============================================================
// PocketDay — FinancialPeriod & Custom Financial Month Unit Tests
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketday/core/utils/financial_period.dart';
import 'package:pocketday/data/models/budget_model.dart';
import 'package:pocketday/data/models/transaction_model.dart';
import 'package:pocketday/data/repositories/budget_repository.dart';
import 'package:pocketday/data/repositories/transaction_repository.dart';
import 'package:pocketday/features/budget/providers/budget_provider.dart';
import 'package:pocketday/features/budget/providers/financial_month_provider.dart';
import 'package:pocketday/features/transactions/providers/transactions_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FinancialPeriod Calculation Unit Tests', () {
    test('Start Day 1 behaves exactly like a calendar month', () {
      final novDate = DateTime(2026, 11, 15, 14, 30);
      final period = FinancialPeriod.fromDateTime(
        novDate,
        startDay: 1,
        isCustom: false,
      );

      expect(period.startDate, DateTime(2026, 11, 1, 0, 0, 0, 0, 0));
      expect(period.endDate, DateTime(2026, 11, 30, 23, 59, 59, 999));
      expect(period.cycleYear, 2026);
      expect(period.cycleMonth, 11);
      expect(period.cycleKey, '2026-11');
      expect(period.displayLabel, 'November 2026');
      expect(period.isCustom, false);
    });

    test('Start Day 10 groups Nov 10 – Dec 9', () {
      final date = DateTime(2026, 11, 15);
      final period = FinancialPeriod.fromDateTime(
        date,
        startDay: 10,
        isCustom: true,
      );

      expect(period.startDate, DateTime(2026, 11, 10, 0, 0, 0, 0, 0));
      expect(period.endDate, DateTime(2026, 12, 9, 23, 59, 59, 999));
      expect(period.cycleYear, 2026);
      expect(period.cycleMonth, 11);
      expect(period.cycleKey, '2026-11');
      expect(period.displayLabel, 'Nov 10 – Dec 9, 2026');
      expect(period.previewLabel, 'November 10 – December 9, 2026');
      expect(period.isCustom, true);
    });

    test('Start Day 15 groups Oct 15 – Nov 14 for a date in that range', () {
      final date = DateTime(2026, 10, 20);
      final period = FinancialPeriod.fromDateTime(
        date,
        startDay: 15,
        isCustom: true,
      );

      expect(period.startDate, DateTime(2026, 10, 15, 0, 0, 0, 0, 0));
      expect(period.endDate, DateTime(2026, 11, 14, 23, 59, 59, 999));
      expect(period.cycleYear, 2026);
      expect(period.cycleMonth, 10);
      expect(period.cycleKey, '2026-10');
      expect(period.displayLabel, 'Oct 15 – Nov 14, 2026');
    });

    test('Current date is before start day: begins in previous month', () {
      // Today is Nov 5, start day is 10 -> belongs to October cycle (Oct 10 – Nov 9)
      final date = DateTime(2026, 11, 5, 10, 0);
      final period = FinancialPeriod.fromDateTime(
        date,
        startDay: 10,
        isCustom: true,
      );

      expect(period.startDate, DateTime(2026, 10, 10, 0, 0, 0, 0, 0));
      expect(period.endDate, DateTime(2026, 11, 9, 23, 59, 59, 999));
      expect(period.cycleYear, 2026);
      expect(period.cycleMonth, 10);
      expect(period.cycleKey, '2026-10');
      expect(period.contains(date), true);
    });

    test('Current date is exactly the start day: new period begins', () {
      // Nov 10 at midnight
      final date = DateTime(2026, 11, 10, 0, 0, 0);
      final period = FinancialPeriod.fromDateTime(
        date,
        startDay: 10,
        isCustom: true,
      );

      expect(period.startDate, DateTime(2026, 11, 10, 0, 0, 0, 0, 0));
      expect(period.endDate, DateTime(2026, 12, 9, 23, 59, 59, 999));
      expect(period.cycleYear, 2026);
      expect(period.cycleMonth, 11);
      expect(period.contains(date), true);
    });

    test('Current date is the last day of the calendar month', () {
      // Nov 30 with start day 10 -> belongs to Nov 10 - Dec 9 cycle
      final date = DateTime(2026, 11, 30, 23, 59);
      final period = FinancialPeriod.fromDateTime(
        date,
        startDay: 10,
        isCustom: true,
      );

      expect(period.startDate, DateTime(2026, 11, 10, 0, 0, 0, 0, 0));
      expect(period.endDate, DateTime(2026, 12, 9, 23, 59, 59, 999));
      expect(period.cycleYear, 2026);
      expect(period.cycleMonth, 11);
      expect(period.contains(date), true);
    });

    test('Year boundary transition (December -> January)', () {
      // Date in late December belongs to December cycle
      final decDate = DateTime(2026, 12, 15);
      final period = FinancialPeriod.fromDateTime(
        decDate,
        startDay: 10,
        isCustom: true,
      );

      expect(period.startDate, DateTime(2026, 12, 10, 0, 0, 0, 0, 0));
      expect(period.endDate, DateTime(2027, 1, 9, 23, 59, 59, 999));
      expect(period.cycleYear, 2026);
      expect(period.cycleMonth, 12);
      expect(period.displayLabel, 'Dec 10, 2026 – Jan 9, 2027');
      expect(period.previewLabel, 'December 10, 2026 – January 9, 2027');
      expect(period.contains(decDate), true);

      // Early January date (Jan 5, 2027) before the 10th still belongs to the December 2026 cycle!
      final janEarlyDate = DateTime(2027, 1, 5);
      final janEarlyPeriod = FinancialPeriod.fromDateTime(
        janEarlyDate,
        startDay: 10,
        isCustom: true,
      );
      expect(janEarlyPeriod, period);
      expect(janEarlyPeriod.cycleKey, '2026-12');
      expect(janEarlyPeriod.contains(janEarlyDate), true);
    });

    test('February in normal year and leap year', () {
      // 2024 is a leap year (Feb 29 days)
      final leapJanCycle = FinancialPeriod.fromCycle(
        2024,
        1,
        startDay: 30,
        isCustom: true,
      );
      expect(leapJanCycle.startDate, DateTime(2024, 1, 30));
      // In 2024, Feb has 29 days, so day 30 clamps to 29; cycle ends on Feb 28 23:59:59.999
      expect(leapJanCycle.endDate, DateTime(2024, 2, 28, 23, 59, 59, 999));

      // 2025 is not a leap year (Feb 28 days)
      final nonLeapJanCycle = FinancialPeriod.fromCycle(
        2025,
        1,
        startDay: 30,
        isCustom: true,
      );
      expect(nonLeapJanCycle.startDate, DateTime(2025, 1, 30));
      // In 2025, Feb has 28 days, day 30 clamps to 28; cycle ends on Feb 27 23:59:59.999
      expect(nonLeapJanCycle.endDate, DateTime(2025, 2, 27, 23, 59, 59, 999));
    });

    test('Inclusive start and end date filtering', () {
      final period = FinancialPeriod.fromCycle(
        2026,
        11,
        startDay: 10,
        isCustom: true,
      );

      // Exact start millisecond
      final exactStart = DateTime(2026, 11, 10, 0, 0, 0, 0);
      expect(period.contains(exactStart), true);

      // Exact end millisecond
      final exactEnd = DateTime(2026, 12, 9, 23, 59, 59, 999);
      expect(period.contains(exactEnd), true);

      // 1 millisecond before start
      final beforeStart = DateTime(2026, 11, 9, 23, 59, 59, 999);
      expect(period.contains(beforeStart), false);

      // 1 millisecond after end (exact start of next cycle)
      final afterEnd = DateTime(2026, 12, 10, 0, 0, 0, 0);
      expect(period.contains(afterEnd), false);
    });

    test('Previous and Next period chaining', () {
      final nov = FinancialPeriod.fromCycle(
        2026,
        11,
        startDay: 10,
        isCustom: true,
      );
      final oct = nov.previousPeriod();
      final dec = nov.nextPeriod();

      expect(oct.cycleKey, '2026-10');
      expect(oct.startDate, DateTime(2026, 10, 10));
      expect(oct.endDate, DateTime(2026, 11, 9, 23, 59, 59, 999));

      expect(dec.cycleKey, '2026-12');
      expect(dec.startDate, DateTime(2026, 12, 10));
      expect(dec.endDate, DateTime(2027, 1, 9, 23, 59, 59, 999));

      // Jan 2027 next from Dec 2026
      final jan = dec.nextPeriod();
      expect(jan.cycleKey, '2027-01');
      expect(jan.startDate, DateTime(2027, 1, 10));
      expect(jan.endDate, DateTime(2027, 2, 9, 23, 59, 59, 999));
    });
  });

  group('FinancialMonthNotifier State & Persistence Tests', () {
    test('Default state is calendar month (disabled, startDay 1)', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = FinancialMonthNotifier();
      await notifier.init();

      expect(notifier.state.isCustomEnabled, false);
      expect(notifier.state.startDay, 1);
    });

    test('Updating customEnabled and startDay persists to SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = FinancialMonthNotifier();
      await notifier.init();

      await notifier.setCustomEnabled(true);
      await notifier.setStartDay(10);

      expect(notifier.state.isCustomEnabled, true);
      expect(notifier.state.startDay, 10);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('financial_month_custom_enabled'), true);
      expect(prefs.getInt('financial_month_start_day'), 10);
    });

    test('Resetting financial month returns to calendar default', () async {
      SharedPreferences.setMockInitialValues({
        'financial_month_custom_enabled': true,
        'financial_month_start_day': 15,
      });
      final notifier = FinancialMonthNotifier();
      await notifier.init();
      expect(notifier.state.isCustomEnabled, true);
      expect(notifier.state.startDay, 15);

      await notifier.reset();
      expect(notifier.state.isCustomEnabled, false);
      expect(notifier.state.startDay, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('financial_month_custom_enabled'), null);
      expect(prefs.getInt('financial_month_start_day'), null);
    });
  });

  group('Budget Integration with Financial Month', () {
    test('Budget spending groups by pay-cycle when enabled', () async {
      SharedPreferences.setMockInitialValues({
        'financial_month_custom_enabled': true,
        'financial_month_start_day': 10,
      });

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            TransactionRepositoryImpl(),
          ),
          budgetRepositoryProvider.overrideWithValue(BudgetRepositoryImpl()),
        ],
      );

      // Load initial state
      await container.read(financialMonthProvider.notifier).init();
      container.read(budgetProvider.notifier).setSelectedMonth(DateTime(2026, 11, 1));

      // Create a budget for the November cycle
      final overallBudget = BudgetModel(
        id: 'b_cycle_nov',
        amount: 25000.0,
        month: '2026-11',
        categoryId: null,
        createdAt: DateTime(2026, 11, 10),
        updatedAt: DateTime(2026, 11, 10),
      );
      await container.read(budgetProvider.notifier).saveBudget(overallBudget);

      // Transaction A: Nov 5, 2026 (Before Nov 10 -> belongs to October cycle)
      final txnBefore = TransactionModel(
        id: 'txn_before',
        title: 'Early Nov Purchase',
        amount: 1500.0,
        type: TransactionType.expense,
        categoryId: 'shopping',
        categoryName: 'Shopping',
        date: DateTime(2026, 11, 5),
      );

      // Transaction B: Nov 15, 2026 (Inside Nov 10 - Dec 9 -> belongs to November cycle)
      final txnInside1 = TransactionModel(
        id: 'txn_inside1',
        title: 'Mid Nov Grocery',
        amount: 3200.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food & Dining',
        date: DateTime(2026, 11, 15),
      );

      // Transaction C: Dec 5, 2026 (Inside Nov 10 - Dec 9 -> belongs to November cycle)
      final txnInside2 = TransactionModel(
        id: 'txn_inside2',
        title: 'Early Dec Dinner',
        amount: 1800.0,
        type: TransactionType.expense,
        categoryId: 'food',
        categoryName: 'Food & Dining',
        date: DateTime(2026, 12, 5),
      );

      // Transaction D: Dec 12, 2026 (After Dec 9 -> belongs to December cycle)
      final txnAfter = TransactionModel(
        id: 'txn_after',
        title: 'Mid Dec Fuel',
        amount: 2000.0,
        type: TransactionType.expense,
        categoryId: 'transport',
        categoryName: 'Transportation',
        date: DateTime(2026, 12, 12),
      );

      await container.read(transactionsProvider.notifier).addTransaction(txnBefore);
      await container.read(transactionsProvider.notifier).addTransaction(txnInside1);
      await container.read(transactionsProvider.notifier).addTransaction(txnInside2);
      await container.read(transactionsProvider.notifier).addTransaction(txnAfter);

      final state = container.read(budgetProvider);

      // Active period for November cycle with start day 10 must be Nov 10 – Dec 9, 2026
      expect(state.activePeriod.startDate, DateTime(2026, 11, 10));
      expect(state.activePeriod.endDate, DateTime(2026, 12, 9, 23, 59, 59, 999));
      expect(state.activePeriod.displayLabel, 'Nov 10 – Dec 9, 2026');

      // Overall spent must include txnInside1 (3200) + txnInside2 (1800) = 5000.0
      // It must EXCLUDE txnBefore (Nov 5) and txnAfter (Dec 12)!
      final totalSpent = state.categorySpending[null] ?? 0.0;
      expect(totalSpent, 5000.0);

      // Food category spending must be 3200 + 1800 = 5000.0
      final foodSpent = state.categorySpending['food'] ?? 0.0;
      expect(foodSpent, 5000.0);
    });

    test('Switching between custom cycle and calendar month dynamically updates spending',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            TransactionRepositoryImpl(),
          ),
          budgetRepositoryProvider.overrideWithValue(BudgetRepositoryImpl()),
        ],
      );

      await container.read(financialMonthProvider.notifier).init();
      container.read(budgetProvider.notifier).setSelectedMonth(DateTime(2026, 11, 1));

      // Nov 5 (inside calendar Nov, outside Nov 10-Dec 9 cycle)
      final txnNov5 = TransactionModel(
        id: 't_nov5',
        title: 'Nov 5 bill',
        amount: 1000.0,
        type: TransactionType.expense,
        categoryId: 'bills',
        categoryName: 'Bills & Utilities',
        date: DateTime(2026, 11, 5),
      );

      // Dec 5 (outside calendar Nov, inside Nov 10-Dec 9 cycle)
      final txnDec5 = TransactionModel(
        id: 't_dec5',
        title: 'Dec 5 bill',
        amount: 2500.0,
        type: TransactionType.expense,
        categoryId: 'bills',
        categoryName: 'Bills & Utilities',
        date: DateTime(2026, 12, 5),
      );

      await container.read(transactionsProvider.notifier).addTransaction(txnNov5);
      await container.read(transactionsProvider.notifier).addTransaction(txnDec5);

      // Phase 1: Calendar month active (1st to 30th)
      var budgetState = container.read(budgetProvider);
      expect(budgetState.activePeriod.isCustom, false);
      expect(budgetState.activePeriod.displayLabel, 'November 2026');
      // Only Nov 5 is in November calendar month (1000.0)
      expect(budgetState.categorySpending[null], 1000.0);

      // Phase 2: User enables custom financial month with start day 10
      await container.read(financialMonthProvider.notifier).setCustomEnabled(true);
      await container.read(financialMonthProvider.notifier).setStartDay(10);

      budgetState = container.read(budgetProvider);
      expect(budgetState.activePeriod.isCustom, true);
      expect(budgetState.activePeriod.displayLabel, 'Nov 10 – Dec 9, 2026');
      // In Nov 10 - Dec 9 cycle: Dec 5 is included (2500.0), Nov 5 is excluded!
      expect(budgetState.categorySpending[null], 2500.0);

      // Phase 3: User returns to calendar month
      await container.read(financialMonthProvider.notifier).setCustomEnabled(false);
      budgetState = container.read(budgetProvider);
      expect(budgetState.activePeriod.isCustom, false);
      expect(budgetState.activePeriod.displayLabel, 'November 2026');
      expect(budgetState.categorySpending[null], 1000.0);
    });
  });
}
