class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String emoji;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.emoji,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => (targetAmount - savedAmount) > 0 ? (targetAmount - savedAmount) : 0.0;

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get percentage => targetAmount > 0 ? (savedAmount / targetAmount) * 100 : 0.0;

  bool get isCompleted => savedAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'emoji': emoji,
      'targetDate': targetDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
      emoji: map['emoji'] ?? '💰',
      targetDate: map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
    );
  }

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    String? emoji,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      emoji: emoji ?? this.emoji,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
