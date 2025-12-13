import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/models/postal_code_result.dart';

void main() {
  group('PostalCodeResult', () {
    final paris = City(
      name: 'Paris',
      latitude: 48.8566,
      longitude: 2.3522,
      department: 'Paris',
      postalCode: '75001',
    );

    final lyon = City(
      name: 'Lyon',
      latitude: 45.75,
      longitude: 4.85,
      department: 'Rhône',
      postalCode: '69001',
    );

    final marseille = City(
      name: 'Marseille',
      latitude: 43.2965,
      longitude: 5.3698,
      department: 'Bouches-du-Rhône',
      postalCode: '13001',
    );

    group('isSingleCity', () {
      test('returns true for single city result', () {
        final result = PostalCodeResult(
          postalCode: '75001',
          cities: [paris],
        );

        expect(result.isSingleCity, isTrue);
      });

      test('returns false for multiple cities', () {
        final result = PostalCodeResult(
          postalCode: '01000',
          cities: [paris, lyon],
        );

        expect(result.isSingleCity, isFalse);
      });

      test('returns false for empty list', () {
        final result = PostalCodeResult(
          postalCode: '00000',
          cities: [],
        );

        expect(result.isSingleCity, isFalse);
      });
    });

    group('requiresSelection', () {
      test('returns false for single city result', () {
        final result = PostalCodeResult(
          postalCode: '75001',
          cities: [paris],
        );

        expect(result.requiresSelection, isFalse);
      });

      test('returns true for multiple cities', () {
        final result = PostalCodeResult(
          postalCode: '01000',
          cities: [paris, lyon],
        );

        expect(result.requiresSelection, isTrue);
      });

      test('returns false for empty list', () {
        final result = PostalCodeResult(
          postalCode: '00000',
          cities: [],
        );

        expect(result.requiresSelection, isFalse);
      });
    });

    group('singleCity', () {
      test('returns the city for single city result', () {
        final result = PostalCodeResult(
          postalCode: '75001',
          cities: [paris],
        );

        expect(result.singleCity, equals(paris));
      });

      test('throws StateError for multiple cities', () {
        final result = PostalCodeResult(
          postalCode: '01000',
          cities: [paris, lyon],
        );

        expect(() => result.singleCity, throwsStateError);
      });

      test('throws StateError for empty list', () {
        final result = PostalCodeResult(
          postalCode: '00000',
          cities: [],
        );

        expect(() => result.singleCity, throwsStateError);
      });
    });

    group('sortedCities', () {
      test('returns cities sorted alphabetically by name', () {
        final result = PostalCodeResult(
          postalCode: '01000',
          cities: [marseille, paris, lyon],
        );

        final sorted = result.sortedCities;

        expect(sorted.length, 3);
        expect(sorted[0].name, 'Lyon');
        expect(sorted[1].name, 'Marseille');
        expect(sorted[2].name, 'Paris');
      });

      test('returns new list without modifying original', () {
        final originalOrder = [marseille, paris, lyon];
        final result = PostalCodeResult(
          postalCode: '01000',
          cities: originalOrder,
        );

        final sorted = result.sortedCities;

        // Original list unchanged
        expect(result.cities[0], equals(marseille));
        expect(result.cities[1], equals(paris));
        expect(result.cities[2], equals(lyon));

        // Sorted list is different
        expect(sorted[0], equals(lyon));
        expect(sorted[1], equals(marseille));
        expect(sorted[2], equals(paris));
      });

      test('handles single city', () {
        final result = PostalCodeResult(
          postalCode: '75001',
          cities: [paris],
        );

        final sorted = result.sortedCities;

        expect(sorted.length, 1);
        expect(sorted[0], equals(paris));
      });

      test('handles empty list', () {
        final result = PostalCodeResult(
          postalCode: '00000',
          cities: [],
        );

        final sorted = result.sortedCities;

        expect(sorted, isEmpty);
      });

      test('sorts case-insensitively', () {
        final ajaccio = City(
          name: 'Ajaccio',
          latitude: 41.9192,
          longitude: 8.7386,
          department: 'Corse-du-Sud',
          postalCode: '20000',
        );

        final bastia = City(
          name: 'Bastia',
          latitude: 42.7032,
          longitude: 9.4508,
          department: 'Haute-Corse',
          postalCode: '20200',
        );

        final result = PostalCodeResult(
          postalCode: '20000',
          cities: [bastia, ajaccio],
        );

        final sorted = result.sortedCities;

        expect(sorted[0].name, 'Ajaccio');
        expect(sorted[1].name, 'Bastia');
      });
    });

    group('equality', () {
      test('equal results are equal', () {
        final result1 = PostalCodeResult(
          postalCode: '75001',
          cities: [paris],
        );

        final result2 = PostalCodeResult(
          postalCode: '75001',
          cities: [paris],
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('different postal codes are not equal', () {
        final result1 = PostalCodeResult(
          postalCode: '75001',
          cities: [paris],
        );

        final result2 = PostalCodeResult(
          postalCode: '69001',
          cities: [paris],
        );

        expect(result1, isNot(equals(result2)));
      });

      test('different city lists are not equal', () {
        final result1 = PostalCodeResult(
          postalCode: '01000',
          cities: [paris],
        );

        final result2 = PostalCodeResult(
          postalCode: '01000',
          cities: [lyon],
        );

        expect(result1, isNot(equals(result2)));
      });

      test('different list lengths are not equal', () {
        final result1 = PostalCodeResult(
          postalCode: '01000',
          cities: [paris],
        );

        final result2 = PostalCodeResult(
          postalCode: '01000',
          cities: [paris, lyon],
        );

        expect(result1, isNot(equals(result2)));
      });
    });

    group('toString', () {
      test('shows postal code and city count', () {
        final result = PostalCodeResult(
          postalCode: '01000',
          cities: [paris, lyon],
        );

        expect(result.toString(), 'PostalCodeResult(01000, 2 cities)');
      });
    });
  });
}
