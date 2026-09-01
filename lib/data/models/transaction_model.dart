// ============================================================================
// PocketDay
// File: transaction_model.dart
// Purpose: Immutable entity representing an income or expense transaction.
// Architecture: Domain / Data Model Layer
// State Management: Riverpod (via TransactionsProvider)
// Storage: Cloud Firestore with Native Offline Cache
// ============================================================================

/// Defines whether a transaction adds to or subtracts from the user's balance.
enum TransactionType { income, expense }

/// Represents a single financial event recorded by the user.
///
/// Important rule: A transaction may carry an optional [goalId] linking it
/// to a [GoalModel]. When present:
/// - The transaction still counts toward global totals (income or expense
///   in Dashboard / Budget).
/// - The Goal provider uses [goalId] to calculate the goal's current balance.
class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final String? notes;
  final String? goalId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    this.notes,
    this.goalId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'date': date.toIso8601String(),
      'notes': notes,
      'goalId': goalId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: map['categoryId'] ?? 'other',
      categoryName: map['categoryName'] ?? 'Other',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      notes: map['notes'],
      goalId: map['goalId'],
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? notes,
    String? goalId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      goalId: goalId ?? this.goalId,
    );
  }
}
