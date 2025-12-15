import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:find_map_location/models/city.dart';

/// Represents a geographic bounding box for random coordinate generation.
///
/// Used to constrain random address generation within a city's approximate area.
/// The bounding box is defined by minimum and maximum latitude/longitude values.
class CityBounds {
  /// Southern boundary (minimum latitude)
  final double minLatitude;

  /// Northern boundary (maximum latitude)
  final double maxLatitude;

  /// Western boundary (minimum longitude)
  final double minLongitude;

  /// Eastern boundary (maximum longitude)
  final double maxLongitude;

  /// Random number generator for coordinate generation
  static final Random _random = Random();

  /// Creates a bounding box with explicit boundaries.
  ///
  /// All coordinates must be valid: minLatitude <= maxLatitude and minLongitude <= maxLongitude.
  const CityBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  })  : assert(minLatitude <= maxLatitude, 'minLatitude must be <= maxLatitude'),
        assert(minLongitude <= maxLongitude, 'minLongitude must be <= maxLongitude');

  /// Creates a bounding box centered on a city's coordinates.
  ///
  /// [city] - The city to center the bounds on
  /// [delta] - The distance in degrees to extend in all directions (default: 0.05° ≈ 5.5km)
  ///
  /// Example:
  /// ```dart
  /// final paris = City(name: 'Paris', latitude: 48.8566, longitude: 2.3522, ...);
  /// final bounds = CityBounds.fromCityCenter(paris);
  /// // Creates bounds from (48.8066, 2.3022) to (48.9066, 2.4022)
  /// ```
  factory CityBounds.fromCityCenter(City city, {double delta = 0.05}) {
    return CityBounds(
      minLatitude: city.latitude - delta,
      maxLatitude: city.latitude + delta,
      minLongitude: city.longitude - delta,
      maxLongitude: city.longitude + delta,
    );
  }

  /// Generates a random point within this bounding box.
  ///
  /// Returns a [LatLng] with coordinates uniformly distributed within the bounds.
  /// Each call produces different coordinates (with high probability).
  ///
  /// Example:
  /// ```dart
  /// final bounds = CityBounds(minLatitude: 48.8, maxLatitude: 48.9, ...);
  /// final randomPoint = bounds.generateRandomPoint();
  /// print('Random coordinates: ${randomPoint.latitude}, ${randomPoint.longitude}');
  /// ```
  LatLng generateRandomPoint() {
    final lat = minLatitude + _random.nextDouble() * (maxLatitude - minLatitude);
    final lon = minLongitude + _random.nextDouble() * (maxLongitude - minLongitude);
    return LatLng(lat, lon);
  }

  /// Checks if a point is within this bounding box.
  ///
  /// Returns true if the point's coordinates are within or on the boundaries.
  ///
  /// Example:
  /// ```dart
  /// final bounds = CityBounds(minLatitude: 48.8, maxLatitude: 48.9, ...);
  /// final point = LatLng(48.85, 2.35);
  /// if (bounds.contains(point)) {
  ///   print('Point is within bounds');
  /// }
  /// ```
  bool contains(LatLng point) {
    return point.latitude >= minLatitude &&
        point.latitude <= maxLatitude &&
        point.longitude >= minLongitude &&
        point.longitude <= maxLongitude;
  }

  @override
  String toString() {
    return 'CityBounds(lat: $minLatitude to $maxLatitude, lon: $minLongitude to $maxLongitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CityBounds &&
        other.minLatitude == minLatitude &&
        other.maxLatitude == maxLatitude &&
        other.minLongitude == minLongitude &&
        other.maxLongitude == maxLongitude;
  }

  @override
  int get hashCode => Object.hash(minLatitude, maxLatitude, minLongitude, maxLongitude);
}
