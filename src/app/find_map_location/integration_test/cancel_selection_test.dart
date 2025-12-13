import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cancel Selection Flow', () {
    testWidgets('User can press back button to cancel selection',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter multi-city postal code
      await tester.enterText(find.byType(TextField), '01630');
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify selection screen appeared
      expect(find.text('Select City'), findsOneWidget);

      // Press back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify back on home screen
      expect(find.text('Select City'), findsNothing);
      expect(find.text('Find Map Location'), findsOneWidget);

      // Verify no map is displayed (user cancelled, so idle state)
      expect(find.text('Enter a postal code to view the map'), findsOneWidget);
    });

    testWidgets('Cancel selection preserves postal code input',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code
      await tester.enterText(find.byType(TextField), '01630');
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Cancel selection
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify input field still has value
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '01630');
    });

    testWidgets('User can retry after cancelling selection',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code
      await tester.enterText(find.byType(TextField), '01630');
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Cancel selection
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Submit again
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify selection screen appears again
      expect(find.text('Select City'), findsOneWidget);
      expect(find.text('Péron'), findsOneWidget);
    });

    testWidgets('Rapid postal code changes cancel previous request',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter first postal code
      await tester.enterText(find.byType(TextField), '01630');
      await tester.pump();

      // Submit first request
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 100));

      // Quickly change to second postal code (before first completes)
      await tester.enterText(find.byType(TextField), '75001');
      await tester.pump();

      // Submit second request
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // First request (01630 - multi-city) should be cancelled
      // Only second request (75001 - single city) should complete
      // Verify NO selection screen (75001 is single city)
      expect(find.text('Select City'), findsNothing);

      // Verify map is displayed (75001 completed)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
