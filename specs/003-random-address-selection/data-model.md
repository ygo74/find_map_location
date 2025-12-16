# Data Model: Random Address Selection for Location Game

**Date**: 2025-12-14
**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Research**: [research.md](./research.md)

## Overview

This document defines the data entities, their relationships, and validation rules for the random address selection feature. All entities follow Flutter/Dart immutability patterns with const constructors and null safety.

## Entity Diagram

```
┌─────────────────────┐
│   City              │
│ (EXISTING)          │
│─────────────────────│
│ + name: String      │
│ + postcode: String  │
│ + lat: double       │
│ + lon: double       │
│ + department: String│
└──────────┬──────────┘
           │
           │ has bounds for
           │
           ▼
┌─────────────────────────────┐
│   RandomAddress             │
│─────────────────────────────│
│ + streetNumber: String      │
│ + streetName: String        │
│ + cityName: String          │
│ + postcode: String          │
│ + latitude: double          │
│ + longitude: double         │
│ + generatedAt: DateTime     │
└──────────┬──────────────────┘
           │
           │ wrapped in
           │
           ▼
┌─────────────────────────────┐
│   AddressSelectionResult    │
│─────────────────────────────│
│ + address: RandomAddress?   │
│ + error: String?            │
│ + isSuccess: bool           │
└─────────────────────────────┘

┌─────────────────────────────┐
│   GameSessionState          │
│─────────────────────────────│
│ + currentAddress:           │
│   RandomAddress?            │
│ + hasStartedSearch: bool    │
│ + usedAddresses: Set<String>│
│ + selectedCity: City?       │
└─────────────────────────────┘
```

## Entities

### 1. RandomAddress

**Purpose**: Represents a specific address within a city that serves as the game target. Contains complete address information and geographic coordinates.

**Properties**:
| Property | Type | Required | Description | Validation |
|----------|------|----------|-------------|------------|
| streetNumber | String | Yes | House/building number | Non-empty, e.g. "42", "12bis" |
| streetName | String | Yes | Street name with type | Non-empty, e.g. "Rue de Rivoli" |
| cityName | String | Yes | City name | Non-empty, must match selected city |
| postcode | String | Yes | Postal code | 5 digits for France |
| latitude | double | Yes | Latitude coordinate | -90.0 to 90.0 |
| longitude | double | Yes | Longitude coordinate | -180.0 to 180.0 |
| generatedAt | DateTime | Yes | Timestamp of generation | UTC timezone |

**Invariants**:
- Coordinates must be within reasonable bounds for France (41°N-51°N, -5°E-10°E)
- streetNumber + streetName + cityName combination must be unique within session
- generatedAt is immutable after creation

**Constructor**:
```dart
const RandomAddress({
  required this.streetNumber,
  required this.streetName,
  required this.cityName,
  required this.postcode,
  required this.latitude,
  required this.longitude,
  required this.generatedAt,
});
```

**Methods**:
- `String toDisplayString()` → Formats for UI: "42 Rue de Rivoli, Paris"
- `String toUniqueKey()` → Generates uniqueness key: "Paris|Rue de Rivoli|42"
- `bool isInCity(City city)` → Validates address belongs to city

**Example**:
```dart
const address = RandomAddress(
  streetNumber: '42',
  streetName: 'Rue de Rivoli',
  cityName: 'Paris',
  postcode: '75001',
  latitude: 48.8606,
  longitude: 2.3376,
  generatedAt: DateTime(...),
);
```

### 2. AddressSelectionResult

**Purpose**: Wrapper for address generation operations, providing either successful address or error information.

**Properties**:
| Property | Type | Required | Description | Validation |
|----------|------|----------|-------------|------------|
| address | RandomAddress? | No | Generated address if successful | null on error |
| error | String? | No | User-friendly error message | null on success |
| isSuccess | bool | Yes | Success/failure indicator | Derived from address != null |

**Invariants**:
- Exactly one of `address` or `error` must be non-null
- If `isSuccess` is true, `address` must not be null
- If `isSuccess` is false, `error` must not be null

**Factory Constructors**:
```dart
factory AddressSelectionResult.success(RandomAddress address) {
  return AddressSelectionResult._(address: address, error: null);
}

factory AddressSelectionResult.failure(String error) {
  return AddressSelectionResult._(address: null, error: error);
}
```

