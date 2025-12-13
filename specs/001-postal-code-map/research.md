# Research: Postal Code Map Viewer

**Feature**: 001-postal-code-map
**Date**: 2025-12-13
**Purpose**: Resolve technical unknowns and research best practices for Flutter map integration with geocoding

## Research Tasks Completed

### 1. Flutter Map Integration Options

**Decision**: Use `flutter_map` with OpenStreetMap tiles

**Rationale**:
- **flutter_map** (https://pub.dev/packages/flutter_map) is the most mature and actively maintained open-source mapping solution for Flutter
- Supports OpenStreetMap tiles (free, no API key required)
- ~3.5M downloads, actively maintained, excellent documentation
- Provides all required features: zoom, pan, center on coordinates, marker support
- Lightweight (no heavy SDK like Google Maps)
- Cross-platform (iOS + Android with same API)

**Alternatives Considered**:
1. **google_maps_flutter**: Requires Google Maps API key, billing setup, and separate iOS/Android configuration. Rejected due to "minimal libraries" requirement and setup complexity.
2. **mapbox_gl**: Requires API key and account setup. Rejected for same reasons as Google Maps.
3. **Custom tile rendering**: Too complex for MVP. Rejected due to development time.

**Implementation Notes**:
- Add `flutter_map: ^7.0.0` and `latlong2: ^0.9.0` to pubspec.yaml
- Use OpenStreetMap tile server: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- Initial zoom level 13 as specified in requirements
- Attribution required per OSM usage policy (add to map display)

---

### 2. French Postal Code Geocoding Service

**Decision**: Use Gouvernement Français API gouv.fr (api-adresse.data.gouv.fr)

**Rationale**:
- **API Adresse** (https://adresse.data.gouv.fr) is the official French government geocoding API
- Free, no API key required, no rate limits for reasonable use
- Specifically designed for French addresses and postal codes
- Returns geographic coordinates, city names, and administrative data
- REST API with JSON responses
- Official government data source (most accurate for French postal codes)

**API Endpoint**:
```
GET https://api-adresse.data.gouv.fr/search/?q={postalCode}&type=municipality&limit=1
```

**Response Format**:
```json
{
  "features": [{
    "geometry": {
      "coordinates": [longitude, latitude]
    },
    "properties": {
      "label": "City Name",
      "postcode": "75001",
      "city": "Paris"
    }
  }]
}
```

**Alternatives Considered**:
1. **Nominatim (OpenStreetMap)**: Good but less accurate for French postal codes. Requires rate limiting (1 req/sec). Rejected for accuracy reasons.
2. **Google Geocoding API**: Requires API key and billing. Rejected due to setup complexity.
3. **Mapbox Geocoding**: Requires API key. Rejected for same reason.

**Implementation Notes**:
- Use `http` package (^1.2.0) for REST calls
- Handle HTTP errors (network issues, 429 rate limits, 500 server errors)
- Parse JSON with `dart:convert`
- No authentication required

---

### 3. HTTP Client Best Practices in Flutter

**Decision**: Use `package:http` with proper error handling and request cancellation

**Rationale**:
- `http` package is the official, lightweight HTTP client for Dart/Flutter
- Simple API for GET/POST requests
- Easy to mock for unit testing
- Supports request cancellation via `HttpClient` or manual tracking

**Best Practices Implemented**:
1. **Request Cancellation (FR-013)**: Track pending request and cancel on new submission
   - Store current request `Future` or use `CancelToken` pattern
   - Cancel previous request before starting new one
2. **Error Handling**: Wrap all HTTP calls in try-catch
   - `SocketException`: Network connectivity issues → FR-011 error message
   - `TimeoutException`: Server timeout → "Service unavailable" message
   - HTTP 404: Postal code not found → FR-006 error message
   - HTTP 429: Rate limit → "Too many requests, please wait"
3. **Timeout Configuration**: Set reasonable timeout (e.g., 10 seconds)
4. **Response Validation**: Check HTTP status codes and JSON structure

**Code Pattern**:
```dart
Future<CityLocation?> fetchLocation(String postalCode) async {
  try {
    final response = await http
        .get(Uri.parse('https://api-adresse.data.gouv.fr/search/?q=$postalCode'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      // Parse JSON
    } else if (response.statusCode == 404) {
      throw PostalCodeNotFoundException();
    }
  } on SocketException {
    throw NetworkException();
  } on TimeoutException {
    throw ServiceUnavailableException();
  }
}
```

---

### 4. State Management for Single-Screen App

**Decision**: Use `StatefulWidget` with built-in `setState` (no external state management library)

**Rationale**:
- Single screen with simple state (input value, loading boolean, error message, map coordinates)
- No need for complex state management (Provider, Riverpod, Bloc) for MVP
- Reduces dependencies (aligns with "minimal libraries" requirement)
- State transitions are straightforward: idle → loading → success/error
- Flutter's built-in state management is sufficient for this scope

**State Structure**:
```dart
class _HomeScreenState extends State<HomeScreen> {
  String _postalCode = '';
  bool _isLoading = false;
  String? _errorMessage;
  CityLocation? _location;

  // Methods: _validateAndSubmit(), _fetchLocation(), _showError()
}
```

**Alternatives Considered**:
1. **Provider**: Overkill for single screen. Rejected for simplicity.
2. **Riverpod**: Modern but adds dependency. Rejected per requirements.
3. **Bloc**: Too complex for this use case. Rejected.

---

### 5. Input Validation Pattern

**Decision**: Validate on submission with RegExp pattern matching

**Rationale**:
- Spec specifies no real-time validation (clarification #4)
- Simple validation: exactly 5 digits
- RegExp pattern: `^[0-9]{5}$`
- Validate before making HTTP request (FR-002)

**Implementation**:
```dart
class PostalCode {
  static final _validationPattern = RegExp(r'^[0-9]{5}$');

  final String value;

  PostalCode(this.value) {
    if (!_validationPattern.hasMatch(value)) {
      throw FormatException('Please enter a valid 5-digit French postal code');
    }
  }

  bool get isValid => _validationPattern.hasMatch(value);
}
```

---

### 6. Testing Strategy for Flutter Maps

**Decision**: Use mocks for geocoding service, widget tests for map display

**Rationale**:
- Unit tests: Mock HTTP responses using `package:mocktail` or `package:mockito`
- Widget tests: Verify map widget renders with correct center/zoom
- Integration tests: Full flow with real geocoding API (or mock server)
- No golden tests required for MVP (can add later for map appearance)

**Test Structure**:
```dart
// Unit test
test('PostalCode validation rejects invalid format', () {
  expect(() => PostalCode('123'), throwsFormatException);
});

// Widget test
testWidgets('MapDisplay shows map at correct coordinates', (tester) async {
  await tester.pumpWidget(MapDisplay(location: parisLocation));
  expect(find.byType(FlutterMap), findsOneWidget);
});

// Integration test
testWidgets('Full flow: enter postal code and see map', (tester) async {
  // Enter '75001', tap submit, verify map appears
});
```

---

## Summary of Technical Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Map Library** | flutter_map + OpenStreetMap | Free, mature, no API key, cross-platform |
| **Geocoding** | API Adresse (gouv.fr) | Official French government API, free, accurate |
| **HTTP Client** | package:http | Official, lightweight, easy to mock |
| **State Management** | StatefulWidget | Simple, no external deps, sufficient for MVP |
| **Validation** | RegExp on submission | Meets spec, simple implementation |
| **Testing** | mocktail + widget tests | Standard Flutter testing approach |

**All "NEEDS CLARIFICATION" items resolved. Ready for Phase 1 design.**
