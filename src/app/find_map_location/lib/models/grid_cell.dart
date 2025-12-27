import 'package:latlong2/latlong.dart';
import 'lat_lng_bounds.dart';

/// Represents a single cell in the grid overlay.
///
/// Each cell has an alphanumeric identifier (e.g., "A1", "C7", "AB25"),
/// geographic boundaries, and a center point. GridCell is immutable once created.
class GridCell {
  /// Alphanumeric identifier (e.g., "A1", "C7", "AB25")
  final String id;

  /// Zero-based column index (0 = A, 1 = B, ...)
  final int columnIndex;

  /// Zero-based row index (0 = row 1, 1 = row 2, ...)
  final int rowIndex;

  /// Geographic boundaries of the cell
  final GridBounds bounds;

  /// Geographic center of the cell
  final LatLng centerPoint;

  /// Creates an immutable GridCell instance.
  const GridCell({
    required this.id,
    required this.columnIndex,
    required this.rowIndex,
    required this.bounds,
    required this.centerPoint,
  });

  @override
  String toString() {
    return 'GridCell{id: $id, columnIndex: $columnIndex, rowIndex: $rowIndex, center: $centerPoint}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridCell &&
        other.id == id &&
        other.columnIndex == columnIndex &&
        other.rowIndex == rowIndex;
  }

  @override
  int get hashCode {
    return Object.hash(id, columnIndex, rowIndex);
  }
}
