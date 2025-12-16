import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/models/city_bounds.dart';
import 'package:find_map_location/models/random_address.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:flutter/foundation.dart';

/// Service for generating random addresses within cities
///
/// Uses random coordinate generation within city bounds combined with
/// reverse geocoding to find real, valid addresses. Supports uniqueness
/// checking and city address validation.
class RandomAddressService {
  final GeocodingService geocodingService;
  final int maxAttempts;

  /// Creates a service with the given geocoding service
  ///
  /// [maxAttempts] controls how many random coordinates to try before giving up
  RandomAddressService({
    required this.geocodingService,
    this.maxAttempts = 10,
  });

  /// Generates a random address for the given city
  ///
  /// Returns null if no valid address can be found after [maxAttempts] tries.
  /// If [usedAddresses] is provided, ensures the generated address is unique.
  Future<RandomAddress?> generateAddress(
    City city, {
    Set<RandomAddress>? usedAddresses,
  }) async {
    final bounds = CityBounds.fromCityCenter(city);
    final used = usedAddresses ?? {};

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final randomPoint = bounds.generateRandomPoint();

      try {
        final address = await geocodingService.reverseGeocode(
          randomPoint.latitude,
          randomPoint.longitude,
        );

        // Check if we got a valid address
        if (address != null && address.isInCity(city)) {
          // Check uniqueness if used addresses provided
          if (used.contains(address)) {
            debugPrint('Address already used, trying again: ${address.toDisplayString()}');
            continue;
          }

          return address;
        }
      } catch (e) {
        // Log error but continue trying other coordinates
        debugPrint('Reverse geocoding attempt $attempt failed: $e');
      }
    }

    // No valid address found after max attempts
    return null;
  }

  /// Validates that a city has at least 5 unique addresses
  ///
  /// Attempts to generate multiple unique addresses to ensure the city
  /// has sufficient address diversity for gameplay.
  Future<bool> validateCityHasSufficientAddresses(City city) async {
    const requiredAddresses = 5;
    final foundAddresses = <RandomAddress>{};
    final maxValidationAttempts = requiredAddresses * 10; // 50 attempts

    for (int attempt = 0; attempt < maxValidationAttempts; attempt++) {
      final address = await generateAddress(city, usedAddresses: foundAddresses);

      if (address != null) {
        foundAddresses.add(address);

        if (foundAddresses.length >= requiredAddresses) {
          return true;
        }
      }
    }

    return false;
  }
}
