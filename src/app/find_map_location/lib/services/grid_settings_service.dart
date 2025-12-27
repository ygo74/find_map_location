import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and retrieving grid overlay settings.
///
/// Uses SharedPreferences to store user preferences for grid cell size.
class GridSettingsService {
  /// SharedPreferences instance for persistent storage
  final SharedPreferences _prefs;

  /// Key for storing grid cell size in SharedPreferences
  static const String _gridSizeKey = 'grid_cell_size_meters';

  /// Default grid cell size in meters
  static const int _defaultSize = 500;

  /// Creates a GridSettingsService with the provided SharedPreferences instance.
  ///
  /// Example:
  /// ```dart
  /// final prefs = await SharedPreferences.getInstance();
  /// final service = GridSettingsService(prefs);
  /// ```
  GridSettingsService(this._prefs);

  /// Retrieves the saved grid size from persistent storage.
  ///
  /// Returns the saved grid size in meters, or 500 (default) if not set.
  /// Only returns values from the valid set: [250, 500, 1000, 2000].
  /// If an invalid value is stored, returns the default.
  int getGridSize() {
    final size = _prefs.getInt(_gridSizeKey);
    if (size != null && _isValidSize(size)) {
      return size;
    }
    return _defaultSize;
  }

  /// Saves the grid size to persistent storage.
  ///
  /// [sizeMeters] must be one of [250, 500, 1000, 2000].
  /// Throws [ArgumentError] if the size is invalid.
  ///
  /// Example:
  /// ```dart
  /// await service.setGridSize(1000);
  /// ```
  Future<void> setGridSize(int sizeMeters) async {
    if (!_isValidSize(sizeMeters)) {
      throw ArgumentError(
        'Grid size must be one of [250, 500, 1000, 2000], got $sizeMeters',
      );
    }
    await _prefs.setInt(_gridSizeKey, sizeMeters);
  }

  /// Validates that a size is one of the allowed values.
  bool _isValidSize(int size) {
    return size == 250 || size == 500 || size == 1000 || size == 2000;
  }
}
