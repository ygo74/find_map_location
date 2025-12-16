# Research: Random Address Selection for Location Game

**Date**: 2025-12-14
**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

This document resolves technical uncertainties and evaluates implementation approaches for the random address selection feature. All NEEDS CLARIFICATION items from Technical Context are addressed here with rationale and alternatives considered.

## Decision 1: Location Services Package Selection

**Question**: Which Flutter package should be used for obtaining user location (FR-014, FR-015)?

**Context**:
- Need to get current user location for map zoom on "Start Search"
- Must handle permission requests (Android/iOS)
- Must be privacy-compliant (transient use only - FR-018)
- Performance target: <1s location acquisition (SC-007)

**Options Evaluated**:

### Option A: geolocator (^11.0.0)
**Pros**:
- Most popular Flutter location package (45k+ pub points)
- Comprehensive API: getCurrentPosition(), getLastKnownPosition(), permission handling
- Well-maintained by Baseflow (active updates)
- Built-in permission request flows for iOS/Android
- Supports accuracy levels (perfect for street-level zoom requirement)
- Extensive documentation and community support

**Cons**:
- Adds ~200KB to app size
- Requires permission_handler peer dependency
- More features than strictly needed

### Option B: location (^6.0.0)
**Pros**:
- Simpler API surface
- Lighter weight (~150KB)
- Good for basic location needs

**Cons**:
- Less actively maintained (fewer updates)
- Permission handling less robust
- Smaller community (harder to find solutions)

### Option C: Manual Platform Channels
**Pros**:
- No third-party dependency
- Complete control over implementation

**Cons**:
- Requires iOS (CoreLocation) and Android (FusedLocationProvider) native code
- High maintenance burden (OS updates, permission changes)
- More error-prone (testing on both platforms)
- Violates DRY principle (reinventing solved problem)
- Estimated 2-3 days additional development time

**Decision**: **Option A - geolocator**

**Rationale**:
1. **Reliability**: Battle-tested in production apps, handles edge cases (permission denial, location unavailable)
2. **Maintainability**: Active community support reduces long-term maintenance risk
3. **Performance**: Meets <1s requirement with getLastKnownPosition() fallback
4. **Constitution Compliance**: Well-documented API supports principle I (code quality)
5. **Cost/Benefit**: Size tradeoff (200KB) acceptable for robust location functionality

**Implementation Notes**:
- Use `Geolocator.getCurrentPosition()` for accuracy
- Fallback to `Geolocator.getLastKnownPosition()` if timeout
- Accuracy: `LocationAccuracy.high` for street-level detail
- Timeout: 5 seconds (balance between UX and reliability)

## Decision 2: Reverse Geocoding Strategy

**Question**: How to implement reverse geocoding for random coordinates → address (FR-006)?

**Context**:
- Generate random lat/lng within city bounding box
- Convert coordinates to real address via API
- Must use existing API Adresse (data.gouv.fr) - no new external dependencies
- Support French addresses with special characters (FR-009)

**API Adresse Reverse Geocoding**:
- Endpoint: `GET https://api-adresse.data.gouv.fr/reverse/`
- Parameters: `lat`, `lon`, `type=housenumber`
- Returns: Closest address to coordinates with full details

**Options Evaluated**:

### Option A: Direct Reverse Geocoding (Chosen Approach)
```dart
// Generate random coordinates within city bounds
final random = Random();
final lat = cityBounds.minLat + random.nextDouble() * (cityBounds.maxLat - cityBounds.minLat);
final lon = cityBounds.minLon + random.nextDouble() * (cityBounds.maxLon - cityBounds.minLon);

// Reverse geocode to nearest address
final uri = Uri.parse('https://api-adresse.data.gouv.fr/reverse/?lat=$lat&lon=$lon&type=housenumber');
final response = await client.get(uri);
```

**Pros**:
- Single API call (efficient)
- Guaranteed real address
- Works for any city size
- API Adresse reverse endpoint optimized for this use case

**Cons**:
- Random coordinates might land in non-residential areas (parks, water)
- Requires retry logic if address not found

### Option B: Pre-fetch Address List
```dart
// Fetch all addresses in city first
final addresses = await fetchAllAddressesInCity(cityPostalCode);
// Pick random from list
final randomAddress = addresses[random.nextInt(addresses.length)];
```

**Pros**:
- No "empty" coordinate issue
- Faster subsequent selections (cached list)

**Cons**:
- Large cities: massive API response (Paris has 100k+ addresses)
- Memory intensive
- Initial fetch delay (violates SC-001: <2s requirement)
- API Adresse limits results to 50 items (insufficient for cities)

