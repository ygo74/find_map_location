/// Represents user preferences for grid overlay (persisted data model).
///
/// This model is used to save and load grid configuration settings
/// to/from persistent storage (SharedPreferences).
class GridSettings {
  /// User's chosen cell size in meters (250, 500, 1000, or 2000)
  final int selectedCellSize;

  /// Default cell size in meters
  static const int defaultCellSize = 500;

  /// Valid cell size options
  static const List<int> validSizes = [250, 500, 1000, 2000];

  /// Creates a GridSettings instance with the specified cell size.
  ///
  /// [selectedCellSize] must be one of [250, 500, 1000, 2000].
  /// Defaults to 500 if not specified.
  const GridSettings({
    this.selectedCellSize = defaultCellSize,
  }) : assert(
          selectedCellSize == 250 ||
              selectedCellSize == 500 ||
              selectedCellSize == 1000 ||
              selectedCellSize == 2000,
          'selectedCellSize must be one of [250, 500, 1000, 2000]',
        );

  /// Creates a GridSettings from a cell size value, with validation.
  ///
  /// Returns default settings if [size] is invalid.
  factory GridSettings.fromCellSize(int? size) {
    if (size != null && validSizes.contains(size)) {
      return GridSettings(selectedCellSize: size);
    }
    return const GridSettings();
  }

  @override
  String toString() {
    return 'GridSettings{selectedCellSize: ${selectedCellSize}m}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridSettings &&
        other.selectedCellSize == selectedCellSize;
  }

  @override
  int get hashCode => selectedCellSize.hashCode;
}
