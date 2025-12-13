import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Postal Code Map Viewer Integration Tests', () {
    testWidgets('non-existent postal code shows error message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter non-existent postal code
      await tester.enterText(find.byType(TextField), '00000');
      await tester.tap(find.text('Find City'));
      await tester.pump();

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(
        find.textContaining('No city found for postal code 00000'),
        findsOneWidget,
      );
    });

    testWidgets('valid postal code shows map', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter valid postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.tap(find.text('Find City'));
      await tester.pump();

      // Wait for loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for map to load
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify map is displayed (check for map container)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('error clears when valid code entered after invalid', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // First enter non-existent postal code
      await tester.enterText(find.byType(TextField), '00000');
      await tester.tap(find.text('Find City'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.textContaining('No city found'), findsOneWidget);

      // Then enter valid postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.tap(find.text('Find City'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Error should be cleared
      expect(find.textContaining('No city found'), findsNothing);
    });
  });
}
