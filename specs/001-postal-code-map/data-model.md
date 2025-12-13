# Data Model: Postal Code Map Viewer

**Feature**: 001-postal-code-map
**Date**: 2025-12-13
**Purpose**: Define entities, value objects, and state management for postal code geocoding

## Entity Overview

```
┌─────────────────┐
│  PostalCode     │ (Value Object)
│  - value: String│
│  - isValid()    │
└────────┬────────┘
         │ validates
         │ submits
         ▼
┌─────────────────────┐
│ GeocodingService    │ (Service)
│ - fetchLocation()   │
└────────┬────────────┘
         │ returns
         ▼
┌─────────────────┐
│  CityLocation   │ (Entity)
│  - coordinates  │
│  - cityName     │
│  - postalCode   │
└────────┬────────┘
         │ displays on
         ▼
┌─────────────────┐
│   MapState      │ (State Enum)
│  - idle         │
│  - loading      │
│  - success      │
│  - error        │
└─────────────────┘
```

---

## 1. PostalCode (Value Object)

**Purpose**: Encapsulate French postal code validation logic

**Attributes**:
- `value`: String - The 5-digit postal code
- `isValid`: bool - Computed property checking format

**Validation Rules** (from FR-002):
- Exactly 5 characters
- All characters must be digits (0-9)
- Pattern: `^[0-9]{5}$`

**Dart Implementation**:
```dart
class PostalCode {
  static final RegExp _validationPattern = RegExp(r'^[0-9]{5}$');

  final String value;

  PostalCode(this.value);

  bool get isValid => _validationPattern.hasMatch(value);

  bool get isEmpty => value.isEmpty;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostalCode && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
```

**State Transitions**:
1. User input → `PostalCode('')` (empty)
2. User types → `PostalCode('750')` (invalid)
3. User completes → `PostalCode('75001')` (valid)
4. Validation on submit → `isValid` check determines next action

**Error Cases**:
- Empty: Show "Please enter a postal code" (FR-010)
- Invalid format: Show "Please enter a valid 5-digit French postal code" (FR-003)

---

## 2. CityLocation (Entity)

**Purpose**: Represent geographic location data returned from geocoding API

**Attributes**:
- `latitude`: double - Geographic latitude (Y coordinate)
- `longitude`: double - Geographic longitude (X coordinate)
- `cityName`: String - Human-readable city name (e.g., "Paris 1er Arrondissement")
- `postalCode`: String - The postal code this location corresponds to
- `label`: String? - Optional full address label from API

**Dart Implementation**:
```dart
import 'package:latlong2/latlong.dart';

class CityLocation {
  final double latitude;
  final double longitude;
  final String cityName;
  final String postalCode;
  final String? label;

  CityLocation({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.postalCode,
    this.label,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;

    return CityLocation(
      longitude: (coords[0] as num).toDouble(),  // API returns [lon, lat]
      latitude: (coords[1] as num).toDouble(),
      cityName: properties['city'] as String,
      postalCode: properties['postcode'] as String,
      label: properties['label'] as String?,
    );
  }

  @override
  String toString() => 'CityLocation($cityName, $postalCode)';
}
```

**Relationships**:
- Created by: `GeocodingService.fetchLocation(PostalCode)`
- Used by: `MapDisplay` widget for center coordinates and zoom

**Data Source**: API Adresse (api-adresse.data.gouv.fr)

---

## 3. MapState (State Enum)

**Purpose**: Track UI state for postal code lookup and map display

**States**:
```dart
enum MapState {
  idle,       // Initial state, no lookup performed
  loading,    // Geocoding request in progress (show CircularProgressIndicator)
  success,    // Location fetched, map displayed
  error,      // Error occurred (network, not found, invalid format)
}
```

**State Transitions**:
```
idle → loading   (user submits valid postal code)
loading → success (geocoding API returns location)
loading → error  (network error, 404, timeout)
error → loading  (user retries with corrected input)
success → loading (user submits different postal code)
```

**UI Behavior by State**:
- `idle`: Show input form, no map
- `loading`: Show input form + CircularProgressIndicator
- `success`: Show input form + map with location
- `error`: Show input form + error message (no map or hide map)

---

## 4. ErrorType (Error Enum)

**Purpose**: Categorize different error conditions for appropriate messaging

**Types**:
```dart
enum ErrorType {
  emptyInput,      // FR-010: "Please enter a postal code"
  invalidFormat,   // FR-003: "Please enter a valid 5-digit French postal code"
  notFound,        // FR-006: "No city found for postal code {code}"
  networkError,    // FR-011: "No internet connection. Please check your network"
  serverError,     // API error: "Service temporarily unavailable. Please try again"
}
```

