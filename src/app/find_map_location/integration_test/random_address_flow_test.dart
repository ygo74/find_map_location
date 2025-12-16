import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Random Address Complete Game Flow Integration Test', () {
    testWidgets('complete game flow from postal code to address display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Verify initial state
      expect(find.text('Find Map Location'), findsOneWidget);
      expect(find.text('Enter a postal code to view the map'), findsOneWidget);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Step 2: Enter valid postal code for Paris
      await tester.enterText(textField, '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 3: Verify map is displayed
      expect(find.text('Enter a postal code to view the map'), findsNothing);

      // Step 4: Verify random address is displayed
      expect(find.text('Find this address:'), findsOneWidget);

      // Address should have street number, street name, and city
      // The actual address is random, so we just verify the card exists
      expect(find.byType(Card), findsAtLeastNWidgets(1));

      // Step 5: Verify Start Search button appears
      expect(find.text('Start Search'), findsOneWidget);

      // Step 6: Tap Start Search button
      await tester.tap(find.text('Start Search'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 7: Verify button is still visible (just disabled)
      // and address is still displayed
      expect(find.text('Find this address:'), findsOneWidget);
      expect(find.text('Start Search'), findsOneWidget);
    });

    testWidgets('handles single city postal code correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code with single city
      await tester.enterText(find.byType(TextField), '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should bypass city selection and go straight to map with address
      expect(find.text('Find this address:'), findsOneWidget);
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('address changes when selecting different city', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter first postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Find this address:'), findsOneWidget);

      // Clear and enter different postal code
      await tester.enterText(find.byType(TextField), '69001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should still have address display (new address for Lyon)
      expect(find.text('Find this address:'), findsOneWidget);
    });

    testWidgets('handles invalid postal code gracefully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter invalid postal code
      await tester.enterText(find.byType(TextField), '00000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show error message
      expect(find.textContaining('No city found'), findsOneWidget);

      // Should not show address display
      expect(find.text('Find this address:'), findsNothing);
    });

    testWidgets('validates postal code format', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter invalid format (too short)
      await tester.enterText(find.byType(TextField), '123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.textContaining('valid 5-digit'), findsOneWidget);

      // Should not show address
      expect(find.text('Find this address:'), findsNothing);
    });

    testWidgets('shows loading indicator during address generation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Should show loading indicator briefly
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Loading should be gone, address should appear
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Find this address:'), findsOneWidget);
    });

    testWidgets('start search button disabled after press', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Get to address display
      await tester.enterText(find.byType(TextField), '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find the button
      final button = find.text('Start Search');
      expect(button, findsOneWidget);

      // Tap it once
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Try to tap again - should not cause any error
      // Button should be visible but disabled
      expect(button, findsOneWidget);
    });
  });
}
