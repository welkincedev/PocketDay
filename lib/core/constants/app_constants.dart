// ============================================================================
// PocketDay
// File: app_constants.dart
// Purpose: Application design tokens, dimensions, and default category definitions.
// Architecture: Core Layer
// State Management: N/A
// Storage: N/A
// ============================================================================

import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'PocketDay';
  static const String currencySymbol = '₹';
  static const String defaultLocale = 'en_IN';

  // Spacing System
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 24.0;

  // Radius System
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // Collection Keys (Firestore)
  static const String transactionsCollection = 'transactions';
  static const String budgetCollection = 'budgets';
  static const String goalsCollection = 'goals';
  static const String subscriptionsCollection = 'subscriptions';
  static const String savingsGoalsCollection = 'savings_goals';

  // Transaction Categories with Icons & Colors
  static const List<Map<String, dynamic>> defaultCategories = [
    {
      'id': 'food',
      'name': 'Food & Dining',
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFF59E0B),
      'type': 'expense',
    },
    {
      'id': 'shopping',
      'name': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFEC4899),
      'type': 'expense',
    },
    {
      'id': 'transport',
      'name': 'Transportation',
      'icon': Icons.directions_bus_rounded,
      'color': Color(0xFF3B82F6),
      'type': 'expense',
    },
    {
      'id': 'bills',
      'name': 'Bills & Utilities',
      'icon': Icons.receipt_long_rounded,
      'color': Color(0xFF8B5CF6),
      'type': 'expense',
    },
    {
      'id': 'entertainment',
      'name': 'Entertainment',
      'icon': Icons.movie_rounded,
      'color': Color(0xFF6366F1),
      'type': 'expense',
    },
    {
      'id': 'health',
      'name': 'Health & Fitness',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFEF4444),
      'type': 'expense',
    },
    {
      'id': 'salary',
      'name': 'Salary',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFF10B981),
      'type': 'income',
    },
    {
      'id': 'freelance',
      'name': 'Freelance',
      'icon': Icons.laptop_mac_rounded,
      'color': Color(0xFF06B6D4),
      'type': 'income',
    },
    {
      'id': 'investment',
      'name': 'Investment',
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFF14B8A6),
      'type': 'income',
    },
    {
      'id': 'goal_contribution',
      'name': 'Goal Contribution',
      'icon': Icons.savings_rounded,
      'color': Color(0xFF10B981),
      'type': 'both',
    },
    {
      'id': 'other',
      'name': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFF64748B),
      'type': 'both',
    },
  ];
}
