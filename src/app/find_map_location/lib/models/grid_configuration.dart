import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// State management for grid overlay configuration.
///
/// Extends [ChangeNotifier] to provide reactive updates when grid
/// configuration changes (origin set, cell size changed, visibility toggled).
class GridConfiguration extends ChangeNotifier {
  /// Size of each grid cell in meters (one of: 250, 500, 1000, 2000)
  int _cellSizeMeters;

  /// Geographic origin point (top-left of cell A1); null if not yet initialized
  LatLng? _origin;

  /// Whether grid overlay is currently displayed
  bool _isVisible;

  /// Creates a GridConfiguration with default or specified values.
  ///
  /// [cellSizeMeters] defaults to 500. Must be one of [250, 500, 1000, 2000].
  /// [isVisible] defaults to false (grid hidden until origin set).
  GridConfiguration({
    int cellSizeMeters = 500,
    LatLng? origin,
    bool isVisible = false,
  })  : _cellSizeMeters = cellSizeMeters,
        _origin = origin,
        _isVisible = isVisible;

  // Getters
  int get cellSizeMeters => _cellSizeMeters;
  LatLng? get origin => _origin;
  bool get isVisible => _isVisible;

  /// Sets the grid origin and makes the grid visible.
  ///
  /// This should be called once when the first address is searched.
  /// Notifies listeners to trigger grid rendering.
  void setOrigin(LatLng newOrigin) {
    _origin = newOrigin;
    _isVisible = true;
    notifyListeners();
  }

  /// Changes the cell size and notifies listeners to redraw the grid.
  ///
  /// [newSize] must be one of [250, 500, 1000, 2000].
  void setCellSize(int newSize) {
    if (_cellSizeMeters != newSize) {
      _cellSizeMeters = newSize;
      notifyListeners();
    }
  }

  /// Hides the grid overlay without clearing the origin.
  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  /// Resets the grid configuration to initial state.
  ///
  /// Clears origin, hides grid, and resets to default cell size.
  void reset() {
    _origin = null;
    _isVisible = false;
    _cellSizeMeters = 500;
    notifyListeners();
  }
}
