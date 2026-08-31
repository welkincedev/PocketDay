// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: goal_test.dart
//
// Purpose:
// Unit test suite for `GoalModel` progress calculations, transaction linkage, and CRUD operations.
//
// Responsibilities:
// - Verify positive progress aggregation for both goal contributions and goal-linked expenses.
// - Verify progress clamping at 100% (1.0) and remaining amount calculations.
// - Verify edit, deletion, and unlinking semantics for transactions tied to goals.
//
// Data Flow:
// Mock Transactions & Goals → GoalModel Calculations → Test Assertions
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketday/data/models/goal_model.dart';
import 'package:pocketday/data/models/transaction_model.dart';
import 'package:pocketday/data/repositories/goal_repository.dart';
import 'package:pocketday/features/goals/providers/goals_provider.dart';

void main() {

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
      return data
          .map(
            (d) => TransactionModel(
              id: d['id'] ?? 'txn_${d.hashCode}',
              title: d['title'] ?? 'Test',
              amount: (d['amount'] as num).toDouble(),
              type: d['type'] == 'income'
                  ? TransactionType.income
                  : TransactionType.expense,
              categoryId:
                  d['categoryId'] ??
                  (d['type'] == 'income' ? 'goal_contribution' : 'food'),
              categoryName: d['categoryName'] ?? 'Test',
              date: DateTime.now(),
              goalId: d['goalId'],
            ),
          )
          .toList();
    }

    test('0% progress with no transactions', () {
      final txns = <TransactionModel>[];
      expect(baseGoal.calculateCurrentAmount(txns), 0.0);
      expect(baseGoal.calculateProgress(0.0), 0.0);
      expect(baseGoal.calculatePercentage(0.0), 0.0);
      expect(baseGoal.isGoalCompleted(0.0), false);
    });

    test('Goal-linked expenses ADD to goal progress (not subtract)', () {
      // This is the core semantic test for the bug fix.
      // Goal: ₹25,000
      // Contributions: ₹10,000 + ₹10,000 = ₹20,000
      // Goal-linked expenses: ₹4,000 + ₹2,000 = ₹6,000 (POSITIVE progress)
      // Expected: ₹26,000 (contributions + expenses toward goal)
      final txns = makeTxns([
        {
          'id': 't1',
          'amount': 10000,
          'type': 'income',
          'categoryId': 'goal_contribution',
          'goalId': 'g_test',
        },
        {
          'id': 't2',
          'amount': 10000,
          'type': 'income',
          'categoryId': 'goal_contribution',
          'goalId': 'g_test',
        },
        {
          'id': 't3',
          'amount': 4000,
          'type': 'expense',
          'categoryId': 'food',
          'goalId': 'g_test',
        },
        {
          'id': 't4',
          'amount': 2000,
          'type': 'expense',
          'categoryId': 'transport',
          'goalId': 'g_test',
        },
      ]);
      final current = baseGoal.calculateCurrentAmount(txns);
      expect(current, 26000.0); // 10k + 10k + 4k + 2k — all positive
      expect(baseGoal.calculateProgress(current), 1.0); // clamped (above 100%)
      expect(baseGoal.isGoalCompleted(current), true);
    });

    test('100% progress when current == target', () {
      final txns = makeTxns([
        {
          'id': 't1',
          'amount': 25000,
          'type': 'income',
          'categoryId': 'goal_contribution',
          'goalId': 'g_test',
        },
      ]);
      final current = baseGoal.calculateCurrentAmount(txns);
      expect(current, 25000.0);
      expect(baseGoal.calculateProgress(current), 1.0);
      expect(baseGoal.isGoalCompleted(current), true);
    });

    test('Progress clamped to 1.0 when above target', () {
      final txns = makeTxns([
        {
          'id': 't1',
          'amount': 27000,
          'type': 'income',
          'categoryId': 'goal_contribution',
          'goalId': 'g_test',
        },
      ]);
      final current = baseGoal.calculateCurrentAmount(txns);
      expect(current, 27000.0);
      expect(baseGoal.calculateProgress(current), 1.0); // clamped
      expect(
        baseGoal.calculatePercentage(current),
        closeTo(108.0, 0.1),
      ); // real %
      expect(baseGoal.isGoalCompleted(current), true);
    });

    test('Unlinked transactions do not affect goal balance', () {
      final txns = makeTxns([
        {
          'id': 't1',
          'amount': 5000,
          'type': 'income',
          'categoryId': 'goal_contribution',
          'goalId': 'g_test',
        },
        // unrelated transaction with no goalId
        {
          'id': 't2',
          'amount': 3000,
          'type': 'expense',
          'categoryId': 'food',
          'goalId': null,
        },
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

    test(
      'Goal-linked expense: positive for goal, still counts as global expense',
      () {
        // The core "no double counting" test with corrected semantics
        final allTxns = makeTxns([
          {
            'id': 't1',
            'amount': 20000,
            'type': 'income',
            'categoryId': 'goal_contribution',
            'goalId': 'g_test',
          },
          {
            'id': 't2',
            'amount': 5000,
            'type': 'expense',
            'categoryId': 'electronics',
            'goalId': 'g_test',
            'title': 'iPhone case',
          },
          {
            'id': 't3',
            'amount': 3000,
            'type': 'expense',
            'categoryId': 'food',
            'goalId': null,
          },
        ]);

        // Goal progress: 20000 + 5000 = 25000 (both count as positive progress)
        final goalCurrent = baseGoal.calculateCurrentAmount(allTxns);
        expect(goalCurrent, 25000.0);

        // Total global expenses: t2 + t3 (both are normal expenses globally)
        final totalExpenses = allTxns
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        expect(totalExpenses, 8000.0); // 5000 + 3000 — not double counted
      },
    );

    // ─── SCENARIO FROM SPEC: §16 ───

    test(
      'Spec scenario: expense linked to iPhone goal increases goal progress',
      () {
        final iPhoneGoal = GoalModel(
          id: 'g_iphone',
          name: 'iPhone',
          targetAmount: 80000.0,
          emoji: '📱',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Initial: ₹20,000 from contributions
        final txns = makeTxns([
          {
            'id': 't1',
            'amount': 20000,
            'type': 'income',
            'categoryId': 'goal_contribution',
            'goalId': 'g_iphone',
          },
        ]);

        var current = iPhoneGoal.calculateCurrentAmount(txns);
        expect(current, 20000.0);
        expect(iPhoneGoal.calculatePercentage(current), 25.0);

        // User adds an expense linked to the goal
        txns.add(
          TransactionModel(
            id: 't2',
            title: 'iPhone Purchase',
            amount: 5000.0,
            type: TransactionType.expense,
            categoryId: 'electronics',
            categoryName: 'Electronics',
            date: DateTime.now(),
            goalId: 'g_iphone',
          ),
        );

        current = iPhoneGoal.calculateCurrentAmount(txns);
        expect(current, 25000.0); // ₹20k + ₹5k = ₹25k
        expect(iPhoneGoal.calculatePercentage(current), 31.25);
      },
    );

    // ─── SCENARIO FROM SPEC: §18 — Delete reversal ───

    test('Deleting a goal-linked expense reduces goal progress', () {
      final iPhoneGoal = GoalModel(
        id: 'g_iphone',
        name: 'iPhone',
        targetAmount: 80000.0,
        emoji: '📱',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txns = <TransactionModel>[
        TransactionModel(
          id: 't1',
          title: 'Saved',
          amount: 20000.0,
          type: TransactionType.income,
          categoryId: 'goal_contribution',
          categoryName: 'Goal Contribution',
          date: DateTime.now(),
          goalId: 'g_iphone',
        ),
        TransactionModel(
          id: 't2',
          title: 'Purchase',
          amount: 5000.0,
          type: TransactionType.expense,
          categoryId: 'electronics',
          categoryName: 'Electronics',
          date: DateTime.now(),
          goalId: 'g_iphone',
        ),
      ];

      expect(iPhoneGoal.calculateCurrentAmount(txns), 25000.0);

      // Delete the expense
      txns.removeWhere((t) => t.id == 't2');
      expect(iPhoneGoal.calculateCurrentAmount(txns), 20000.0);
    });

    // ─── SCENARIO FROM SPEC: §19 — Edit ───

    test(
      'Editing a goal-linked expense amount updates goal progress correctly',
      () {
        final iPhoneGoal = GoalModel(
          id: 'g_iphone',
          name: 'iPhone',
          targetAmount: 80000.0,
          emoji: '📱',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final txns = <TransactionModel>[
          TransactionModel(
            id: 't1',
            title: 'Saved',
            amount: 20000.0,
            type: TransactionType.income,
            categoryId: 'goal_contribution',
            categoryName: 'Goal Contribution',
            date: DateTime.now(),
            goalId: 'g_iphone',
          ),
          TransactionModel(
            id: 't2',
            title: 'Purchase',
            amount: 5000.0,
            type: TransactionType.expense,
            categoryId: 'electronics',
            categoryName: 'Electronics',
            date: DateTime.now(),
            goalId: 'g_iphone',
          ),
        ];

        expect(iPhoneGoal.calculateCurrentAmount(txns), 25000.0);

        // Edit: change ₹5,000 → ₹8,000
        txns[1] = TransactionModel(
          id: 't2',
          title: 'Purchase',
          amount: 8000.0,
          type: TransactionType.expense,
          categoryId: 'electronics',
          categoryName: 'Electronics',
          date: DateTime.now(),
          goalId: 'g_iphone',
        );

        expect(
          iPhoneGoal.calculateCurrentAmount(txns),
          28000.0,
        ); // 20k + 8k, NOT 12k
      },
    );

    // ─── SCENARIO FROM SPEC: §20 — Remove goal link ───

    test('Removing goalId from a transaction reduces goal progress', () {
      final iPhoneGoal = GoalModel(
        id: 'g_iphone',
        name: 'iPhone',
        targetAmount: 80000.0,
        emoji: '📱',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txns = <TransactionModel>[
        TransactionModel(
          id: 't1',
          title: 'Saved',
          amount: 20000.0,
          type: TransactionType.income,
          categoryId: 'goal_contribution',
          categoryName: 'Goal Contribution',
          date: DateTime.now(),
          goalId: 'g_iphone',
        ),
        TransactionModel(
          id: 't2',
          title: 'Purchase',
          amount: 5000.0,
          type: TransactionType.expense,
          categoryId: 'electronics',
          categoryName: 'Electronics',
          date: DateTime.now(),
          goalId: 'g_iphone',
        ),
      ];

      expect(iPhoneGoal.calculateCurrentAmount(txns), 25000.0);

      // Remove goalId from the expense (unlink from goal)
      txns[1] = TransactionModel(
        id: 't2',
        title: 'Purchase',
        amount: 5000.0,
        type: TransactionType.expense,
        categoryId: 'electronics',
        categoryName: 'Electronics',
        date: DateTime.now(),
        goalId: null,
      );

      expect(iPhoneGoal.calculateCurrentAmount(txns), 20000.0);
    });

    // ─── calculateGoalImpact ───

    test(
      'calculateGoalImpact returns positive for both contributions and expenses',
      () {
        final contribution = TransactionModel(
          id: 'c1',
          title: 'Saved',
          amount: 10000.0,
          type: TransactionType.income,
          categoryId: 'goal_contribution',
          categoryName: 'Goal Contribution',
          date: DateTime.now(),
          goalId: 'g_test',
        );
        final expense = TransactionModel(
          id: 'e1',
          title: 'Bought item',
          amount: 5000.0,
          type: TransactionType.expense,
          categoryId: 'electronics',
          categoryName: 'Electronics',
          date: DateTime.now(),
          goalId: 'g_test',
        );
        final unlinked = TransactionModel(
          id: 'u1',
          title: 'Food',
          amount: 3000.0,
          type: TransactionType.expense,
          categoryId: 'food',
          categoryName: 'Food',
          date: DateTime.now(),
          goalId: null,
        );

        expect(baseGoal.calculateGoalImpact(contribution), 10000.0);
        expect(
          baseGoal.calculateGoalImpact(expense),
          5000.0,
        ); // positive in goal context
        expect(baseGoal.calculateGoalImpact(unlinked), 0.0);
      },
    );

    test(
      'PART 35 Spec Test: Edit goal contribution 5,000 -> 7,500 updates progress without duplicates',
      () {
        final iPhoneGoal = GoalModel(
          id: 'g_iphone',
          name: 'iPhone',
          targetAmount: 50000.0,
          emoji: '📱',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final txns = <TransactionModel>[
          TransactionModel(
            id: 'c1',
            title: 'Saved for iPhone',
            amount: 5000.0,
            type: TransactionType.income,
            categoryId: 'goal_contribution',
            categoryName: 'Goal Contribution',
            date: DateTime.now(),
            goalId: 'g_iphone',
          ),
        ];

        var current = iPhoneGoal.calculateCurrentAmount(txns);
        expect(current, 5000.0);

        // Edit ₹5,000 -> ₹7,500 on same ID 'c1'
        txns[0] = TransactionModel(
          id: 'c1',
          title: 'Saved for iPhone',
          amount: 7500.0,
          type: TransactionType.income,
          categoryId: 'goal_contribution',
          categoryName: 'Goal Contribution',
          date: DateTime.now(),
          goalId: 'g_iphone',
        );

        current = iPhoneGoal.calculateCurrentAmount(txns);
        expect(current, 7500.0);
        expect(txns.length, 1);
      },
    );
  });

  // ─── CRUD TESTS ───

  group('Goal CRUD', () {
    test('Create, read, update, delete goal', () async {
      final container = ProviderContainer(
        overrides: [
          goalRepositoryProvider.overrideWithValue(GoalRepositoryImpl()),
        ],
      );

      // Create
      await container
          .read(goalsProvider.notifier)
          .addGoal(
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
      final updated = goal.copyWith(
        name: 'Emergency Savings',
        targetAmount: 75000.0,
      );
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
