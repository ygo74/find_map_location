# Data Model: City Selection for Duplicate Postal Codes

**Feature**: 002-city-selection
**Date**: 2025-12-13
**Purpose**: Define entities and state for handling multiple cities per postal code

## Entity Overview

```
┌─────────────────┐
│  PostalCode     │ (Value Object - from 001)
│  - value: String│
│  - isValid()    │
└────────┬────────┘
         │ validates
         │ submits
         ▼
┌─────────────────────┐
│ GeocodingService    │ (Service - MODIFIED)
│ - fetchLocations()  │ ← Returns List<City> now
└────────┬────────────┘
         │ returns
         ▼
┌─────────────────────────┐
│ PostalCodeResult        │ (NEW - Wrapper Entity)
│ - postalCode: String    │
│ - cities: List<City>    │
│ - isSingleCity()        │
│ - requiresSelection()   │
└────────┬────────────────┘
         │ contains
         ▼
┌─────────────────────────┐
│  City                   │ (NEW - Entity)
│ - name: String          │
│ - latitude: double      │
│ - longitude: double     │
│ - department: String?   │ ← For disambiguation
│ - displayLabel: String  │ ← Computed property
└────────┬────────────────┘
         │ user selects
         ▼
┌─────────────────┐
│   MapState      │ (State Enum - from 001)
│  - idle         │
│  - loading      │
│  - selection    │ ← NEW state
│  - success      │
│  - error        │
└─────────────────┘
```

---

## 1. City (Entity) [NEW]

**Purpose**: Represent a single city/village with geographic and administrative data

**Attributes**:
- `name`: String - City/village name (e.g., "Saint-Genis-Pouilly")
- `latitude`: double - Geographic latitude
- `longitude`: double - Geographic longitude
- `department`: String? - Department name for disambiguation (e.g., "Ain")
- `postalCode`: String - The postal code this city belongs to

**Computed Properties**:
- `displayLabel`: String - Full display text for UI
  - With department: "Saint-Genis-Pouilly (Ain)"
  - Without department: "Saint-Genis-Pouilly"

**Dart Implementation**:
```dart
class City {
  final String name;
  final double latitude;
  final double longitude;
  final String? department;
  final String postalCode;

  const City({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.department,
    required this.postalCode,
  });

  /// Display label for UI (includes department if available)
  String get displayLabel {
    if (department != null && department!.isNotEmpty) {
      return '$name ($department)';
    }
    return name;
  }

  /// Factory constructor from API Adresse JSON
  factory City.fromJson(Map<String, dynamic> json, String postalCode) {
    final properties = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;

    // Extract department from context: "01, Ain, Auvergne-Rhône-Alpes"
    String? department;
    final context = properties['context'] as String?;
    if (context != null) {
      final parts = context.split(',');
      if (parts.length >= 2) {
        department = parts[1].trim();
      }
    }

    return City(
      name: properties['city'] as String,
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
      department.hashCode ^
      postalCode.hashCode;

  @override
  String toString() => 'City($displayLabel, $postalCode)';
}
```

**Validation Rules** (from spec):
- `name` must not be empty
- `latitude` must be valid: -90.0 to 90.0
- `longitude` must be valid: -180.0 to 180.0
- `department` is optional (null-safe)
- `postalCode` must match PostalCode validation rules

**Immutability**:
- All fields are final
- Use `const` constructor when possible
- No setters or mutating methods

---

## 2. PostalCodeResult (Wrapper Entity) [NEW]

**Purpose**: Encapsulate the result of a postal code lookup with decision logic

**Attributes**:
- `postalCode`: String - The postal code that was queried
- `cities`: List<City> - All cities matching the postal code

**Computed Properties**:
- `isSingleCity`: bool - Returns true if exactly one city
- `requiresSelection`: bool - Returns true if multiple cities

**Dart Implementation**:
```dart
class PostalCodeResult {
  final String postalCode;
  final List<City> cities;

  const PostalCodeResult({
    required this.postalCode,
    required this.cities,
  });

  /// True if result contains exactly one city
  bool get isSingleCity => cities.length == 1;

  /// True if result requires user to select from multiple cities
  bool get requiresSelection => cities.length > 1;

  /// Get the first (and only) city for single-city results
  City get singleCity {
    if (!isSingleCity) {
      throw StateError('Cannot get singleCity when multiple cities exist');
    }
    return cities.first;
  }

  /// Get cities sorted alphabetically by name
  List<City> get sortedCities {
    final sorted = List<City>.from(cities);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  @override
  String toString() =>
      'PostalCodeResult($postalCode, ${cities.length} cities)';
}
```

**Decision Logic** (from spec):
1. `isSingleCity == true` → Display map immediately (FR-005)
2. `requiresSelection == true` → Show city selection screen (FR-002)
3. `cities.isEmpty` → Error state (should not happen with valid API response)

**State Transitions**:
```
User submits postal code
         ↓
GeocodingService returns PostalCodeResult
         ↓
    [Decision]
         ↓
  ┌──────┴──────┐
  ↓             ↓
isSingleCity  requiresSelection
  ↓             ↓
Display map   Show selection screen
              ↓
         User selects city
              ↓
         Display map
```

---

## 3. MapState (State Enum) [MODIFIED]

**Purpose**: Track UI state during postal code lookup and city selection

**Original States** (from feature 001):
- `idle`: Initial state, no action taken
- `loading`: Geocoding request in progress
- `success`: Map displayed successfully
- `error`: Error occurred (network, not found, format)

**New State** (for feature 002):
- `selection`: Multiple cities returned, awaiting user selection

