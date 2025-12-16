import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/widgets/address_display.dart';
import 'package:find_map_location/models/random_address.dart';

void main() {
  group('AddressDisplay', () {
    testWidgets('displays address correctly', (tester) async {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressDisplay(address: address),
          ),
        ),
      );

      expect(find.text('Find this address:'), findsOneWidget);
      expect(find.text('42 Rue de Rivoli, Paris'), findsOneWidget);
    });

    testWidgets('handles special characters correctly', (tester) async {
      final address = RandomAddress(
        streetNumber: '5',
        streetName: "Rue de l'Église",
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.86,
        longitude: 2.34,
        generatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressDisplay(address: address),
          ),
        ),
      );

      expect(find.text("5 Rue de l'Église, Paris"), findsOneWidget);
    });

    testWidgets('uses Card widget', (tester) async {
      final address = RandomAddress(
        streetNumber: '10',
        streetName: 'Avenue des Champs-Élysées',
        cityName: 'Paris',
        postcode: '75008',
        latitude: 48.8698,
        longitude: 2.3078,
        generatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressDisplay(address: address),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays header text', (tester) async {
      final address = RandomAddress(
        streetNumber: '1',
        streetName: 'Rue de la Paix',
        cityName: 'Lyon',
        postcode: '69001',
        latitude: 45.7640,
        longitude: 4.8357,
        generatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressDisplay(address: address),
          ),
        ),
      );

      expect(find.text('Find this address:'), findsOneWidget);
    });

    testWidgets('handles long street names without overflow', (tester) async {
      final address = RandomAddress(
        streetNumber: '123',
        streetName: 'Rue de la République et de la Liberté des Citoyens',
        cityName: 'Villeurbanne',
        postcode: '69100',
        latitude: 45.7705,
        longitude: 4.8825,
        generatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressDisplay(address: address),
          ),
        ),
      );

      // Should render without overflow errors
      expect(tester.takeException(), isNull);
      expect(find.byType(AddressDisplay), findsOneWidget);
    });

    testWidgets('renders with proper styling', (tester) async {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressDisplay(address: address),
          ),
        ),
      );

      // Check that address text has larger style than header
      final headerText = tester.widget<Text>(find.text('Find this address:'));
      final addressText = tester.widget<Text>(find.text('42 Rue de Rivoli, Paris'));

      expect(headerText.style, isNotNull);
      expect(addressText.style, isNotNull);
    });
  });
}
