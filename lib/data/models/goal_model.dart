// ============================================================================
// PocketDay
// File: goal_model.dart
// Purpose: Target savings goal model and progress calculation extensions.
// Architecture: Domain / Data Model Layer
// State Management: Riverpod (via GoalsProvider)
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

import 'transaction_model.dart';

/// Represents a financial Goal that the user is working toward.
///
/// A Goal has a [targetAmount] and tracks progress through linked transactions:
/// - Income transactions with `categoryId == 'goal_contribution'` and
///   matching [GoalModel.id] in [TransactionModel.goalId] are direct additions.
/// - Expense transactions with a matching [TransactionModel.goalId] are
///   goal-linked purchases — they count as positive progress toward the goal.
///
/// All financial values (current balance, progress, remaining) are derived
/// at read time from the transaction list.
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
  double calculateCurrentAmount(List<TransactionModel> transactions) {
    double balance = 0.0;
    for (var txn in transactions) {
      if (txn.goalId == id) {
        balance += txn.amount;
      }
    }
    return balance;
  }

  double calculateGoalImpact(TransactionModel transaction) {
    if (transaction.goalId != id) return 0.0;
    return transaction.amount;
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