**Example**:
```dart
// Success case
final result = AddressSelectionResult.success(randomAddress);

// Failure case
final result = AddressSelectionResult.failure(
  'Unable to generate address for this location. Please try a different city.'
);
```

### 3. GameSessionState

**Purpose**: Tracks the current game session state including active address, search status, and history for uniqueness checking.

**Properties**:
| Property | Type | Required | Description | Validation |
|----------|------|----------|-------------|------------|
| currentAddress | RandomAddress? | No | Currently displayed target address | null before generation |
| hasStartedSearch | bool | Yes | Whether "Start Search" was pressed | Default false |
| usedAddresses | Set<String> | Yes | Set of address keys already shown | Initially empty |
| selectedCity | City? | No | Currently selected city context | null before city selection |

**Invariants**:
- If `hasStartedSearch` is true, `currentAddress` must not be null
- `usedAddresses` contains keys from `RandomAddress.toUniqueKey()`
- `usedAddresses` is append-only (no removal)

**Constructor**:
```dart
const GameSessionState({
  this.currentAddress,
  this.hasStartedSearch = false,
  this.usedAddresses = const {},
  this.selectedCity,
});
```

**Methods**:
- `GameSessionState withAddress(RandomAddress address)` → Returns new state with updated address
- `GameSessionState withSearchStarted()` → Returns new state with hasStartedSearch = true
- `GameSessionState withNewCity(City city)` → Returns new state for city change (resets address/search)
- `bool isAddressUsed(String key)` → Checks if address key exists in usedAddresses
- `GameSessionState addUsedAddress(String key)` → Returns new state with key added to set

**State Transitions**:
```
Initial State
  ↓
City Selected → (selectedCity set, currentAddress null, hasStartedSearch false)
  ↓
Address Generated → (currentAddress set, hasStartedSearch false, key added to usedAddresses)
  ↓
Search Started → (hasStartedSearch true)
  ↓
New City Selected → Reset to City Selected state
```

**Example**:
```dart
// Initial state
var state = const GameSessionState();

// After city selection
state = state.withNewCity(parisCity);

// After address generation
state = state.withAddress(randomAddress)
            .addUsedAddress(randomAddress.toUniqueKey());

// After "Start Search" pressed
state = state.withSearchStarted();
```

### 4. CityBounds (New Helper Class)

**Purpose**: Represents the bounding box for random coordinate generation within a city.

**Properties**:
| Property | Type | Required | Description | Validation |
|----------|------|----------|-------------|------------|
| minLatitude | double | Yes | Southern boundary | -90.0 to 90.0 |
| maxLatitude | double | Yes | Northern boundary | > minLatitude |
| minLongitude | double | Yes | Western boundary | -180.0 to 180.0 |
| maxLongitude | double | Yes | Eastern boundary | > minLongitude |

**Constructor**:
```dart
const CityBounds({
  required this.minLatitude,
  required this.maxLatitude,
  required this.minLongitude,
  required this.maxLongitude,
});

factory CityBounds.fromCityCenter(City city, {double delta = 0.05}) {
  return CityBounds(
    minLatitude: city.lat - delta,
    maxLatitude: city.lat + delta,
    minLongitude: city.lon - delta,
    maxLongitude: city.lon + delta,
  );
}
```

**Methods**:
- `LatLng generateRandomCoordinate(Random random)` → Returns random point within bounds
- `bool contains(LatLng point)` → Checks if point is within bounds

**Example**:
```dart
final bounds = CityBounds.fromCityCenter(parisCity, delta: 0.05);
final random Coords = bounds.generateRandomCoordinate(Random());
```

## Relationships

### City → RandomAddress
- **Type**: One-to-Many
- **Cardinality**: 1 City → 0..* RandomAddress
- **Description**: Each city can have multiple random addresses generated for it. A random address always belongs to exactly one city.
- **Constraint**: RandomAddress.cityName must match City.name

### RandomAddress → AddressSelectionResult
- **Type**: Composition (Lifetime Dependency)
- **Cardinality**: 1 AddressSelectionResult → 0..1 RandomAddress
- **Description**: AddressSelectionResult wraps either a RandomAddress (success) or error message (failure)
- **Constraint**: Exactly one of address or error must be set

### GameSessionState → RandomAddress
- **Type**: Association (Current Reference)
- **Cardinality**: 1 GameSessionState → 0..1 RandomAddress (current), 0..* String (history keys)
- **Description**: GameSessionState tracks the current active address and history of used addresses via keys
- **Constraint**: usedAddresses set must include key of currentAddress if it exists

