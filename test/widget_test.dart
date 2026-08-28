import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pocketday/core/constants/app_constants.dart';
import 'package:pocketday/main.dart';

void main() {
  testWidgets('PocketDayApp smoke test', (WidgetTester tester) async {
    final tempDir = await Directory.systemTemp.createTemp('pocketday_smoke_test');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.userBox);
    await Hive.openBox(AppConstants.transactionsBox);
    await Hive.openBox(AppConstants.budgetBox);

    await tester.pumpWidget(
      const ProviderScope(
        child: PocketDayApp(),
      ),
    );
    expect(find.byType(PocketDayApp), findsOneWidget);

    await Hive.close();
    await tempDir.delete(recursive: true);
  });
}
