import 'package:latlong2/latlong.dart';

/// Represents a city location with geographic coordinates.
///
/// Contains latitude, longitude, city name, and postal code information
/// retrieved from the geocoding API.
class CityLocation {
  final double latitude;
  final double longitude;
  final String cityName;
  final String postalCode;

  CityLocation({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.postalCode,
  });

  /// Creates a CityLocation from API response JSON
  /// Note: API returns coordinates as [longitude, latitude] but we need [latitude, longitude]
  factory CityLocation.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;

    // API Adresse returns [lon, lat] but LatLng expects (lat, lon)
    final lon = coordinates[0] as double;
    final lat = coordinates[1] as double;

    return CityLocation(
      latitude: lat,
      longitude: lon,
      cityName: properties['name'] as String,
      postalCode: properties['postcode'] as String,
    );
  }

  /// Returns coordinates as LatLng for flutter_map
  LatLng get coordinates => LatLng(latitude, longitude);
}