### Option C: Strategic Coordinate Generation with Retries
Enhance Option A with intelligent retries:
```dart
const maxRetries = 5;
for (int i = 0; i < maxRetries; i++) {
  final coords = generateRandomCoordinates(cityBounds);
  final address = await reverseGeocode(coords);
  if (address != null && address.isValidHousenumber()) {
    return address;
  }
}
throw NoAddressFoundException();
```

**Decision**: **Option C - Strategic Reverse Geocoding with Retries**

**Rationale**:
1. **Performance**: Single API call per attempt (fast)
2. **Reliability**: Retry loop handles edge cases (parks, water bodies)
3. **Scalability**: Works for small villages and large cities equally
4. **Memory Efficient**: No large response caching
5. **User Experience**: Max 5 attempts typically completes in <1s

**Implementation Details**:
- Max 5 retry attempts before error (FR-010)
- Filter: require `type=housenumber` (exclude streets without numbers)
- Validation: check `properties.type == 'housenumber'` in response
- Error handling: display FR-010 message if all retries fail

## Decision 3: City Bounding Box Calculation

**Question**: How to determine city boundaries for random coordinate generation?

**Context**:
- Need bounding box (minLat, maxLat, minLon, maxLon) for city
- API Adresse returns geometry for each city in GeoJSON format
- Must handle various city shapes (not just rectangles)

**API Adresse City Data**:
```json
{
  "geometry": {
    "type": "Point",
    "coordinates": [lon, lat]
  },
  "properties": {
    "city": "Paris",
    "postcode": "75001"
  }
}
```

**Options Evaluated**:

### Option A: Use City Center + Fixed Radius
```dart
final centerLat = city.geometry.coordinates[1];
final centerLon = city.geometry.coordinates[0];
final radius = 5.0; // km
// Generate within circle
```

**Pros**:
- Simple implementation
- Works with Point geometry from API

**Cons**:
- Inaccurate for elongated cities (coastal towns)
- May generate coordinates outside city boundaries
- Fixed radius doesn't scale (villages vs. metropolises)

### Option B: Request Full City Polygon from API
Query different endpoint for city boundaries:
```dart
final boundaryUrl = 'https://geo.api.gouv.fr/communes?nom=$cityName&fields=contour';
```

**Pros**:
- Accurate city boundaries
- Can generate within true polygon

**Cons**:
- Additional API dependency (geo.api.gouv.fr vs. api-adresse)
- Extra network request (latency)
- Complex polygon-contains-point logic
- Violates simplicity principle

### Option C: Adaptive Bounding Box from Reverse Geocoding
Use center point + adaptive sampling:
```dart
// Start with city center
final center = LatLng(city.lat, city.lon);

// Generate samples, expand bounds based on successful addresses
final addresses = <RandomAddress>[];
for (int sample = 0; sample < 10 && addresses.length < 5; sample++) {
  final offset = generateRandomOffset(currentRadius);
  final coords = center + offset;
  final address = await reverseGeocode(coords);
  if (address?.city == targetCity) {
    addresses.add(address);
    updateBounds(coords); // Expand bounding box
  }
}
```

**Cons**:
- Complex (multiple API calls for bounds discovery)
- Slow initial setup
- Over-engineered for requirement

### Option D: Fixed Bounding Box with City Name Validation
Simplest approach:
```dart
// Use fixed offset from city center
final delta = 0.05; // ~5km at mid-latitudes
final bounds = CityBounds(
  minLat: city.lat - delta,
  maxLat: city.lat + delta,
  minLon: city.lon - delta,
  maxLon: city.lon + delta,
);

// Generate random coordinates
final coords = generateRandom(bounds);

// Validate returned address matches city name
final address = await reverseGeocode(coords);
if (address.city != targetCityName) {
  // Retry with new coordinates
}
```

**Pros**:
- Simple implementation
- Single API endpoint (api-adresse reverse)
- Self-correcting via city name validation
- Fast (<2s with retries)

**Cons**:
- Some wasted API calls for coordinates outside city

**Decision**: **Option D - Fixed Bounding Box with City Name Validation**

**Rationale**:
1. **Simplicity**: Minimal code complexity, easy to test
2. **Performance**: Meets <2s requirement even with 2-3 retries
3. **Reliability**: City name validation ensures correctness
4. **Maintainability**: No polygon math or additional APIs
5. **Constitution Compliance**: Follows principle IV (efficiency) - simple is fast