**State Diagram**:
```
    [idle]
      ↓
  User submits postal code
      ↓
   [loading]
      ↓
  API response
      ↓
  ┌───┴───┐
  ↓       ↓
error   result
  ↓       ↓
[error]  [Decision]
         ↓
    ┌────┴────┐
    ↓         ↓
isSingleCity requiresSelection
    ↓         ↓
[success]  [selection]
             ↓
        User selects city
             ↓
          [success]
```

**Dart Implementation**:
```dart
enum MapState {
  idle,
  loading,
  selection,  // NEW: Awaiting city selection
  success,
  error,
}
```

**UI Behavior per State**:
- `idle`: Show postal code input, empty map
- `loading`: Show postal code input with progress indicator
- `selection`: Show city selection screen (Navigator.push)
- `success`: Show postal code input with map centered on city
- `error`: Show postal code input with error message

---

## 4. CitySelection (UI State) [NEW]

**Purpose**: Manage state within the city selection screen

**Attributes**:
- `availableCities`: List<City> - Cities to display (immutable)
- `selectedCity`: City? - Currently selected city (null until user taps)

**Dart Implementation**:
```dart
class CitySelectionState {
  final List<City> availableCities;
  final City? selectedCity;

  const CitySelectionState({
    required this.availableCities,
    this.selectedCity,
  });

  CitySelectionState copyWith({
    List<City>? availableCities,
    City? selectedCity,
  }) {
    return CitySelectionState(
      availableCities: availableCities ?? this.availableCities,
      selectedCity: selectedCity ?? this.selectedCity,
    );
  }

  bool get hasSelection => selectedCity != null;

  @override
  String toString() =>
      'CitySelectionState(${availableCities.length} cities, selected: $selectedCity)';
}
```

**State Transitions**:
1. Screen opens → `CitySelectionState(availableCities: cities, selectedCity: null)`
2. User taps city → `copyWith(selectedCity: tappedCity)`
3. Navigation pops → Return selectedCity to previous screen

---

## 5. GeocodingService Interface [MODIFIED]

**Purpose**: Abstract geocoding operations to support multiple cities

**Original Interface** (feature 001):
```dart
abstract class GeocodingService {
  Future<CityLocation> fetchLocation(PostalCode postalCode);
}
```

**Modified Interface** (feature 002):
```dart
abstract class GeocodingService {
  /// Fetches all cities for a given postal code
  Future<PostalCodeResult> fetchLocations(PostalCode postalCode);
}
```

**Breaking Change**: Yes, signature changes from `CityLocation` to `PostalCodeResult`

**Migration Strategy**:
1. Update `fetchLocations` to return `PostalCodeResult` with list of cities
2. Update all callers to handle `PostalCodeResult` instead of single `CityLocation`
3. Add logic to check `isSingleCity` vs `requiresSelection`

**Implementation Notes**:
- Change API call: `limit=1` → `limit=50`
- Parse all features from JSON response (not just first)
- Map each feature to `City` object
- Wrap cities in `PostalCodeResult`

---

## Entity Relationships Summary

| Entity | Type | Responsibility | Relationships |
|--------|------|----------------|---------------|
| **PostalCode** | Value Object | Validate postal code format | Used by GeocodingService |
| **City** | Entity | Represent single city location | Contained in PostalCodeResult |
| **PostalCodeResult** | Wrapper | Aggregate cities for a postal code | Contains List<City> |
| **MapState** | Enum | Track UI state machine | Controls screen flow |
| **CitySelectionState** | UI State | Manage selection screen state | Contains List<City> |
| **GeocodingService** | Service | Fetch data from API | Returns PostalCodeResult |

---

## Validation Rules Summary

### City Validation
- ✅ `name` not empty
- ✅ `latitude` in range [-90.0, 90.0]
- ✅ `longitude` in range [-180.0, 180.0]
- ✅ `postalCode` matches pattern `^[0-9]{5}$`
- ⚠️ `department` nullable (optional field)

### PostalCodeResult Validation
- ✅ `cities` list not null (can be empty for error cases)
- ✅ `postalCode` matches pattern `^[0-9]{5}$`
- ⚠️ Empty cities list should trigger error state

---

## Test Data Examples

### Single City Result
```dart
final singleCityResult = PostalCodeResult(
  postalCode: '75001',
  cities: [
    City(
      name: 'Paris 1er Arrondissement',
      latitude: 48.8629,
      longitude: 2.3364,
      department: 'Paris',
      postalCode: '75001',
    ),
  ],
);

assert(singleCityResult.isSingleCity == true);
assert(singleCityResult.requiresSelection == false);
```

### Multiple Cities Result
```dart
final multiCityResult = PostalCodeResult(
  postalCode: '01630',
  cities: [
    City(
      name: 'Saint-Genis-Pouilly',
      latitude: 46.2436,
      longitude: 6.0236,
      department: 'Ain',
      postalCode: '01630',
    ),
    City(
      name: 'Péron',
      latitude: 46.1987,
      longitude: 6.0123,
      department: 'Ain',
      postalCode: '01630',
    ),
    City(
      name: 'Sergy',
      latitude: 46.2589,
      longitude: 6.0445,
      department: 'Ain',
      postalCode: '01630',
    ),
  ],
);

assert(multiCityResult.isSingleCity == false);
assert(multiCityResult.requiresSelection == true);
assert(multiCityResult.sortedCities.first.name == 'Péron');
```

---

## Implementation Checklist

- [ ] Create `City` model class with fromJson factory
- [ ] Create `PostalCodeResult` wrapper class
- [ ] Add `MapState.selection` enum value
- [ ] Create `CitySelectionState` for selection screen
- [ ] Update `GeocodingService` interface signature
- [ ] Update `ApiAdresseGeocodingService` implementation
- [ ] Write unit tests for City model
- [ ] Write unit tests for PostalCodeResult logic
- [ ] Write unit tests for GeocodingService multi-city parsing
