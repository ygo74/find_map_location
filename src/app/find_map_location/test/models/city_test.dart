import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/city.dart';

void main() {
  group('City', () {
    group('fromJson', () {
      test('parses valid API Adresse GeoJSON feature', () {
        final json = {
          'geometry': {
            'coordinates': [2.3522, 48.8566]
          },
          'properties': {
            'name': 'Paris',
            'context': '75, Paris, Île-de-France'
          }
        };

        final city = City.fromJson(json, '75001');

        expect(city.name, 'Paris');
        expect(city.latitude, 48.8566);
        expect(city.longitude, 2.3522);
        expect(city.department, 'Paris');
        expect(city.postalCode, '75001');
      });

      test('extracts department name from context', () {
        final json = {
          'geometry': {
            'coordinates': [5.7245, 45.1885]
          },
          'properties': {
            'name': 'Grenoble',
            'context': '38, Isère, Auvergne-Rhône-Alpes'
          }
        };

        final city = City.fromJson(json, '38000');

        expect(city.department, 'Isère');
      });

      test('handles missing department context', () {
        final json = {
          'geometry': {
            'coordinates': [2.3522, 48.8566]
          },
          'properties': {
            'name': 'Paris',
          }
        };

        final city = City.fromJson(json, '75001');

        expect(city.department, isNull);
      });

      test('handles malformed context string', () {
        final json = {
          'geometry': {
            'coordinates': [2.3522, 48.8566]
          },
          'properties': {
            'name': 'Paris',
            'context': 'Île-de-France'
          }
        };

        final city = City.fromJson(json, '75001');

        expect(city.department, isNull);
      });

      test('handles empty context string', () {
        final json = {
          'geometry': {
            'coordinates': [2.3522, 48.8566]
          },
          'properties': {
            'name': 'Paris',
            'context': ''
          }
        };

        final city = City.fromJson(json, '75001');

        expect(city.department, isNull);
      });

      test('preserves postal code from parameter', () {
        final json = {
          'geometry': {
            'coordinates': [2.3522, 48.8566]
          },
          'properties': {
            'name': 'Paris',
            'context': '75, Paris, Île-de-France'
          }
        };

        final city = City.fromJson(json, '75008');

        expect(city.postalCode, '75008');
      });
    });

    group('displayLabel', () {
      test('includes department when available', () {
        final city = City(
          name: 'Lyon',
          latitude: 45.75,
          longitude: 4.85,
          department: 'Rhône',
          postalCode: '69001',
        );

        expect(city.displayLabel, 'Lyon (Rhône)');
      });

      test('shows name only when department is null', () {
        final city = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: null,
          postalCode: '75001',
        );

        expect(city.displayLabel, 'Paris');
      });

      test('handles Corsica department names', () {
        final city = City(
          name: 'Ajaccio',
          latitude: 41.9192,
          longitude: 8.7386,
          department: 'Corse-du-Sud',
          postalCode: '20000',
        );

        expect(city.displayLabel, 'Ajaccio (Corse-du-Sud)');
      });
    });

    group('equality', () {
      test('equal cities are equal', () {
        final city1 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Paris',
          postalCode: '75001',
        );

        final city2 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Paris',
          postalCode: '75001',
        );

        expect(city1, equals(city2));
        expect(city1.hashCode, equals(city2.hashCode));
      });

      test('different names are not equal', () {
        final city1 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Paris',
          postalCode: '75001',
        );

        final city2 = City(
          name: 'Lyon',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Paris',
          postalCode: '75001',
        );

        expect(city1, isNot(equals(city2)));
      });

      test('different coordinates are not equal', () {
        final city1 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Paris',
          postalCode: '75001',
        );

        final city2 = City(
          name: 'Paris',
          latitude: 45.75,
          longitude: 4.85,
          department: 'Paris',
          postalCode: '75001',
        );

        expect(city1, isNot(equals(city2)));
      });

      test('different departments are not equal', () {
        final city1 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Paris',
          postalCode: '75001',
        );

        final city2 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Rhône',
          postalCode: '75001',
        );

        expect(city1, isNot(equals(city2)));
      });

      test('null vs non-null department are not equal', () {
        final city1 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: 'Paris',
          postalCode: '75001',
        );

        final city2 = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: null,
          postalCode: '75001',
        );

        expect(city1, isNot(equals(city2)));
      });
    });
  });
}
