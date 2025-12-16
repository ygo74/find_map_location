import 'package:find_map_location/models/city.dart';

/// Represents a random address within a city for the location game.
///
/// The address coordinates are used for validation but NOT displayed on the map.
/// The address is shown only as text to create the game challenge.
class RandomAddress {
  /// House/building number (e.g., "42", "12bis")
  final String streetNumber;

  /// Street name with type (e.g., "Rue de Rivoli")
  final String streetName;

  /// City name
  final String cityName;

  /// Postal code (5 digits for France)
  final String postcode;

  /// Latitude coordinate (-90.0 to 90.0)
  final double latitude;

  /// Longitude coordinate (-180.0 to 180.0)
  final double longitude;

  /// Timestamp when address was generated (UTC)
  final DateTime generatedAt;

  /// Creates a RandomAddress instance.
  ///
  /// All fields are required. Coordinates should be within reasonable bounds
  /// for France (41°N-51°N, -5°E-10°E).
  const RandomAddress({
    required this.streetNumber,
    required this.streetName,
    required this.cityName,
    required this.postcode,
    required this.latitude,
    required this.longitude,
    required this.generatedAt,
  });

  /// Formats address for display in UI: "42 Rue de Rivoli, Paris"
  ///
  /// Example:
  /// ```dart
  /// final address = RandomAddress(...);
  /// print(address.toDisplayString()); // "42 Rue de Rivoli, Paris"
  /// ```
  String toDisplayString() {
    return '$streetNumber $streetName, $cityName';
  }

  /// Generates unique key for deduplication: "Paris|Rue de Rivoli|42"
  ///
  /// Used by GameSessionState to track used addresses and prevent duplicates.
  /// The key is based on address components only (not coordinates or timestamp).
  ///
  /// Example:
  /// ```dart
  /// final key = address.toUniqueKey();
  /// usedAddresses.add(key); // Track this address as used
  /// ```
  String toUniqueKey() {
    return '$cityName|$streetName|$streetNumber';
  }

  /// Validates that this address belongs to the given city.
  ///
  /// Performs case-insensitive comparison of city names.
  ///
  /// Example:
  /// ```dart
  /// if (address.isInCity(selectedCity)) {
  ///   print('Address is valid for this city');
  /// }
  /// ```
  bool isInCity(City city) {
    return cityName.toLowerCase() == city.name.toLowerCase();
  }

  /// Equality is based on address components (street number, name, city).
  ///
  /// Coordinates and timestamp are NOT considered for equality,
  /// allowing addresses to be deduplicated in Sets.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RandomAddress &&
        other.streetNumber == streetNumber &&
        other.streetName == streetName &&
        other.cityName == cityName;
  }

  /// Hash code based on address components for Set/Map operations.
  @override
  int get hashCode => Object.hash(streetNumber, streetName, cityName);

  @override
  String toString() {
    return 'RandomAddress($streetNumber $streetName, $cityName $postcode)';
  }
}