### GameSessionState → City
- **Type**: Association (Current Reference)
- **Cardinality**: 1 GameSessionState → 0..1 City
- **Description**: GameSessionState references the currently selected city
- **Constraint**: When selectedCity changes, currentAddress and hasStartedSearch reset

## Validation Rules

### Address Generation Validation

1. **City Name Match** (FR-006):
   ```dart
   bool validateCityMatch(RandomAddress address, City city) {
     return address.cityName.toLowerCase() == city.name.toLowerCase();
   }
   ```

2. **Address Uniqueness** (SC-002, FR-005):
   ```dart
   bool isAddressUnique(RandomAddress address, GameSessionState state) {
     return !state.isAddressUsed(address.toUniqueKey());
   }
   ```

3. **Coordinate Bounds** (FR-006):
   ```dart
   bool areCoordinatesValid(double lat, double lon) {
     return lat >= 41.0 && lat <= 51.0 &&  // France latitude range
            lon >= -5.0 && lon <= 10.0;     // France longitude range
   }
   ```

4. **Address Completeness** (FR-004):
   ```dart
   bool isAddressComplete(RandomAddress address) {
     return address.streetNumber.isNotEmpty &&
            address.streetName.isNotEmpty &&
            address.cityName.isNotEmpty &&
            address.postcode.length == 5;
   }
   ```

### State Transition Validation

1. **Can Start Search** (FR-013, FR-014):
   ```dart
   bool canStartSearch(GameSessionState state) {
     return state.currentAddress != null && !state.hasStartedSearch;
   }
   ```

2. **Can Generate New Address** (FR-001, FR-007):
   ```dart
   bool canGenerateAddress(GameSessionState state) {
     return state.selectedCity != null;
   }
   ```

## Immutability Patterns

All entities follow Flutter immutability best practices:

```dart
// ✅ Correct: Immutable with const constructor
class RandomAddress {
  final String streetNumber;
  final String streetName;
  // ... other final fields

  const RandomAddress({required this.streetNumber, ...});

  // Returns new instance
  RandomAddress copyWith({String? streetNumber, ...}) {
    return RandomAddress(
      streetNumber: streetNumber ?? this.streetNumber,
      // ...
    );
  }
}

// ❌ Incorrect: Mutable fields
class RandomAddress {
  String streetNumber; // No final
  void updateStreetNumber(String newNumber) {
    streetNumber = newNumber; // Mutation
  }
}
```

## Serialization

### JSON Serialization (for testing/debugging only - no persistence requirement)

```dart
class RandomAddress {
  Map<String, dynamic> toJson() {
    return {
      'streetNumber': streetNumber,
      'streetName': streetName,
      'cityName': cityName,
      'postcode': postcode,
      'latitude': latitude,
      'longitude': longitude,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory RandomAddress.fromJson(Map<String, dynamic> json) {
    return RandomAddress(
      streetNumber: json['streetNumber'] as String,
      streetName: json['streetName'] as String,
      cityName: json['cityName'] as String,
      postcode: json['postcode'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}
```

## Testing Considerations

### Unit Test Scenarios

1. **RandomAddress**:
   - `toDisplayString()` formats correctly
   - `toUniqueKey()` generates consistent keys
   - `isInCity()` validates city membership
   - Equality and hashCode for Set operations

2. **AddressSelectionResult**:
   - `.success()` factory creates valid success result
   - `.failure()` factory creates valid failure result
   - Invariant enforcement (can't have both address and error)

3. **GameSessionState**:
   - State transitions preserve immutability
   - `usedAddresses` set operations work correctly
   - City change resets state appropriately

4. **CityBounds**:
   - `generateRandomCoordinate()` produces points within bounds
   - `contains()` correctly validates boundary conditions
   - `fromCityCenter()` calculates bounds accurately

### Widget Test Scenarios

- AddressDisplay widget renders RandomAddress correctly
- Special characters (accents, apostrophes) display properly
- Long street names wrap without overflow

## Implementation Checklist

- [ ] Create `lib/models/random_address.dart`
- [ ] Create `lib/models/address_selection_result.dart`
- [ ] Create `lib/models/game_session_state.dart`
- [ ] Create `lib/models/city_bounds.dart`
- [ ] Write unit tests for all entities
- [ ] Document public APIs with dartdoc
- [ ] Verify `flutter analyze` passes
- [ ] Confirm immutability patterns throughout
