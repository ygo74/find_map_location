import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/city_bounds.dart';
import 'package:find_map_location/models/city.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('CityBounds', () {
    test('fromCityCenter creates bounds with default delta', () {
      final city = City(
        name: 'Paris',
        postalCode: '75001',
        latitude: 48.8566,
        longitude: 2.3522,
        department: 'Paris',
      );

      final bounds = CityBounds.fromCityCenter(city);

      expect(bounds.minLatitude, 48.8566 - 0.05);
      expect(bounds.maxLatitude, 48.8566 + 0.05);
      expect(bounds.minLongitude, 2.3522 - 0.05);
      expect(bounds.maxLongitude, 2.3522 + 0.05);
    });

    test('fromCityCenter creates bounds with custom delta', () {
      final city = City(
        name: 'Lyon',
        postalCode: '69001',
        latitude: 45.7640,
        longitude: 4.8357,
        department: 'Rhône',
      );

      final bounds = CityBounds.fromCityCenter(city, delta: 0.1);

      expect(bounds.minLatitude, 45.7640 - 0.1);
      expect(bounds.maxLatitude, 45.7640 + 0.1);
      expect(bounds.minLongitude, 4.8357 - 0.1);
      expect(bounds.maxLongitude, 4.8357 + 0.1);
    });

    test('generateRandomPoint returns point within bounds', () {
      final bounds = CityBounds(
        minLatitude: 48.8,
        maxLatitude: 48.9,
        minLongitude: 2.3,
        maxLongitude: 2.4,
      );

      // Generate multiple points to verify they're all within bounds
      for (int i = 0; i < 100; i++) {
        final point = bounds.generateRandomPoint();

        expect(point.latitude, greaterThanOrEqualTo(48.8));
        expect(point.latitude, lessThanOrEqualTo(48.9));
        expect(point.longitude, greaterThanOrEqualTo(2.3));
        expect(point.longitude, lessThanOrEqualTo(2.4));
      }
    });

    test('contains validates point within bounds', () {
      final bounds = CityBounds(
        minLatitude: 48.8,
        maxLatitude: 48.9,
        minLongitude: 2.3,
        maxLongitude: 2.4,
      );

      expect(bounds.contains(LatLng(48.85, 2.35)), isTrue);
      expect(bounds.contains(LatLng(48.8, 2.3)), isTrue); // Boundary
      expect(bounds.contains(LatLng(48.9, 2.4)), isTrue); // Boundary
      expect(bounds.contains(LatLng(48.7, 2.35)), isFalse); // Below min
      expect(bounds.contains(LatLng(49.0, 2.35)), isFalse); // Above max
      expect(bounds.contains(LatLng(48.85, 2.2)), isFalse); // Below min
      expect(bounds.contains(LatLng(48.85, 2.5)), isFalse); // Above max
    });

    test('generateRandomPoint generates different points', () {
      final bounds = CityBounds(
        minLatitude: 48.8,
        maxLatitude: 48.9,
        minLongitude: 2.3,
        maxLongitude: 2.4,
      );

      final point1 = bounds.generateRandomPoint();
      final point2 = bounds.generateRandomPoint();

      // Very unlikely to be exactly the same (randomness)
      expect(point1.latitude != point2.latitude || point1.longitude != point2.longitude, isTrue);
    });
  });
}
