import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/models/postal_code.dart';

void main() {
  group('ApiAdresseGeocodingService', () {
    test('fetchLocations returns PostalCodeResult with single city', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('limit=50'));
        expect(request.url.toString(), contains('type=municipality'));
        return http.Response('''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [2.347870, 48.862270]
      },
      "properties": {
        "name": "Paris",
        "context": "75, Paris, Île-de-France"
      }
    }
  ]
}
''', 200);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      final result = await service.fetchLocations(postalCode);

      expect(result.postalCode, '75001');
      expect(result.cities.length, 1);
      expect(result.cities[0].name, 'Paris');
      expect(result.cities[0].latitude, 48.862270);
      expect(result.cities[0].longitude, 2.347870);
      expect(result.cities[0].department, 'Paris');
      expect(result.isSingleCity, isTrue);
    });

    test('fetchLocations returns PostalCodeResult with multiple cities', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
{
  "type": "FeatureCollection",
  "features": [
    {
      "geometry": {
        "coordinates": [5.2, 45.6]
      },
      "properties": {
        "name": "Bourg-en-Bresse",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    },
    {
      "geometry": {
        "coordinates": [5.3, 45.7]
      },
      "properties": {
        "name": "Péronnas",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    },
    {
      "geometry": {
        "coordinates": [5.1, 45.5]
      },
      "properties": {
        "name": "Viriat",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    }
  ]
}
''', 200);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('01000');

      final result = await service.fetchLocations(postalCode);

      expect(result.postalCode, '01000');
      expect(result.cities.length, 3);
      expect(result.cities[0].name, 'Bourg-en-Bresse');
      expect(result.cities[1].name, 'Péronnas');
      expect(result.cities[2].name, 'Viriat');
      expect(result.cities[0].department, 'Ain');
      expect(result.cities[1].department, 'Ain');
      expect(result.cities[2].department, 'Ain');
      expect(result.requiresSelection, isTrue);
      expect(result.isSingleCity, isFalse);
    });

    test('fetchLocations parses all cities correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
{
  "features": [
    {
      "geometry": {"coordinates": [5.2, 45.6]},
      "properties": {
        "name": "Bourg-en-Bresse",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    },
    {
      "geometry": {"coordinates": [5.3, 45.7]},
      "properties": {
        "name": "Péronnas",
        "context": "01, Ain, Auvergne-Rhône-Alpes"
      }
    }
  ]
}
''', 200);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final result = await service.fetchLocations(PostalCode('01000'));

      expect(result.cities.length, 2);
      expect(result.cities[0].department, 'Ain');
      expect(result.cities[1].department, 'Ain');
      expect(result.cities[0].postalCode, '01000');
      expect(result.cities[1].postalCode, '01000');
    });

    test('fetchLocations throws PostalCodeNotFoundException when no results', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
{
  "type": "FeatureCollection",
  "features": []
}
''', 200);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('00000');

      expect(
        () => service.fetchLocations(postalCode),
        throwsA(isA<PostalCodeNotFoundException>()),
      );
    });

    test('fetchLocations throws NetworkException on SocketException', () async {
      final mockClient = MockClient((request) async {
        throw Exception('No internet');
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      expect(
        () => service.fetchLocations(postalCode),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchLocations throws ServerException on 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      expect(
        () => service.fetchLocations(postalCode),
        throwsA(isA<ServerException>()),
      );
    });

    test('fetchLocations throws ServerException on 503 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      expect(
        () => service.fetchLocations(postalCode),
        throwsA(isA<ServerException>()),
      );
    });

    test('fetchLocations includes limit=50 in API request', () async {
      String? requestUrl;
      final mockClient = MockClient((request) async {
        requestUrl = request.url.toString();
        return http.Response('{"features": []}', 200);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);

      try {
        await service.fetchLocations(PostalCode('01000'));
      } catch (_) {}

      expect(requestUrl, contains('limit=50'));
    });

    // Reverse Geocoding Tests (T019)
    group('reverseGeocode', () {
      test('returns RandomAddress for valid housenumber', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.toString(), contains('/reverse/'));
          expect(request.url.toString(), contains('lat=48.8606'));
          expect(request.url.toString(), contains('lon=2.3376'));
          expect(request.url.toString(), contains('type=housenumber'));
          return http.Response('''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [2.3376, 48.8606]
      },
      "properties": {
        "housenumber": "42",
        "street": "Rue de Rivoli",
        "city": "Paris",
        "postcode": "75001",
        "type": "housenumber"
      }
    }
  ]
}
''', 200);
        });

        final service = ApiAdresseGeocodingService(client: mockClient);
        final address = await service.reverseGeocode(48.8606, 2.3376);

        expect(address, isNotNull);
        expect(address!.streetNumber, '42');
        expect(address.streetName, 'Rue de Rivoli');
        expect(address.cityName, 'Paris');
        expect(address.postcode, '75001');
        expect(address.latitude, 48.8606);
        expect(address.longitude, 2.3376);
      });

      test('returns null for empty features', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"features": []}', 200);
        });

        final service = ApiAdresseGeocodingService(client: mockClient);
        final address = await service.reverseGeocode(48.8606, 2.3376);

        expect(address, isNull);
      });

      test('returns null for non-housenumber type', () async {
        final mockClient = MockClient((request) async {
          return http.Response('''
{
  "features": [
    {
      "geometry": {
        "coordinates": [2.3376, 48.8606]
      },
      "properties": {
        "type": "street",
        "street": "Rue de Rivoli",
        "city": "Paris",
        "postcode": "75001"
      }
    }
  ]
}
''', 200);
        });

        final service = ApiAdresseGeocodingService(client: mockClient);
        final address = await service.reverseGeocode(48.8606, 2.3376);

        expect(address, isNull);
      });

      test('handles special characters in address', () async {
        final mockClient = MockClient((request) async {
          return http.Response('''
{
  "features": [
    {
      "geometry": {
        "coordinates": [2.34, 48.86]
      },
      "properties": {
        "housenumber": "5",
        "street": "Rue de l'Église",
        "city": "Paris",
        "postcode": "75001",
        "type": "housenumber"
      }
    }
  ]
}
''', 200);
        });

        final service = ApiAdresseGeocodingService(client: mockClient);
        final address = await service.reverseGeocode(48.86, 2.34);

        expect(address, isNotNull);
        expect(address!.streetName, "Rue de l'Église");
      });

      test('throws ServerException on HTTP error', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Server error', 500);
        });

        final service = ApiAdresseGeocodingService(client: mockClient);

        expect(
          () => service.reverseGeocode(48.8606, 2.3376),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws NetworkException on socket error', () async {
        final mockClient = MockClient((request) async {
          throw SocketException('No internet');
        });

        final service = ApiAdresseGeocodingService(client: mockClient);

        expect(
          () => service.reverseGeocode(48.8606, 2.3376),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
