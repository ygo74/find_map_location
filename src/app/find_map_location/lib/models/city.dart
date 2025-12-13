/// Represents a city/village with geographic and administrative data.
///
/// Cities are returned by the geocoding service when looking up postal codes.
/// Multiple cities may share the same postal code in France.
class City {
  /// City/village name (e.g., "Saint-Genis-Pouilly")
  final String name;

  /// Geographic latitude (-90.0 to 90.0)
  final double latitude;

  /// Geographic longitude (-180.0 to 180.0)
  final double longitude;

  /// Department name for disambiguation (e.g., "Ain")
  /// Null if department information is not available
  final String? department;

  /// The postal code this city belongs to
  final String postalCode;

  /// Creates a City instance.
  ///
  /// All fields except [department] are required.
  const City({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.department,
    required this.postalCode,
  });

  /// Display label for UI.
  ///
  /// Includes department in parentheses if available:
  /// - With department: "Saint-Genis-Pouilly (Ain)"
  /// - Without department: "Saint-Genis-Pouilly"
  String get displayLabel {
    if (department != null && department!.isNotEmpty) {
      return '$name ($department)';
    }
    return name;
  }

  /// Creates a City from API Adresse JSON response.
  ///
  /// Expects a GeoJSON feature with:
  /// - properties.city: city name
  /// - geometry.coordinates: [longitude, latitude]
  /// - properties.context: "departmentCode, departmentName, region"
  ///
  /// Example:
  /// ```dart
  /// final city = City.fromJson(jsonFeature, '01630');
  /// ```
  factory City.fromJson(Map<String, dynamic> json, String postalCode) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;

    // Extract department name from context: "01, Ain, Auvergne-Rhône-Alpes"
    // Index 1 contains the department name (e.g., "Ain")
    String? department;
    final context = properties['context'] as String?;
    if (context != null && context.isNotEmpty) {
      final parts = context.split(',');
      if (parts.length >= 2) {
        final departmentName = parts[1].trim();
        // Only set if non-empty
        if (departmentName.isNotEmpty) {
          department = departmentName;
        }
      }
    }

    // API returns 'name' field for municipality name (same as 'city' field)
    final name = properties['name'] as String? ?? properties['city'] as String;

    return City(
      name: name,
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
      department: department,
      postalCode: postalCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          department == other.department &&
          postalCode == other.postalCode;

  @override
  int get hashCode =>
      name.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      (department?.hashCode ?? 0) ^
      postalCode.hashCode;

  @override
  String toString() => 'City($displayLabel, $postalCode)';
}