**Error Message Mapping**:
```dart
extension ErrorTypeMessage on ErrorType {
  String getMessage(String? postalCode) {
    switch (this) {
      case ErrorType.emptyInput:
        return 'Please enter a postal code';
      case ErrorType.invalidFormat:
        return 'Please enter a valid 5-digit French postal code';
      case ErrorType.notFound:
        return 'No city found for postal code $postalCode. Please verify and try again.';
      case ErrorType.networkError:
        return 'No internet connection. Please check your network and try again.';
      case ErrorType.serverError:
        return 'Service temporarily unavailable. Please try again later.';
    }
  }
}
```

---

## 5. GeocodingService (Service Layer)

**Purpose**: Handle HTTP communication with geocoding API

**Interface**:
```dart
abstract class GeocodingService {
  Future<CityLocation> fetchLocation(PostalCode postalCode);
}
```

**Implementation**:
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ApiAdresseGeocodingService implements GeocodingService {
  static const String baseUrl = 'https://api-adresse.data.gouv.fr/search';
  final http.Client client;

  ApiAdresseGeocodingService({http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<CityLocation> fetchLocation(PostalCode postalCode) async {
    final uri = Uri.parse('$baseUrl/?q=${postalCode.value}&type=municipality&limit=1');

    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;

        if (features.isEmpty) {
          throw PostalCodeNotFoundException(postalCode.value);
        }

        return CityLocation.fromJson(features[0]);
      } else if (response.statusCode == 404) {
        throw PostalCodeNotFoundException(postalCode.value);
      } else {
        throw ServerException('HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw ServerException('Request timeout');
    }
  }

  void dispose() {
    client.close();
  }
}
```

**Custom Exceptions**:
```dart
class PostalCodeNotFoundException implements Exception {
  final String postalCode;
  PostalCodeNotFoundException(this.postalCode);

  @override
  String toString() => 'PostalCodeNotFoundException: $postalCode';
}

class NetworkException implements Exception {
  @override
  String toString() => 'NetworkException: No internet connection';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}
```

---

## 6. Screen State Management

**Purpose**: Manage UI state in HomeScreen (StatefulWidget)

**State Class Structure**:
```dart
class _HomeScreenState extends State<HomeScreen> {
  final _geocodingService = ApiAdresseGeocodingService();
  final _postalCodeController = TextEditingController();

  MapState _mapState = MapState.idle;
  CityLocation? _currentLocation;
  ErrorType? _errorType;
  Future<CityLocation>? _pendingRequest;  // For request cancellation

  @override
  void dispose() {
    _postalCodeController.dispose();
    _geocodingService.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Cancel pending request (FR-013)
    _pendingRequest = null;

    final postalCode = PostalCode(_postalCodeController.text.trim());

    // Validate
    if (postalCode.isEmpty) {
      setState(() {
        _mapState = MapState.error;
        _errorType = ErrorType.emptyInput;
      });
      return;
    }

    if (!postalCode.isValid) {
      setState(() {
        _mapState = MapState.error;
        _errorType = ErrorType.invalidFormat;
      });
      return;
    }

    // Fetch location
    setState(() {
      _mapState = MapState.loading;
      _errorType = null;
    });

    _pendingRequest = _geocodingService.fetchLocation(postalCode);

    try {
      final location = await _pendingRequest!;
      if (_pendingRequest != null) {  // Check not cancelled
        setState(() {
          _mapState = MapState.success;
          _currentLocation = location;
        });
      }
    } on PostalCodeNotFoundException {
      if (_pendingRequest != null) {
        setState(() {
          _mapState = MapState.error;
          _errorType = ErrorType.notFound;
        });
      }
    } on NetworkException {
      if (_pendingRequest != null) {
        setState(() {
          _mapState = MapState.error;
          _errorType = ErrorType.networkError;
        });
      }
    } on ServerException {
      if (_pendingRequest != null) {
        setState(() {
          _mapState = MapState.error;
          _errorType = ErrorType.serverError;
        });
      }
    }
  }
}
```

---

## Summary

**Entities Defined**: 5
1. PostalCode (Value Object) - Input validation
2. CityLocation (Entity) - Geographic data
3. MapState (Enum) - UI state tracking
4. ErrorType (Enum) - Error categorization
5. GeocodingService (Service) - API communication

**Key Relationships**:
- PostalCode → GeocodingService → CityLocation
- MapState + ErrorType → UI rendering decisions
- HomeScreen state manages all interactions

**Immutability**: All entities are immutable (final fields)

**Null Safety**: Full null safety with proper nullable types (?)

**Testing Strategy**:
- Unit tests for PostalCode validation
- Unit tests for CityLocation.fromJson parsing
- Service tests with mocked HTTP client
- Widget tests for state transitions
