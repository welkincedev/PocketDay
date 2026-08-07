import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketday/main.dart';

void main() {
  testWidgets('PocketDayApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PocketDayApp(),
      ),
    );
    expect(find.byType(PocketDayApp), findsOneWidget);
  });
}
