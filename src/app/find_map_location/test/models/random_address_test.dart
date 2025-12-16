import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/random_address.dart';
import 'package:find_map_location/models/city.dart';

void main() {
  group('RandomAddress', () {
    test('toDisplayString formats address correctly', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      expect(address.toDisplayString(), '42 Rue de Rivoli, Paris');
    });

    test('toDisplayString handles special characters', () {
      final address = RandomAddress(
        streetNumber: '5',
        streetName: "Rue de l'Église",
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.86,
        longitude: 2.34,
        generatedAt: DateTime.now().toUtc(),
      );

      expect(address.toDisplayString(), "5 Rue de l'Église, Paris");
    });

    test('toUniqueKey generates consistent key', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      expect(address.toUniqueKey(), 'Paris|Rue de Rivoli|42');
    });

    test('toUniqueKey is consistent across instances', () {
      final address1 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final address2 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc().add(Duration(seconds: 5)),
      );

      expect(address1.toUniqueKey(), address2.toUniqueKey());
    });

    test('isInCity validates city match', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final parisCity = City(
        name: 'Paris',
        postalCode: '75001',
        latitude: 48.86,
        longitude: 2.34,
        department: 'Paris',
      );

      final lyonCity = City(
        name: 'Lyon',
        postalCode: '69000',
        latitude: 45.75,
        longitude: 4.85,
        department: 'Rhône',
      );

      expect(address.isInCity(parisCity), isTrue);
      expect(address.isInCity(lyonCity), isFalse);
    });

    test('isInCity is case-insensitive', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'PARIS',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final city = City(
        name: 'paris',
        postalCode: '75001',
        latitude: 48.86,
        longitude: 2.34,
        department: 'Paris',
      );

      expect(address.isInCity(city), isTrue);
    });

    test('equality is based on address components', () {
      final address1 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final address2 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc().add(Duration(hours: 1)),
      );

      final address3 = RandomAddress(
        streetNumber: '43',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      expect(address1, equals(address2));
      expect(address1, isNot(equals(address3)));
    });

    test('hashCode is consistent with equality', () {
      final address1 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final address2 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8607,
        longitude: 2.3377,
        generatedAt: DateTime.now().toUtc().add(Duration(hours: 1)),
      );

      expect(address1.hashCode, equals(address2.hashCode));
    });

    test('addresses can be used in Sets for uniqueness', () {
      final address1 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final address2 = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8607,
        longitude: 2.3377,
        generatedAt: DateTime.now().toUtc(),
      );

      final addressSet = {address1, address2};
      expect(addressSet.length, 1); // Should deduplicate
    });
  });
}
