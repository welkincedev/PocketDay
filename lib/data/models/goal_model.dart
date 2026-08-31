// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: goal_model.dart
//
// Purpose:
// Domain model and calculation extension for target savings goals.
//
// Responsibilities:
// - Hold goal target criteria (id, name, targetAmount, emoji, targetDate, createdAt, updatedAt).
// - Provide `toMap()` and `fromMap()` for Hive storage in `goalsBox`.
// - Expose `GoalCalculations` extension to derive goal progress, remaining amount, and completion status from transactions.
//
// Data Flow:
// Goal Sheet / Transactions ↔ GoalModel ↔ GoalCalculations extension ↔ GoalsNotifier
//
// Important Rules:
// - Goal contributions and goal-linked expenses add positively (`+txn.amount`) to goal progress.
// - Financial calculations are derived dynamically at read time from transactions.
//
// Main Operations:
// - calculateCurrentAmount(transactions): Sum total saved balance
// - calculateProgress(currentAmount): Derive 0.0-1.0 progress ratio
// - isGoalCompleted(currentAmount): Check if balance >= target
// ============================================================

import 'transaction_model.dart';

/// Represents a financial Goal that the user is working toward.
///
/// A Goal has a [targetAmount] and tracks progress through linked transactions:
/// - Income transactions with `categoryId == 'goal_contribution'` and
///   matching [GoalModel.id] in [TransactionModel.goalId] are **direct additions**.
/// - Expense transactions with a matching [TransactionModel.goalId] are
///   **goal-linked purchases** — they count as **positive progress** toward
///   the goal (the user spent money on the thing they're saving for).
///
/// A goal-linked expense is still a normal expense in the global financial
/// system (Dashboard, Budget, Transaction list). The goal calculation is a
/// separate interpretation of the same transaction.
///
/// All financial values (current balance, progress, remaining) are **derived
/// at read time** from the transaction list — they are never stored.
///
/// See [GoalCalculations] for the calculation helpers.
class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final String emoji;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.emoji,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'emoji': emoji,
      'targetDate': targetDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      emoji: map['emoji'] ?? '🎯',
      targetDate: map['targetDate'] != null
          ? DateTime.parse(map['targetDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  GoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    String? emoji,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      emoji: emoji ?? this.emoji,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension GoalCalculations on GoalModel {
  /// Calculates the current progress amount for this goal from [transactions].
  ///
  /// Goal progress rule:
  /// ```
  /// progress = sum of goal_contributions + sum of goal-linked expense amounts
  /// ```
  ///
  /// Both contribution income AND goal-linked purchases count as positive
  /// progress. A goal-linked expense means "I spent money toward this goal",
  /// which is progress, not a deduction.
  double calculateCurrentAmount(List<TransactionModel> transactions) {
    double balance = 0.0;
    for (var txn in transactions) {
      if (txn.goalId == id) {
        // Both direct contributions and goal-linked expenses increase progress
        balance += txn.amount;
      }
    }
    return balance;
  }

  /// Returns the goal-context impact of a single [transaction].
  ///
  /// In goal context, ALL linked transactions are positive progress:
  /// - Direct contributions: +amount
  /// - Goal-linked expenses: +amount (spending toward the goal)
  ///
  /// Returns 0 if the transaction is not linked to this goal.
  double calculateGoalImpact(TransactionModel transaction) {
    if (transaction.goalId != id) return 0.0;
    return transaction.amount; // always positive in goal context
  }

  double calculateRemainingAmount(double currentAmount) {
    return (targetAmount - currentAmount) > 0
        ? (targetAmount - currentAmount)
        : 0.0;
  }

  double calculateProgress(double currentAmount) {
    return targetAmount > 0
        ? (currentAmount / targetAmount).clamp(0.0, 1.0)
        : 0.0;
  }

  double calculatePercentage(double currentAmount) {
    return targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;
  }

  bool isGoalCompleted(double currentAmount) {
    return currentAmount >= targetAmount;
  }
}
