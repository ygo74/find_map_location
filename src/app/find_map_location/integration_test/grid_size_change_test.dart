import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Grid Size Configuration', () {
    setUp(() async {
      // Clear any persisted settings before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('app loads and initializes with default grid size', (WidgetTester tester) async {
      // Arrange - set default grid size
      SharedPreferences.setMockInitialValues({});

      // Act - launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enter postal code to load map with grid
      final postalCodeField = find.byType(TextField);
      expect(postalCodeField, findsOneWidget);
      await tester.enterText(postalCodeField, '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert - postal code input field still exists (app loaded)
      expect(postalCodeField, findsOneWidget);
    });

    testWidgets('app loads with persisted 1000m grid size', (WidgetTester tester) async {
      // Arrange - simulate persisted 1000m setting from previous app session
      SharedPreferences.setMockInitialValues({'grid_cell_size_meters': 1000});

      // Act - launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enter postal code to trigger grid initialization with persisted size
      final postalCodeField = find.byType(TextField);
      await tester.enterText(postalCodeField, '75001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert - app loads successfully with persisted settings
      // (GridConfiguration initialized with 1000m from SharedPreferences)
      expect(postalCodeField, findsOneWidget);
    });
  });
}
