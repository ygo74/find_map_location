import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/grid_cell.dart';
import '../models/lat_lng_bounds.dart';

/// Service providing pure functions for grid cell calculations.
///
/// This service has no UI dependencies and can be unit tested in isolation.
/// All methods are static for easy testing and use.
class GridCalculationService {
  // Private constructor to prevent instantiation
  GridCalculationService._();

  /// Earth's radius in meters (for Haversine calculations)
  static const double _earthRadius = 6371000.0;

  /// Converts a zero-based column index to an Excel-style letter name.
  ///
  /// Examples:
  /// - 0 → "A"
  /// - 25 → "Z"
  /// - 26 → "AA"
  /// - 51 → "AZ"
  /// - 701 → "ZZ"
  ///
  /// Implements base-26 conversion algorithm supporting arbitrary column counts.
  static String indexToColumnName(int columnIndex) {
    String name = '';
    int index = columnIndex;
    while (index >= 0) {
      name = String.fromCharCode(65 + (index % 26)) + name;
      index = (index ~/ 26) - 1;
    }
    return name;
  }

  /// Calculates the geographic bounds of a grid cell given its indices.
  ///
  /// [columnIndex]: Zero-based column index
  /// [rowIndex]: Zero-based row index
  /// [origin]: Grid origin (top-left of cell A1)
  /// [cellSizeMeters]: Cell size in meters
  ///
  /// Returns: [GridBounds] representing the cell's geographic rectangle
  static GridBounds calculateCellBounds(
    int columnIndex,
    int rowIndex,
    LatLng origin,
    double cellSizeMeters,
  ) {
    // Calculate distances from origin in meters
    final double eastMeters = columnIndex * cellSizeMeters;
    final double southMeters = rowIndex * cellSizeMeters;

    // Calculate north-west corner (cell start)
    final LatLng northWest = _offsetCoordinate(
      origin,
      eastMeters,
      southMeters,
    );

    // Calculate south-east corner (cell end)
    final LatLng southEast = _offsetCoordinate(
      origin,
      eastMeters + cellSizeMeters,
      southMeters + cellSizeMeters,
    );

    return GridBounds(northWest, southEast);
  }

  /// Calculates the grid origin (top-left of cell A1) based on city bounds.
  ///
  /// [cityCenter]: Geographic coordinates of the city center
  /// [cellSizeMeters]: Size of each grid cell in meters (250, 500, 1000, or 2000)
  /// [cityBounds]: Optional bounds of the city to align grid properly
  ///
  /// Returns: [LatLng] representing the grid origin (north-west corner of cell A1)
  ///
  /// The grid is aligned so that cell boundaries are regular and the city center
  /// falls on a grid boundary, ensuring the grid covers the entire city.
  static LatLng calculateGridOrigin(
    LatLng cityCenter,
    double cellSizeMeters, {
    GridBounds? cityBounds,
  }) {
    // If city bounds provided, use north-west corner as approximate origin
    if (cityBounds != null) {
      final northWest = LatLng(cityBounds.north, cityBounds.west);

      // Calculate distance from city center to align grid
      final double eastDist = _calculateEastDistance(northWest, cityCenter);
      final double southDist = _calculateSouthDistance(northWest, cityCenter);

      // Snap to grid alignment - find the nearest grid line west and north of the bounds
      final int cellsEast = (eastDist / cellSizeMeters).floor();
      final int cellsSouth = (southDist / cellSizeMeters).floor();

      // Calculate aligned origin
      return _offsetCoordinate(northWest, cellsEast * cellSizeMeters, cellsSouth * cellSizeMeters);
    }

    // Fallback: center the grid on the city center point
    // Align origin so that city center falls on a cell boundary
    return cityCenter;
  }

  /// Determines which grid cell contains a given geographic point.
  ///
  /// [point]: Geographic coordinates to locate
  /// [origin]: Grid origin (top-left of cell A1)
  /// [cellSizeMeters]: Size of each cell in meters
  ///
  /// Returns: [GridCell] containing the point
  ///
  /// Applies north-west boundary rule (FR-005a): Points exactly on north or
  /// west edges belong to the cell. Uses floor() for deterministic assignment.
  static GridCell getCellForPoint(
    LatLng point,
    LatLng origin,
    double cellSizeMeters,
  ) {
    // Calculate distances from origin in meters
    final double eastDistance = _calculateEastDistance(origin, point);
    final double southDistance = _calculateSouthDistance(origin, point);

    // Calculate cell indices (floor implements north-west boundary rule)
    final int columnIndex = (eastDistance / cellSizeMeters).floor();
    final int rowIndex = (southDistance / cellSizeMeters).floor();

    // Generate cell ID
    final String cellId =
        '${indexToColumnName(columnIndex)}${rowIndex + 1}';

    // Calculate cell bounds
    final GridBounds bounds =
        calculateCellBounds(columnIndex, rowIndex, origin, cellSizeMeters);

    // Calculate center point
    final LatLng centerPoint = LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );

