import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/widgets/grid_settings_dialog.dart';

void main() {
  group('GridSettingsDialog', () {
    testWidgets('displays all four cell size options', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridSettingsDialog(currentCellSizeMeters: 500),
          ),
        ),
      );

      // Assert - verify all 4 options present
      expect(find.text('250m'), findsOneWidget);
      expect(find.text('500m'), findsOneWidget);
      expect(find.text('1000m'), findsOneWidget);
      expect(find.text('2000m'), findsOneWidget);
    });

    testWidgets('pre-selects current cell size', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridSettingsDialog(currentCellSizeMeters: 1000),
          ),
        ),
      );

      // Assert - verify 1000m is selected
      final radio1000 = tester.widget<RadioListTile<int>>(
        find.widgetWithText(RadioListTile<int>, '1000m'),
      );
      expect(radio1000.groupValue, equals(1000));
      expect(radio1000.value, equals(1000));
    });

    testWidgets('allows selecting a different size', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridSettingsDialog(currentCellSizeMeters: 500),
          ),
        ),
      );

      // Act - tap on 2000m option
      await tester.tap(find.text('2000m'));
      await tester.pumpAndSettle();

      // Assert - verify 2000m is now selected
      final radio2000 = tester.widget<RadioListTile<int>>(
        find.widgetWithText(RadioListTile<int>, '2000m'),
      );
      expect(radio2000.groupValue, equals(2000));
    });

    testWidgets('returns null when Cancel button pressed', (WidgetTester tester) async {
      // Arrange
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<int>(
                      context: context,
                      builder: (context) => GridSettingsDialog(currentCellSizeMeters: 500),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - show dialog and tap Cancel
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - dialog returns null
      expect(result, isNull);
    });

    testWidgets('returns selected size when Apply button pressed', (WidgetTester tester) async {
      // Arrange
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<int>(
                      context: context,
                      builder: (context) => GridSettingsDialog(currentCellSizeMeters: 500),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Act - show dialog, select 250m, and tap Apply
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('250m'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Assert - dialog returns selected value
      expect(result, equals(250));
    });

    testWidgets('displays dialog title', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridSettingsDialog(currentCellSizeMeters: 500),
          ),
        ),
      );

      // Assert
      expect(find.text('Grid Cell Size'), findsOneWidget);
    });
  });
}
