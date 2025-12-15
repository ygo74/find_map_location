import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:find_map_location/services/random_address_service.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/models/random_address.dart';

void main() {
  group('RandomAddressService', () {
    group('generateAddress', () {
      test('returns RandomAddress on successful generation', () async {
        final mockClient = MockClient((request) async {
          if (request.url.toString().contains('/reverse/')) {
            return http.Response('''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [2.3376, 48.8606]
    },
    "properties": {
      "type": "housenumber",
      "housenumber": "42",
      "street": "Rue de Rivoli",
      "city": "Paris",
      "postcode": "75001"
    }
  }]
}
''', 200);
          }
          return http.Response('{}', 404);
        });

        final geocodingService = ApiAdresseGeocodingService(client: mockClient);
        final service = RandomAddressService(geocodingService: geocodingService);

        final city = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: '75',
          postalCode: '75001',
        );

        final result = await service.generateAddress(city);

        expect(result, isNotNull);
        expect(result!.cityName, 'Paris');
        expect(result.streetNumber, '42');
        expect(result.streetName, 'Rue de Rivoli');
      });

      test('returns null after max retry attempts with no valid address', () async {
        final mockClient = MockClient((request) async {
          // Always return empty features (no address found)
          return http.Response('''
{
  "type": "FeatureCollection",
  "features": []
}
''', 200);
        });

        final geocodingService = ApiAdresseGeocodingService(client: mockClient);
        final service = RandomAddressService(geocodingService: geocodingService);

        final city = City(
          name: 'SmallVillage',
          latitude: 48.0,
          longitude: 2.0,
          department: '75',
          postalCode: '75000',
        );

        final result = await service.generateAddress(city);

        expect(result, isNull);
      });

      test('validates address is within city boundaries', () async {
        final mockClient = MockClient((request) async {
          // Return address for different city
          return http.Response('''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [2.3376, 48.8606]
    },
    "properties": {
      "type": "housenumber",
      "housenumber": "42",
      "street": "Rue de Rivoli",
      "city": "Lyon",
      "postcode": "69001"
    }
  }]
}
''', 200);
        });

        final geocodingService = ApiAdresseGeocodingService(client: mockClient);
        final service = RandomAddressService(geocodingService: geocodingService);

        final city = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: '75',
          postalCode: '75001',
        );

        // Should return null because address is for Lyon, not Paris
        final result = await service.generateAddress(city);

        expect(result, isNull);
      });

      test('continues trying on network errors until max attempts', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount < 5) {
            throw SocketException('No internet');
          }
          // Succeed on 5th attempt
          return http.Response('''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [2.3376, 48.8606]
    },
    "properties": {
      "type": "housenumber",
      "housenumber": "10",
      "street": "Avenue des Champs-Élysées",
      "city": "Paris",
      "postcode": "75008"
    }
  }]
}
''', 200);
        });

        final geocodingService = ApiAdresseGeocodingService(client: mockClient);
        final service = RandomAddressService(geocodingService: geocodingService);

        final city = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: '75',
          postalCode: '75008',
        );

        final result = await service.generateAddress(city);

        expect(result, isNotNull);
        expect(result!.streetName, 'Avenue des Champs-Élysées');
        expect(callCount, 5);
      });
    });

    group('generateAddress with uniqueness', () {
      test('skips already used addresses and generates a new one', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            // First address (already used)
            return http.Response('''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [2.3376, 48.8606]
    },
    "properties": {
      "type": "housenumber",
      "housenumber": "42",
      "street": "Rue de Rivoli",
      "city": "Paris",
      "postcode": "75001"
    }
  }]
}
''', 200);
          } else {
            // Second address (new)
            return http.Response('''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [2.3500, 48.8700]
    },
    "properties": {
      "type": "housenumber",
      "housenumber": "10",
      "street": "Avenue des Champs-Élysées",
      "city": "Paris",
      "postcode": "75008"
    }
  }]
}
''', 200);
          }
        });

        final geocodingService = ApiAdresseGeocodingService(client: mockClient);
        final service = RandomAddressService(geocodingService: geocodingService);

        final city = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: '75',
          postalCode: '75001',
        );

        // Create a used address
        final usedAddress = RandomAddress(
          streetNumber: '42',
          streetName: 'Rue de Rivoli',
          cityName: 'Paris',
          postcode: '75001',
          latitude: 48.8606,
          longitude: 2.3376,
          generatedAt: DateTime.now().toUtc(),
        );

        final usedAddresses = {usedAddress};

        final result = await service.generateAddress(city, usedAddresses: usedAddresses);

        expect(result, isNotNull);
        expect(result!.streetName, 'Avenue des Champs-Élysées');
        expect(result.streetNumber, '10');
        expect(callCount, greaterThanOrEqualTo(2));
      });
    });

    group('validateCityHasSufficientAddresses', () {
      test('returns true when city has at least 5 unique addresses', () async {
        final mockClient = MockClient((request) async {
          // Return different address each time based on coordinates
          final lat = request.url.queryParameters['lat'];
          final addresses = [
            '{"type": "FeatureCollection", "features": [{"type": "Feature", "geometry": {"type": "Point", "coordinates": [2.3376, 48.8606]}, "properties": {"type": "housenumber", "housenumber": "1", "street": "Rue A", "city": "Paris", "postcode": "75001"}}]}',
            '{"type": "FeatureCollection", "features": [{"type": "Feature", "geometry": {"type": "Point", "coordinates": [2.3400, 48.8620]}, "properties": {"type": "housenumber", "housenumber": "2", "street": "Rue B", "city": "Paris", "postcode": "75001"}}]}',
            '{"type": "FeatureCollection", "features": [{"type": "Feature", "geometry": {"type": "Point", "coordinates": [2.3450, 48.8650]}, "properties": {"type": "housenumber", "housenumber": "3", "street": "Rue C", "city": "Paris", "postcode": "75001"}}]}',
            '{"type": "FeatureCollection", "features": [{"type": "Feature", "geometry": {"type": "Point", "coordinates": [2.3500, 48.8700]}, "properties": {"type": "housenumber", "housenumber": "4", "street": "Rue D", "city": "Paris", "postcode": "75001"}}]}',
            '{"type": "FeatureCollection", "features": [{"type": "Feature", "geometry": {"type": "Point", "coordinates": [2.3550, 48.8750]}, "properties": {"type": "housenumber", "housenumber": "5", "street": "Rue E", "city": "Paris", "postcode": "75001"}}]}',
          ];

          // Cycle through addresses
          final index = (double.parse(lat!) * 1000).toInt() % addresses.length;
          return http.Response(addresses[index], 200);
        });

        final geocodingService = ApiAdresseGeocodingService(client: mockClient);
        final service = RandomAddressService(geocodingService: geocodingService);

        final city = City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: '75',
          postalCode: '75001',
        );

        final result = await service.validateCityHasSufficientAddresses(city);

        expect(result, isTrue);
      });

      test('returns false when city has fewer than 5 unique addresses', () async {
        final mockClient = MockClient((request) async {
          // Always return same address (only 1 unique address)
          return http.Response('''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "geometry": {
      "type": "Point",
      "coordinates": [2.3376, 48.8606]
    },
    "properties": {
      "type": "housenumber",
      "housenumber": "1",
      "street": "Rue Unique",
      "city": "SmallVillage",
      "postcode": "75000"
    }
  }]
}
''', 200);
        });

        final geocodingService = ApiAdresseGeocodingService(client: mockClient);
        final service = RandomAddressService(geocodingService: geocodingService);

        final city = City(
          name: 'SmallVillage',
          latitude: 48.0,
          longitude: 2.0,
          department: '75',
          postalCode: '75000',
        );

        final result = await service.validateCityHasSufficientAddresses(city);

        expect(result, isFalse);
      });
    });
  });
}
