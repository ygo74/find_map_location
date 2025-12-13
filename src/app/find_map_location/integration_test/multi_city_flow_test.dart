import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-City Selection Flow', () {
    testWidgets('Enter postal code 01630 → see selection → select city → map displays',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Find the postal code input field
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      // Enter postal code "01630" (has 3 cities)
      await tester.enterText(inputField, '01630');
      await tester.pump();

      // Find and tap the submit button
      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify city selection screen appeared
      expect(find.text('Select City'), findsOneWidget);

      // Verify multiple cities are displayed
      expect(find.text('Saint-Genis-Pouilly'), findsOneWidget);
      expect(find.text('Péron'), findsOneWidget);
      expect(find.text('Sergy'), findsOneWidget);

      // Verify department is shown in subtitle
      expect(find.text('Ain'), findsAtLeast(3));

      // Tap on "Péron"
      await tester.tap(find.text('Péron'));
      await tester.pumpAndSettle();

      // Verify we're back on home screen (no "Select City" title)
      expect(find.text('Select City'), findsNothing);

      // Verify map is displayed
      // Note: FlutterMap widget may not be easily testable in integration tests
      // We verify by checking that we're no longer in loading state
      // and selection screen is dismissed
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('User can cancel city selection and return to home',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code "01630"
      await tester.enterText(find.byType(TextField), '01630');
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify selection screen appeared
      expect(find.text('Select City'), findsOneWidget);

      // Tap back button (AppBar leading)
      final backButton = find.byType(BackButton);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify we're back on home screen
      expect(find.text('Select City'), findsNothing);
      expect(find.text('Find Map Location'), findsOneWidget);

      // Verify input field still has the postal code
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '01630');
    });

    testWidgets('Cities are displayed in alphabetical order',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter postal code "01630"
      await tester.enterText(find.byType(TextField), '01630');
      await tester.pump();

      // Submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find all ListTile widgets
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles.length, 3);

      // Extract titles
      final titles = listTiles.map((tile) {
        final titleWidget = tile.title as Text;
        return titleWidget.data;
      }).toList();

      // Verify alphabetical order
      expect(titles[0], 'Péron');
      expect(titles[1], 'Saint-Genis-Pouilly');
      expect(titles[2], 'Sergy');
    });
  });
}
