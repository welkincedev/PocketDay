import 'transaction_model.dart';

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
      targetDate: map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
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
        if (txn.categoryId == 'goal_contribution') {
          balance += txn.amount;
        } else if (txn.type == TransactionType.expense) {
          balance -= txn.amount;
        }
      }
    }
    return balance;
  }

  double calculateRemainingAmount(double currentAmount) {
    return (targetAmount - currentAmount) > 0 ? (targetAmount - currentAmount) : 0.0;
  }

  double calculateProgress(double currentAmount) {
    return targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  }

  double calculatePercentage(double currentAmount) {
    return targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0.0;
  }

  bool isGoalCompleted(double currentAmount) {
    return currentAmount >= targetAmount;
  }
}