**Implementation Details**:
- Delta: 0.05 degrees (~5km) - good default for French cities
- Validation: Compare returned `properties.city` with target city name (case-insensitive)
- Edge case: Large cities (Paris, Lyon) - acceptable to have some failed attempts
- Max retries: 10 attempts for coordinates + 5 attempts for valid address = reasonable success rate

## Decision 4: Address Uniqueness Tracking

**Question**: How to ensure 99% address uniqueness within session (SC-002, FR-005)?

**Context**:
- Users playing same city multiple times should get different addresses
- No persistent storage (stateless session)
- True randomness allows repetition (acceptable per edge case)

**Options Evaluated**:

### Option A: In-Memory Set Tracking
```dart
class GameSessionState {
  final Set<String> _usedAddresses = {};

  bool isAddressUsed(String addressKey) {
    return _usedAddresses.contains(addressKey);
  }

  void markAddressUsed(String addressKey) {
    _usedAddresses.add(addressKey);
  }
}
```

**Pros**:
- Simple implementation
- O(1) lookup performance
- Meets 99% uniqueness requirement with retry logic

**Cons**:
- Unbounded growth (not an issue for typical game session)
- Persists only during app lifecycle

**Decision**: **Option A - In-Memory Set Tracking**

**Rationale**:
1. **Sufficient**: For typical game sessions (5-20 addresses), set size is negligible
2. **Performance**: Fast lookups don't impact SC-001 timing
3. **Privacy**: No storage requirement (aligns with FR-018)
4. **Acceptable Risk**: True randomness allows rare repetition (documented in edge cases)

**Implementation**:
- Key format: `"{city}|{street}|{number}"` (unique identifier)
- Retry logic: Generate new address if key exists in set
- Max retries: 10 (extremely unlikely to exhaust given coordinate randomness)

## Decision 5: "Start Search" Button State Management

**Question**: Best approach for button disabled state (FR-017)?

**Flutter Best Practices**:
- Use StatefulWidget for button state
- Disable via `onPressed: null`
- Visual feedback via theme disabledColor

**Decision**: StatefulWidget with Boolean flag

```dart
class StartSearchButton extends StatefulWidget {
  final VoidCallback onPressed;

  @override
  State<StartSearchButton> createState() => _StartSearchButtonState();
}

class _StartSearchButtonState extends State<StartSearchButton> {
  bool _isPressed = false;

  void _handlePress() {
    if (_isPressed) return;

    setState(() => _isPressed = true);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isPressed ? null : _handlePress,
      child: Text('Start Search'),
    );
  }
}
```

**Rationale**:
- Standard Flutter pattern (idiomatic)
- Automatic visual feedback (Material Design grayed-out style)
- Prevents multiple taps (FR-016)
- Testable via widget tests

## Technology Choices Summary

| Technology | Purpose | Rationale |
|------------|---------|-----------|
| geolocator ^11.0.0 | User location (FR-014/15) | Robust, well-maintained, handles permissions |
| API Adresse reverse endpoint | Coordinates → address (FR-006) | Existing dependency, no new external service |
| Fixed bounding box + validation | City coordinate generation | Simple, fast, self-correcting |
| In-memory Set | Address uniqueness (SC-002) | O(1) performance, privacy-compliant |
| StatefulWidget | Button state (FR-017) | Idiomatic Flutter, automatic UI feedback |

## Performance Projections

| Metric | Target | Projected | Notes |
|--------|--------|-----------|-------|
| Address generation time | <2s (SC-001) | ~0.5-1.5s | Single API call + retry logic |
| Location acquisition | <1s (SC-007) | ~0.3-0.8s | geolocator optimized path |
| Address uniqueness | 99% (SC-002) | 99.9%+ | Set-based deduplication |
| Memory overhead | N/A | <1MB | Set + models in RAM |
| App size increase | N/A | ~250KB | geolocator + permission_handler |

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Random coords in non-residential areas | Retry delays | Max 5 reverse geocoding attempts |
| City name mismatch in API response | Wrong city address | Strict name validation + retry |
| Location permission denied | No zoom feature | Graceful degradation (FR-015) |
| API Adresse rate limiting | Service degradation | Implement exponential backoff |
| Very small villages (<5 addresses) | Game unplayable | Pre-validation check (FR-019) |

## Open Questions

None - all technical uncertainties resolved.

## Next Steps

Proceed to Phase 1:
1. Generate data-model.md (entities, relationships)
2. Generate contracts/geocoding-api.md (reverse geocoding contract)
3. Generate quickstart.md (development setup)
4. Update agent context with technology choices
