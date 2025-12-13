import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/city_location.dart';

void main() {
  test('fromJson parses API response correctly', () {
    final json = {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [2.347870, 48.862270] // API returns [lon, lat]
      },
      'properties': {
        'label': 'Paris 1er Arrondissement',
        'name': 'Paris 1er Arrondissement',
        'postcode': '75001',
        'city': 'Paris',
      }
    };

    final location = CityLocation.fromJson(json);

    // Verify coordinate order is swapped: [lon, lat] -> (lat, lon)
    expect(location.latitude, equals(48.862270));
    expect(location.longitude, equals(2.347870));
    expect(location.cityName, equals('Paris 1er Arrondissement'));
    expect(location.postalCode, equals('75001'));
  });

  test('coordinates returns LatLng with correct order', () {
    final json = {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [2.347870, 48.862270]
      },
      'properties': {
        'label': 'Paris 1er Arrondissement',
        'name': 'Paris 1er Arrondissement',
        'postcode': '75001',
        'city': 'Paris',
      }
    };

    final location = CityLocation.fromJson(json);
    final coordinates = location.coordinates;

    expect(coordinates.latitude, equals(48.862270));
    expect(coordinates.longitude, equals(2.347870));
  });
}
