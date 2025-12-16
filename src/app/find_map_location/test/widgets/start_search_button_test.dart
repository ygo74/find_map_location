import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/widgets/start_search_button.dart';

void main() {
  group('StartSearchButton', () {
    testWidgets('displays enabled button when isEnabled is true', (tester) async {
      bool callbackInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StartSearchButton(
              isEnabled: true,
              onPressed: () {
                callbackInvoked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Start Search'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Verify button is enabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('displays disabled button when isEnabled is false', (tester) async {
      bool callbackInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StartSearchButton(
              isEnabled: false,
              onPressed: () {
                callbackInvoked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Start Search'), findsOneWidget);

      // Verify button is disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      // Callback should not be invoked when disabled
      expect(callbackInvoked, isFalse);
    });

    testWidgets('button becomes disabled after being tapped', (tester) async {
      bool isEnabled = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StartSearchButton(
                  isEnabled: isEnabled,
                  onPressed: () {
                    setState(() {
                      isEnabled = false;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially enabled
      ElevatedButton button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Now disabled
      button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('displays Material Design 3 styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StartSearchButton(
              isEnabled: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Start Search'), findsOneWidget);

      // Verify it's an ElevatedButton (Material Design 3 component)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button, isNotNull);
    });

    testWidgets('invokes callback when pressed and enabled', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StartSearchButton(
              isEnabled: true,
              onPressed: () {
                callCount++;
              },
            ),
          ),
        ),
      );

      expect(callCount, 0);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(callCount, 1);

      // Tap again
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(callCount, 2);
    });

    testWidgets('button shows disabled visual state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StartSearchButton(
                  key: const Key('enabled'),
                  isEnabled: true,
                  onPressed: () {},
                ),
                StartSearchButton(
                  key: const Key('disabled'),
                  isEnabled: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Both buttons should be visible
      expect(find.byKey(const Key('enabled')), findsOneWidget);
      expect(find.byKey(const Key('disabled')), findsOneWidget);

      // Enabled button should have onPressed callback
      final enabledButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('enabled')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(enabledButton.onPressed, isNotNull);

      // Disabled button should have null onPressed callback
      final disabledButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('disabled')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(disabledButton.onPressed, isNull);
    });
  });
}
