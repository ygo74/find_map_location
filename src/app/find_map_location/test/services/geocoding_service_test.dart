import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/models/postal_code.dart';

void main() {
  group('ApiAdresseGeocodingService', () {
    test('fetchLocation returns CityLocation on success', () async {
      final mockClient = MockClient((request) async {
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
        "label": "Paris 1er Arrondissement",
        "name": "Paris 1er Arrondissement",
        "postcode": "75001",
        "city": "Paris"
      }
    }
  ]
}
''', 200);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      final location = await service.fetchLocation(postalCode);

      expect(location.latitude, equals(48.862270));
      expect(location.longitude, equals(2.347870));
      expect(location.cityName, equals('Paris 1er Arrondissement'));
    });

    test('fetchLocation throws PostalCodeNotFoundException when no results', () async {
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
        () => service.fetchLocation(postalCode),
        throwsA(isA<PostalCodeNotFoundException>()),
      );
    });

    test('fetchLocation throws NetworkException on SocketException', () async {
      final mockClient = MockClient((request) async {
        throw Exception('No internet');
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      expect(
        () => service.fetchLocation(postalCode),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchLocation throws ServerException on 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      expect(
        () => service.fetchLocation(postalCode),
        throwsA(isA<ServerException>()),
      );
    });

    test('fetchLocation throws ServerException on 503 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final service = ApiAdresseGeocodingService(client: mockClient);
      final postalCode = PostalCode('75001');

      expect(
        () => service.fetchLocation(postalCode),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
