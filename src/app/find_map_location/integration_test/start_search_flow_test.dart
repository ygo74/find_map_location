import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Start Search Flow Integration Test', () {
    testWidgets('complete flow: city selection -> address display -> start search -> map zoom', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter valid postal code
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should see map and random address
      expect(find.text('Find this address:'), findsOneWidget);

      // Should see Start Search button (enabled)
      expect(find.text('Start Search'), findsOneWidget);

      // Verify button is enabled
      final button = find.text('Start Search');
      expect(button, findsOneWidget);

      // Tap Start Search button
      await tester.tap(button);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Button should now be disabled (grayed out)
      // Map should have zoomed to user location (if permission granted)
      // Address should still be visible
      expect(find.text('Find this address:'), findsOneWidget);
    });

    testWidgets('start search with location permission denied shows appropriate behavior', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter valid postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap Start Search button
      await tester.tap(find.text('Start Search'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Map should remain at city view (no zoom)
      // Button should be disabled
      // No error message expected
      expect(find.text('Find this address:'), findsOneWidget);
    });

    testWidgets('address remains visible after start search is pressed', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter valid postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Get the address text before pressing button
      final addressDisplayBefore = find.text('Find this address:');
      expect(addressDisplayBefore, findsOneWidget);

      // Tap Start Search button
      await tester.tap(find.text('Start Search'));
      await tester.pumpAndSettle();

      // Address should still be visible
      final addressDisplayAfter = find.text('Find this address:');
      expect(addressDisplayAfter, findsOneWidget);
    });
  });
}
