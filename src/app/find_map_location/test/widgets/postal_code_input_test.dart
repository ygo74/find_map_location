import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/widgets/postal_code_input.dart';

void main() {
  group('PostalCodeInput', () {
    testWidgets('displays error message when provided', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeInput(
              controller: controller,
              onSubmit: () {},
              errorMessage: 'Test error message',
            ),
          ),
        ),
      );

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('does not display error when errorMessage is null', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeInput(
              controller: controller,
              onSubmit: () {},
              errorMessage: null,
            ),
          ),
        ),
      );

      expect(find.text('Test error message'), findsNothing);
    });

    testWidgets('limits input to 5 digits', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeInput(
              controller: controller,
              onSubmit: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '123456789');
      expect(controller.text, equals('12345'));
    });

    testWidgets('only accepts digits', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeInput(
              controller: controller,
              onSubmit: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ABC123');
      expect(controller.text, equals('123'));
    });

    testWidgets('calls onSubmit when button is pressed', (tester) async {
      final controller = TextEditingController();
      var submitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeInput(
              controller: controller,
              onSubmit: () => submitCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Find City'));
      expect(submitCalled, isTrue);
    });
  });
}
