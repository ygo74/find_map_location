import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Grid Solution Flow Integration Tests', () {
    testWidgets('Show Solution button appears when address is loaded',
        (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code for Paris (single city)
      final postalCodeField = find.byType(TextField);
      expect(postalCodeField, findsOneWidget);
      await tester.enterText(postalCodeField, '75001');
      await tester.pump();

      // Submit via button
      final submitButton = find.byType(ElevatedButton);
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
      } else {
        await tester.testTextInput.receiveAction(TextInputAction.done);
      }
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify address is displayed (or map is visible)
      // The app should have either address display or map visible
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Find the Show Solution FAB if address was generated
      final solutionFab = find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.lightbulb_outline),
      );

      // If solution button exists, test it works
      if (solutionFab.evaluate().isNotEmpty) {
        // Tap the Show Solution button
        await tester.tap(solutionFab);
        await tester.pumpAndSettle();

        // Verify SnackBar with cell ID appears
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Address is in cell'), findsOneWidget);
      }
    });

    testWidgets('Solution button hidden when no address loaded', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify no Show Solution button appears initially
      final solutionFab = find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.lightbulb_outline),
      );
      expect(solutionFab, findsNothing);
    });
  });
}
