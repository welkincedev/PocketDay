// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: budget_model.dart
//
// Purpose:
// Domain model representing an overall or category-specific monthly spending budget.
//
// Responsibilities:
// - Track overall monthly budget (when `categoryId == null`) or category budget (`categoryId != null`).
// - Format target month as `YYYY-MM`.
// - Convert to/from Map for Hive storage in `budgetBox`.
//
// Data Flow:
// Budget Sheet → BudgetNotifier ↔ BudgetModel ↔ Hive (`budgetBox`)
//
// Important Rules:
// - `categoryId == null` denotes the overall global monthly budget limit.
//
// Main Operations:
// - toMap(): Serialize budget model to Hive map
// - BudgetModel.fromMap(map): Deserialize Hive map to budget model
// - copyWith(): Return updated budget instance
// ============================================================

class BudgetModel {
  final String id;
  final double amount;
  final String period; // e.g. 'monthly'
  final String month; // format: 'yyyy-MM'
  final String? categoryId; // null represents overall monthly budget
  final String? categoryName; // null or category name
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.amount,
    this.period = 'monthly',
    required this.month,
    this.categoryId,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'period': period,
      'month': month,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      period: map['period'] ?? 'monthly',
      month: map['month'] ?? '',
      categoryId: map['categoryId'],
      categoryName: map['categoryName'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  BudgetModel copyWith({
    String? id,
    double? amount,
    String? period,
    String? month,
    String? categoryId,
    String? categoryName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
