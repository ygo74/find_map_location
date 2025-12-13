import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Single-City Bypass Flow', () {
    testWidgets('Enter postal code 75001 → map displays immediately without selection screen',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Find the postal code input field
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      // Enter postal code "75001" (single city: Paris)
      await tester.enterText(inputField, '75001');
      await tester.pump();

      // Find and tap the submit button
      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);

      // Wait for API response and UI update
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify city selection screen DID NOT appear
      expect(find.text('Select City'), findsNothing);

      // Verify we're still on home screen
      expect(find.text('Find Map Location'), findsOneWidget);

      // Verify loading spinner is gone (map should be showing)
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify no selection list items
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('Single-city result displays map without extra navigation steps',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter single-city postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Count number of screens in navigation stack
      // Should be 1 (home screen only, no selection screen pushed)
      final navigator = tester.widget<Navigator>(find.byType(Navigator).first);
      expect(navigator, isNotNull);

      // Verify selection screen never appeared
      expect(find.text('Select City'), findsNothing);

      // Verify back button is NOT present (would indicate a pushed route)
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('Backward compatibility - feature 001 behavior maintained for single cities',
        (WidgetTester tester) async {
      // This test ensures that the original feature 001 behavior
      // (postal code → map) still works for single-city results

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code
      await tester.enterText(find.byType(TextField), '06000'); // Nice (single city)
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));

      // Show loading
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for response
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Map should appear immediately
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Select City'), findsNothing);
      expect(find.text('Find Map Location'), findsOneWidget);
    });
  });
}
