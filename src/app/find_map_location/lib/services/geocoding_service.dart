import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:find_map_location/models/postal_code.dart';
import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/models/postal_code_result.dart';

/// Abstract interface for geocoding services
abstract class GeocodingService {
  /// Fetches all cities for a given postal code
  Future<PostalCodeResult> fetchLocations(PostalCode postalCode);
}

/// Implementation using API Adresse (French government API)
class ApiAdresseGeocodingService implements GeocodingService {
  static const String baseUrl = 'https://api-adresse.data.gouv.fr/search';
  static const Duration timeout = Duration(seconds: 10);
  static const int limit = 50; // Maximum results for multi-city postal codes

  final http.Client client;

  ApiAdresseGeocodingService({http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<PostalCodeResult> fetchLocations(PostalCode postalCode) async {
    final uri = Uri.parse('$baseUrl/?q=${postalCode.value}&type=municipality&limit=$limit');

    try {
      final response = await client.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final features = json['features'] as List<dynamic>;

        if (features.isEmpty) {
          throw PostalCodeNotFoundException(postalCode.value);
        }

        // Parse all cities from features
        final cities = features
            .cast<Map<String, dynamic>>()
            .map((feature) => City.fromJson(feature, postalCode.value))
            .toList();

        return PostalCodeResult(
          postalCode: postalCode.value,
          cities: cities,
        );
      } else if (response.statusCode >= 500) {
        throw ServerException('Server error: ${response.statusCode}');
      } else {
        throw ServerException('Unexpected error: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw ServerException('Request timeout');
    } on FormatException {
      throw ServerException('Invalid response format');
    }
  }
}

/// Exception thrown when postal code is not found
class PostalCodeNotFoundException implements Exception {
  final String postalCode;
  PostalCodeNotFoundException(this.postalCode);

  @override
  String toString() => 'PostalCodeNotFoundException: $postalCode';
}

/// Exception thrown when network connectivity issues occur
class NetworkException implements Exception {
  @override
  String toString() => 'NetworkException: No internet connection';
}

/// Exception thrown when server errors occur
class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}
