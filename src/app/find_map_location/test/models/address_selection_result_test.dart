import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/address_selection_result.dart';
import 'package:find_map_location/models/random_address.dart';

void main() {
  group('AddressSelectionResult', () {
    test('success constructor creates valid result', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final result = AddressSelectionResult.success(address);

      expect(result.isSuccess, isTrue);
      expect(result.address, equals(address));
      expect(result.error, isNull);
    });

    test('failure constructor creates valid result', () {
      final errorMessage = 'Unable to generate address for this location';
      final result = AddressSelectionResult.failure(errorMessage);

      expect(result.isSuccess, isFalse);
      expect(result.address, isNull);
      expect(result.error, equals(errorMessage));
    });

    test('success result has non-null address', () {
      final address = RandomAddress(
        streetNumber: '10',
        streetName: 'Rue de la Paix',
        cityName: 'Lyon',
        postcode: '69001',
        latitude: 45.7640,
        longitude: 4.8357,
        generatedAt: DateTime.now().toUtc(),
      );

      final result = AddressSelectionResult.success(address);

      expect(result.address, isNotNull);
      expect(result.address!.streetNumber, '10');
    });

    test('failure result has non-null error message', () {
      final result = AddressSelectionResult.failure('Connection error');

      expect(result.error, isNotNull);
      expect(result.error, isNotEmpty);
    });

    test('isSuccess is true only for success results', () {
      final successResult = AddressSelectionResult.success(
        RandomAddress(
          streetNumber: '1',
          streetName: 'Avenue des Champs-Élysées',
          cityName: 'Paris',
          postcode: '75008',
          latitude: 48.8698,
          longitude: 2.3078,
          generatedAt: DateTime.now().toUtc(),
        ),
      );

      final failureResult = AddressSelectionResult.failure('Error occurred');

      expect(successResult.isSuccess, isTrue);
      expect(failureResult.isSuccess, isFalse);
    });

    test('failure result can have different error messages', () {
      final result1 = AddressSelectionResult.failure('Network timeout');
      final result2 = AddressSelectionResult.failure('City has too few addresses');
      final result3 = AddressSelectionResult.failure('Invalid coordinates');

      expect(result1.error, 'Network timeout');
      expect(result2.error, 'City has too few addresses');
      expect(result3.error, 'Invalid coordinates');
    });
  });
}
