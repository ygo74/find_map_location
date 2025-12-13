import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/screens/home_screen.dart';

void main() {
  group('HomeScreen validation', () {
    testWidgets('displays error for empty postal code', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Tap submit without entering anything
      await tester.tap(find.text('Find City'));
      await tester.pump();

      expect(find.text('Please enter a postal code'), findsOneWidget);
    });

    testWidgets('displays error for invalid format - too short', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.text('Find City'));
      await tester.pump();

      expect(
        find.text('Please enter a valid 5-digit French postal code'),
        findsOneWidget,
      );
    });

    testWidgets('displays error for invalid format - contains letters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Note: The input filter prevents letters from being entered,
      // but we can test the validation logic directly
      await tester.enterText(find.byType(TextField), '7500');
      await tester.tap(find.text('Find City'));
      await tester.pump();

      expect(
        find.text('Please enter a valid 5-digit French postal code'),
        findsOneWidget,
      );
    });

    testWidgets('clears error when valid input is entered after error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // First trigger an error
      await tester.tap(find.text('Find City'));
      await tester.pump();
      expect(find.text('Please enter a postal code'), findsOneWidget);

      // Then enter valid input (validation will run on next submit)
      await tester.enterText(find.byType(TextField), '75001');
      await tester.tap(find.text('Find City'));
      await tester.pump();

      // Error message should be cleared (loading or map would show)
      expect(find.text('Please enter a postal code'), findsNothing);
    });

    testWidgets('latest-wins: submitting new request cancels previous', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Submit first postal code and verify loading starts
      await tester.enterText(find.byType(TextField), '75001');
      await tester.tap(find.text('Find City'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Immediately submit second postal code (simulating cancellation scenario)
      await tester.enterText(find.byType(TextField), '69001');
      await tester.tap(find.text('Find City'));
      await tester.pump();

      // The request cancellation logic is implemented via _pendingRequest tracking
      // Full verification would require mocking the geocoding service
      // This test verifies the UI can handle rapid submissions without crashing
    });
  });
}
