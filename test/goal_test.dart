import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pocketday/core/constants/app_constants.dart';
import 'package:pocketday/data/models/goal_model.dart';
import 'package:pocketday/data/models/transaction_model.dart';
import 'package:pocketday/data/repositories/goal_repository.dart';
import 'package:pocketday/features/goals/providers/goals_provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pocketday_goals_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.transactionsBox);
    await Hive.openBox(AppConstants.goalsBox);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ─── GOAL MODEL TESTS ───

  group('GoalModel calculations', () {
    final baseGoal = GoalModel(
      id: 'g_test',
      name: 'Trip to Goa',
      targetAmount: 25000.0,
      emoji: '✈️',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    List<TransactionModel> makeTxns(List<Map<String, dynamic>> data) {
      return data.map((d) => TransactionModel(
        id: d['id'] ?? 'txn_${d.hashCode}',
        title: d['title'] ?? 'Test',
        amount: (d['amount'] as num).toDouble(),
        type: d['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        categoryId: d['categoryId'] ?? (d['type'] == 'income' ? 'goal_contribution' : 'food'),
        categoryName: d['categoryName'] ?? 'Test',
        date: DateTime.now(),
        goalId: d['goalId'],
      )).toList();
    }

    test('0% progress with no transactions', () {
      final txns = <TransactionModel>[];
      expect(baseGoal.calculateCurrentAmount(txns), 0.0);
      expect(baseGoal.calculateProgress(0.0), 0.0);
      expect(baseGoal.calculatePercentage(0.0), 0.0);
      expect(baseGoal.isGoalCompleted(0.0), false);
    });

    test('56% progress with contributions and expenses', () {
      final txns = makeTxns([
        {'id': 't1', 'amount': 10000, 'type': 'income', 'categoryId': 'goal_contribution', 'goalId': 'g_test'},
        {'id': 't2', 'amount': 10000, 'type': 'income', 'categoryId': 'goal_contribution', 'goalId': 'g_test'},
        {'id': 't3', 'amount': 4000, 'type': 'expense', 'categoryId': 'food', 'goalId': 'g_test'},
        {'id': 't4', 'amount': 2000, 'type': 'expense', 'categoryId': 'transport', 'goalId': 'g_test'},
      ]);
      final current = baseGoal.calculateCurrentAmount(txns);
      expect(current, 14000.0); // 10k + 10k - 4k - 2k
      expect(baseGoal.calculateProgress(current), closeTo(0.56, 0.001));
      expect(baseGoal.calculatePercentage(current), closeTo(56.0, 0.1));
      expect(baseGoal.isGoalCompleted(current), false);
    });

    test('100% progress when current == target', () {
      final txns = makeTxns([
        {'id': 't1', 'amount': 25000, 'type': 'income', 'categoryId': 'goal_contribution', 'goalId': 'g_test'},
      ]);
      final current = baseGoal.calculateCurrentAmount(txns);
      expect(current, 25000.0);
      expect(baseGoal.calculateProgress(current), 1.0);
      expect(baseGoal.isGoalCompleted(current), true);
    });

    test('Progress clamped to 1.0 when above target', () {
      final txns = makeTxns([
        {'id': 't1', 'amount': 27000, 'type': 'income', 'categoryId': 'goal_contribution', 'goalId': 'g_test'},
      ]);
      final current = baseGoal.calculateCurrentAmount(txns);
      expect(current, 27000.0);
      expect(baseGoal.calculateProgress(current), 1.0); // clamped
      expect(baseGoal.calculatePercentage(current), closeTo(108.0, 0.1)); // real %
      expect(baseGoal.isGoalCompleted(current), true);
    });

    test('Unlinked transactions do not affect goal balance', () {
      final txns = makeTxns([
        {'id': 't1', 'amount': 5000, 'type': 'income', 'categoryId': 'goal_contribution', 'goalId': 'g_test'},
        // unrelated transaction with no goalId
        {'id': 't2', 'amount': 3000, 'type': 'expense', 'categoryId': 'food', 'goalId': null},
      ]);
      final current = baseGoal.calculateCurrentAmount(txns);
      expect(current, 5000.0); // only the linked contribution counts
    });

    test('Remaining amount is correct', () {
      final current = 14000.0;
      expect(baseGoal.calculateRemainingAmount(current), 11000.0);
    });

    test('Remaining amount is 0 when above target (no negative)', () {
      final current = 30000.0;
      expect(baseGoal.calculateRemainingAmount(current), 0.0);
    });

    test('No double counting — expense adds to total expenses AND deducts from goal', () {
      final allTxns = makeTxns([
        {'id': 't1', 'amount': 20000, 'type': 'income', 'categoryId': 'goal_contribution', 'goalId': 'g_test'},
        {'id': 't2', 'amount': 4000, 'type': 'expense', 'categoryId': 'food', 'goalId': 'g_test'},
        {'id': 't3', 'amount': 5000, 'type': 'expense', 'categoryId': 'food', 'goalId': null},
      ]);

      final goalCurrent = baseGoal.calculateCurrentAmount(allTxns);
      expect(goalCurrent, 16000.0); // 20000 - 4000

      // Total expenses = t2 + t3 (both are regular expenses)
      final totalExpenses = allTxns
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      expect(totalExpenses, 9000.0); // 4000 + 5000 — not double counted
    });
  });

  // ─── CRUD TESTS ───

  group('Goal CRUD', () {
    test('Create, read, update, delete goal', () async {
      final container = ProviderContainer(
        overrides: [goalRepositoryProvider.overrideWithValue(GoalRepositoryImpl())],
      );

      // Create
      await container.read(goalsProvider.notifier).addGoal(
        name: 'Emergency Fund',
        targetAmount: 50000.0,
        emoji: '🛟',
        targetDate: DateTime(2027, 1, 1),
      );

      var state = container.read(goalsProvider);
      expect(state.goals.length, 1);
      final goal = state.goals.first;
      expect(goal.name, 'Emergency Fund');
      expect(goal.targetAmount, 50000.0);
      expect(goal.emoji, '🛟');

      // Update
      final updated = goal.copyWith(name: 'Emergency Savings', targetAmount: 75000.0);
      await container.read(goalsProvider.notifier).updateGoal(updated);

      state = container.read(goalsProvider);
      expect(state.goals.first.name, 'Emergency Savings');
      expect(state.goals.first.targetAmount, 75000.0);

      // Delete
      await container.read(goalsProvider.notifier).deleteGoal(goal.id);
      state = container.read(goalsProvider);
      expect(state.goals.isEmpty, true);
    });
  });
}
