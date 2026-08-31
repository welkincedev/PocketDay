// ============================================================
// POCKETDAY DEVELOPER NOTE
// File: transaction_model.dart
//
// Purpose:
// Immutable financial transaction entity representing income or expense records.
//
// Responsibilities:
// - Hold transaction details (id, title, amount, type, categoryId, categoryName, date, notes, goalId).
// - Convert to/from Map for Hive storage in `transactionsBox`.
// - Link optionally to a Goal via `goalId`.
//
// Data Flow:
// Transaction Form / Sheets → TransactionsProvider ↔ TransactionModel ↔ Hive (`transactionsBox`)
//
// Important Rules:
// - Goal-allocated transactions maintain `type: TransactionType.expense` for balance calculations while contributing positively to Goal progress.
// - Amounts are stored as doubles.
//
// Main Operations:
// - toMap(): Convert transaction entity to Hive-compatible map
// - TransactionModel.fromMap(map): Reconstruct transaction entity from Hive map
// - copyWith(): Copy with modified parameters
// ============================================================

/// Defines whether a transaction adds to or subtracts from the user's balance.
enum TransactionType { income, expense }

/// Represents a single financial event recorded by the user.
///
/// Important rule: A transaction may carry an optional [goalId] linking it
/// to a [GoalModel]. When present:
/// - The transaction still counts toward **global totals** (income or expense
///   in Dashboard / Budget). It must NOT be excluded to avoid double-counting.
/// - The Goal provider uses [goalId] to calculate the goal's current balance.
///
/// Transactions are stored in Hive via [TransactionRepository] and exposed
/// to the UI through [TransactionsProvider].
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
