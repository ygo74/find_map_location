import 'package:latlong2/latlong.dart';

/// Represents a geographic bounding box with north, south, east, and west bounds.
///
/// Used by the grid calculation service to define cell boundaries and viewport areas.
class GridBounds {
  /// Northern boundary (maximum latitude)
  final double north;

  /// Southern boundary (minimum latitude)
  final double south;

  /// Eastern boundary (maximum longitude)
  final double east;

  /// Western boundary (minimum longitude)
  final double west;

  /// Creates a bounding box from two corner points.
  ///
  /// The constructor automatically determines which point is north-west
  /// and which is south-east.
  GridBounds(LatLng corner1, LatLng corner2)
      : north = corner1.latitude > corner2.latitude
            ? corner1.latitude
            : corner2.latitude,
        south = corner1.latitude < corner2.latitude
            ? corner1.latitude
            : corner2.latitude,
        east = corner1.longitude > corner2.longitude
            ? corner1.longitude
            : corner2.longitude,
        west = corner1.longitude < corner2.longitude
            ? corner1.longitude
            : corner2.longitude;

  /// Creates a bounding box with explicit boundaries.
  GridBounds.fromPoints({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  /// Returns the north-west corner of the bounding box.
  LatLng get northWest => LatLng(north, west);

  /// Returns the south-east corner of the bounding box.
  LatLng get southEast => LatLng(south, east);

  /// Returns the center point of the bounding box.
  LatLng get center => LatLng((north + south) / 2, (east + west) / 2);

  @override
  String toString() {
    return 'GridBounds(N:$north, S:$south, E:$east, W:$west)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridBounds &&
        other.north == north &&
        other.south == south &&
        other.east == east &&
        other.west == west;
  }

  @override
  int get hashCode {
    return Object.hash(north, south, east, west);
  }
}
