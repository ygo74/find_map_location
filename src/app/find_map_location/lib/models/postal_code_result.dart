import 'city.dart';

/// Encapsulates the result of a postal code lookup.
///
/// Contains all cities matching a postal code and provides helper methods
/// to determine if user selection is needed.
class PostalCodeResult {
  /// The postal code that was queried
  final String postalCode;

  /// All cities matching the postal code
  final List<City> cities;

  /// Creates a PostalCodeResult instance.
  const PostalCodeResult({
    required this.postalCode,
    required this.cities,
  });

  /// Returns true if result contains exactly one city.
  ///
  /// Single-city results bypass the selection screen and display
  /// the map immediately.
  bool get isSingleCity => cities.length == 1;

  /// Returns true if result requires user to select from multiple cities.
  ///
  /// Multi-city results display a selection screen.
  bool get requiresSelection => cities.length > 1;

  /// Gets the first (and only) city for single-city results.
  ///
  /// Throws [StateError] if called when [isSingleCity] is false.
  City get singleCity {
    if (!isSingleCity) {
      throw StateError('Cannot get singleCity when multiple cities exist');
    }
    return cities.first;
  }

  /// Gets cities sorted alphabetically by name.
  ///
  /// Returns a new list with cities sorted in alphabetical order.
  /// Useful for displaying cities in a consistent order in the UI.
  List<City> get sortedCities {
    final sorted = List<City>.from(cities);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostalCodeResult &&
          runtimeType == other.runtimeType &&
          postalCode == other.postalCode &&
          _listsEqual(cities, other.cities);

  bool _listsEqual(List<City> a, List<City> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => postalCode.hashCode ^ cities.length.hashCode;

  @override
  String toString() =>
      'PostalCodeResult($postalCode, ${cities.length} cities)';
}
