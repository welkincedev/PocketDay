// ============================================================================
// PocketDay Unit Test
// File: widget_test.dart
// Purpose: Basic smoke test verifying application constants integrity.
// Architecture: Test Layer
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketday/core/constants/app_constants.dart';

void main() {
  test('PocketDayApp smoke test — app constants are defined', () {
    expect(AppConstants.appName, equals('PocketDay'));
    expect(AppConstants.currencySymbol, equals('₹'));
    expect(AppConstants.goalsCollection, isNotEmpty);
    expect(AppConstants.transactionsCollection, isNotEmpty);
    expect(AppConstants.budgetCollection, isNotEmpty);
  });
}
