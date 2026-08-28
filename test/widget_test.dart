import 'package:flutter_test/flutter_test.dart';
import 'package:pocketday/core/constants/app_constants.dart';

void main() {
  test('PocketDayApp smoke test — app constants are defined', () {
    expect(AppConstants.goalsBox, isNotEmpty);
    expect(AppConstants.transactionsBox, isNotEmpty);
    expect(AppConstants.budgetBox, isNotEmpty);
  });
}