    return GridCell(
      id: cellId,
      columnIndex: columnIndex,
      rowIndex: rowIndex,
      bounds: bounds,
      centerPoint: centerPoint,
    );
  }

  /// Generates all grid cells visible within a map viewport.
  ///
  /// [viewportBounds]: Geographic bounds of the map viewport
  /// [origin]: Grid origin (top-left of cell A1)
  /// [cellSizeMeters]: Size of each cell in meters
  /// [maxCells]: Maximum number of cells to generate (default 100)
  ///
  /// Returns: List of [GridCell] objects intersecting the viewport
  ///
  /// Includes +1 cell buffer on each edge for smooth panning.
  /// Stops if maxCells limit reached to prevent performance issues.
  static List<GridCell> generateVisibleCells(
    GridBounds viewportBounds,
    LatLng origin,
    double cellSizeMeters, {
    int maxCells = 100,
  }) {
    // Calculate which cells are visible
    final LatLng northWest = LatLng(viewportBounds.north, viewportBounds.west);
    final LatLng southEast = LatLng(viewportBounds.south, viewportBounds.east);

    // Get cell indices for viewport corners
    final GridCell topLeftCell =
        getCellForPoint(northWest, origin, cellSizeMeters);
    final GridCell bottomRightCell =
        getCellForPoint(southEast, origin, cellSizeMeters);

    // Add buffer of 1 cell on each edge for smooth panning
    final int minCol = math.max(0, topLeftCell.columnIndex - 1);
    final int maxCol = bottomRightCell.columnIndex + 1;
    final int minRow = math.max(0, topLeftCell.rowIndex - 1);
    final int maxRow = bottomRightCell.rowIndex + 1;

    // Generate cells in range
    final List<GridCell> cells = [];
    for (int row = minRow; row <= maxRow; row++) {
      for (int col = minCol; col <= maxCol; col++) {
        if (cells.length >= maxCells) {
          return cells; // Performance limit reached
        }

        final String cellId = '${indexToColumnName(col)}${row + 1}';
        final GridBounds bounds =
            calculateCellBounds(col, row, origin, cellSizeMeters);
        final LatLng centerPoint = LatLng(
          (bounds.north + bounds.south) / 2,
          (bounds.east + bounds.west) / 2,
        );

        cells.add(GridCell(
          id: cellId,
          columnIndex: col,
          rowIndex: row,
          bounds: bounds,
          centerPoint: centerPoint,
        ));
      }
    }

    return cells;
  }

  // Helper methods

  /// Calculates east-west distance between two points in meters.
  /// Positive value means 'to' is east of 'from', negative means west.
  static double _calculateEastDistance(LatLng from, LatLng to) {
    // Use Haversine formula for accurate distance on sphere
    final double dLon = _toRadians(to.longitude - from.longitude);
    final double avgLat = _toRadians((from.latitude + to.latitude) / 2);

    return dLon * _earthRadius * math.cos(avgLat);
  }

  /// Calculates north-south distance between two points in meters.
  /// Positive value means 'to' is south of 'from', negative means north.
  static double _calculateSouthDistance(LatLng from, LatLng to) {
    // Use Haversine formula for accurate distance on sphere
    final double dLat = _toRadians(from.latitude - to.latitude);

    return dLat * _earthRadius; // Positive = south (decreasing latitude)
  }

  /// Offsets a coordinate by given distances in meters.
  ///
  /// [origin]: Starting coordinate
  /// [eastMeters]: Distance to move east (negative = west)
  /// [southMeters]: Distance to move south (negative = north)
  static LatLng _offsetCoordinate(
    LatLng origin,
    double eastMeters,
    double southMeters,
  ) {
    // Calculate new latitude (north-south)
    // Positive southMeters decreases latitude (moving south)
    final double dLat = -southMeters / _earthRadius;
    final double newLat = origin.latitude + _toDegrees(dLat);

    // Calculate new longitude (east-west), accounting for latitude
    // Positive eastMeters increases longitude (moving east)
    final double avgLat = _toRadians((origin.latitude + newLat) / 2);
    final double dLon = eastMeters / (_earthRadius * math.cos(avgLat));
    final double newLon = origin.longitude + _toDegrees(dLon);

    return LatLng(newLat, newLon);
  }

  /// Converts degrees to radians
  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Converts radians to degrees
  static double _toDegrees(double radians) => radians * 180.0 / math.pi;

  /// Calculates city bounds based on a center point and radius.
  ///
  /// [cityCenter]: Geographic coordinates of the city center
  /// [radiusMeters]: Radius in meters (default 5000m = 5km for typical city)
  ///
  /// Returns: [GridBounds] representing the city boundaries
  static GridBounds calculateCityBounds(
    LatLng cityCenter,
    double radiusMeters,
  ) {
    final northWest = _offsetCoordinate(cityCenter, -radiusMeters, -radiusMeters);
    final southEast = _offsetCoordinate(cityCenter, radiusMeters, radiusMeters);
    return GridBounds(northWest, southEast);
  }
}
