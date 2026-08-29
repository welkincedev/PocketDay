import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Billing cycle options for recurring subscriptions.
enum SubscriptionBillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly;

  String get label {
    switch (this) {
      case SubscriptionBillingCycle.weekly:
        return 'Weekly';
      case SubscriptionBillingCycle.monthly:
        return 'Monthly';
      case SubscriptionBillingCycle.quarterly:
        return 'Quarterly';
      case SubscriptionBillingCycle.yearly:
        return 'Yearly';
    }
  }

  String get shortLabel {
    switch (this) {
      case SubscriptionBillingCycle.weekly:
        return '/ wk';
      case SubscriptionBillingCycle.monthly:
        return '/ mo';
      case SubscriptionBillingCycle.quarterly:
        return '/ qtr';
      case SubscriptionBillingCycle.yearly:
        return '/ yr';
    }
  }
}

/// Active status of a subscription.
enum SubscriptionStatus {
  active,
  paused,
  cancelled,
  expired;

  String get label {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.paused:
        return 'Paused';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case SubscriptionStatus.active:
        return AppColors.income;
      case SubscriptionStatus.paused:
        return Colors.orange;
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        return AppColors.expense;
    }
  }
}

/// # Developer Notes
///
/// Represents a recurring subscription tracked in PocketDay (e.g. Netflix, Spotify).
///
/// ## Responsibility
/// Stores metadata including amount, cycle, next payment date, category, status, and auto-expense preferences.
/// Evaluates date-aware active vs expired status dynamically and calculates monthly normalized cost.
///
/// ## Data flow
/// Subscription UI → Subscription Provider → Subscription Repository → Hive
class SubscriptionModel {
  final String id;
  final String name;
  final double amount;
  final SubscriptionBillingCycle billingCycle;
  final DateTime nextPaymentDate;
  final DateTime startDate;
  final String category;
  final String paymentMethod;
  final SubscriptionStatus status;
  final bool autoRecordExpense;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextPaymentDate,
    required this.startDate,
    this.category = 'Entertainment',
    this.paymentMethod = 'UPI',
    this.status = SubscriptionStatus.active,
    this.autoRecordExpense = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Evaluates whether the subscription is currently active dynamically based on dates and status.
  bool isCurrentlyActive([DateTime? relativeTo]) {
    if (status == SubscriptionStatus.paused ||
        status == SubscriptionStatus.cancelled) {
      return false;
    }
    final now = relativeTo ?? DateTime.now();
    // Active if nextPaymentDate is in the future or today
    return !nextPaymentDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Calculates dynamic status label and date-aware details (e.g. "Renews in 12 days" or "Ended 24 Aug 2026").
  String calculateStatusDetail([DateTime? relativeTo]) {
    final now = relativeTo ?? DateTime.now();
    if (status == SubscriptionStatus.paused) {
      return 'Paused';
    }
    if (status == SubscriptionStatus.cancelled) {
      return 'Cancelled';
    }

    final diff = nextPaymentDate.difference(now).inDays;
    if (diff < 0) {
      return 'Expired';
    } else if (diff == 0) {
      return 'Due Today';
    } else if (diff == 1) {
      return 'Renews Tomorrow';
    } else {
      return 'Renews in $diff days';
    }
  }

  /// Normalizes the recurring cost to an equivalent monthly amount.
  ///
  /// - Weekly: amount * 52 / 12
  /// - Monthly: amount
  /// - Quarterly: amount / 3
  /// - Yearly: amount / 12
  double calculateMonthlyEquivalent() {
    switch (billingCycle) {
      case SubscriptionBillingCycle.weekly:
        return (amount * 52.0) / 12.0;
      case SubscriptionBillingCycle.monthly:
        return amount;
      case SubscriptionBillingCycle.quarterly:
        return amount / 3.0;
      case SubscriptionBillingCycle.yearly:
        return amount / 12.0;
    }
  }

  /// Calculates the next payment date based on [billingCycle], safely handling month-end dates.
  static DateTime calculateNextDate(
    DateTime fromDate,
    SubscriptionBillingCycle cycle,
  ) {
    switch (cycle) {
      case SubscriptionBillingCycle.weekly:
        return fromDate.add(const Duration(days: 7));
      case SubscriptionBillingCycle.monthly:
        return _addMonths(fromDate, 1);
      case SubscriptionBillingCycle.quarterly:
        return _addMonths(fromDate, 3);
      case SubscriptionBillingCycle.yearly:
        return _addMonths(fromDate, 12);
    }
  }

  static DateTime _addMonths(DateTime date, int months) {
    var newYear = date.year + (date.month + months - 1) ~/ 12;
    var newMonth = (date.month + months - 1) % 12 + 1;
    var lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    var newDay = date.day > lastDayOfNewMonth ? lastDayOfNewMonth : date.day;
    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle.name,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'category': category,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'autoRecordExpense': autoRecordExpense,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      billingCycle: SubscriptionBillingCycle.values.firstWhere(
        (e) => e.name == map['billingCycle'],
        orElse: () => SubscriptionBillingCycle.monthly,
      ),
      nextPaymentDate: map['nextPaymentDate'] != null
          ? DateTime.parse(map['nextPaymentDate'])
          : DateTime.now(),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      category: map['category'] ?? 'Entertainment',
      paymentMethod: map['paymentMethod'] ?? 'UPI',
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      autoRecordExpense: map['autoRecordExpense'] ?? false,
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? name,
    double? amount,
    SubscriptionBillingCycle? billingCycle,
    DateTime? nextPaymentDate,
    DateTime? startDate,
    String? category,
    String? paymentMethod,
    SubscriptionStatus? status,
    bool? autoRecordExpense,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      startDate: startDate ?? this.startDate,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      autoRecordExpense: autoRecordExpense ?? this.autoRecordExpense,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
