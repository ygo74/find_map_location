# API Contract: API Adresse Reverse Geocoding

**Date**: 2025-12-14
**Feature**: [spec.md](../spec.md) | **Data Model**: [data-model.md](../data-model.md)

## Overview

This contract defines the reverse geocoding endpoint of API Adresse (French government geocoding service) used to convert random coordinates into real street addresses for the location game.

**Base URL**: `https://api-adresse.data.gouv.fr`
**Endpoint**: `/reverse/`
**Method**: GET
**Authentication**: None (public API)
**Rate Limiting**: Not officially documented; implement exponential backoff if 429 received

## Reverse Geocoding Endpoint

### Request

**Endpoint**: `GET /reverse/`

**Query Parameters**:
| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| lat | number | Yes | Latitude coordinate | `48.8606` |
| lon | number | Yes | Longitude coordinate | `2.3376` |
| type | string | No | Filter by feature type | `housenumber` (recommended) |

**Example Request**:
```http
GET /reverse/?lat=48.8606&lon=2.3376&type=housenumber HTTP/1.1
Host: api-adresse.data.gouv.fr
Accept: application/json
```

**cURL Example**:
```bash
curl "https://api-adresse.data.gouv.fr/reverse/?lat=48.8606&lon=2.3376&type=housenumber"
```

### Response

**Success Response (200 OK)**:

```json
{
  "type": "FeatureCollection",
  "version": "draft",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [2.3376, 48.8606]
      },
      "properties": {
        "label": "42 Rue de Rivoli 75001 Paris",
        "score": 0.9896819812923914,
        "housenumber": "42",
        "id": "75101_7560_00042",
        "name": "42 Rue de Rivoli",
        "postcode": "75001",
        "citycode": "75101",
        "x": 652225.58,
        "y": 6862263.83,
        "city": "Paris",
        "context": "75, Paris, Île-de-France",
        "type": "housenumber",
        "importance": 0.71234,
        "street": "Rue de Rivoli",
        "distance": 12
      }
    }
  ],
  "attribution": "BAN",
  "licence": "ODbL 1.0",
  "limit": 1
}
```

**Field Descriptions**:

| Field | Type | Always Present | Description | Usage in RandomAddress |
|-------|------|----------------|-------------|------------------------|
| features | array | Yes | Array of found addresses (usually 1) | Take first element |
| features[].geometry.coordinates | [lon, lat] | Yes | Coordinates of found address | Validate matches input |
| features[].properties.housenumber | string | No | House/building number | RandomAddress.streetNumber |
| features[].properties.street | string | No | Street name without number | RandomAddress.streetName |
| features[].properties.city | string | Yes | City name | RandomAddress.cityName (validate match) |
| features[].properties.postcode | string | Yes | Postal code | RandomAddress.postcode |
| features[].properties.label | string | Yes | Full formatted address | For debugging/logging |
| features[].properties.type | string | Yes | Feature type | Validate = "housenumber" |
| features[].properties.distance | number | Yes | Distance from query point (meters) | Log for debugging |
| features[].properties.score | number | Yes | Confidence score (0-1) | Ignore (always use closest) |

**Empty Result Response (200 OK)**:
```json
{
  "type": "FeatureCollection",
  "version": "draft",
  "features": [],
  "attribution": "BAN",
  "licence": "ODbL 1.0",
  "limit": 1
}
```

**Interpretation**: No address found at these coordinates (e.g., water body, park, forest).
**Action**: Retry with different random coordinates.

### Error Responses

**400 Bad Request**:
```json
{
  "error": "missing required parameter: lat"
}
```
**Causes**: Missing or invalid lat/lon parameters
**Action**: Internal error - should not occur with correct implementation

**429 Too Many Requests**:
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
```
**Causes**: Rate limiting triggered
**Action**: Implement exponential backoff, respect Retry-After header

**500 Internal Server Error**:
```json
{
  "error": "Internal server error"
}
```
**Causes**: API service degradation
**Action**: Display user-friendly error message (FR-010)

**503 Service Unavailable**:
```http
HTTP/1.1 503 Service Unavailable
```
**Causes**: API maintenance or overload
**Action**: Display user-friendly error message (FR-010)

## Implementation Guidelines

### Dart/Flutter Implementation

```dart
class ApiAdresseGeocodingService {
  static const String reverseUrl = 'https://api-adresse.data.gouv.fr/reverse/';
  static const Duration timeout = Duration(seconds: 10);

  final http.Client client;

  Future<RandomAddress?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse('$reverseUrl?lat=$lat&lon=$lon&type=housenumber');

    try {
      final response = await client.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final features = json['features'] as List<dynamic>;

        if (features.isEmpty) {
          return null; // No address at this location
        }

        final feature = features[0] as Map<String, dynamic>;
        final properties = feature['properties'] as Map<String, dynamic>;

        // Validate it's a housenumber type
        if (properties['type'] != 'housenumber') {
          return null;
        }

        // Extract address components
        final housenumber = properties['housenumber'] as String?;
        final street = properties['street'] as String?;
        final city = properties['city'] as String;
        final postcode = properties['postcode'] as String;
        final coords = feature['geometry']['coordinates'] as List<dynamic>;

        // Validate completeness (FR-004)
        if (housenumber == null || street == null) {
          return null;
        }

        return RandomAddress(
          streetNumber: housenumber,
          streetName: street,
          cityName: city,
          postcode: postcode,
          latitude: coords[1] as double,  // Note: [lon, lat] order
          longitude: coords[0] as double,
          generatedAt: DateTime.now().toUtc(),
        );
      } else if (response.statusCode == 429) {
        throw RateLimitException();
      } else if (response.statusCode >= 500) {
        throw ServerException('Server error: ${response.statusCode}');
      } else {
        throw ServerException('Unexpected error: ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw ServerException('Request timeout');
    } on FormatException {
      throw ServerException('Invalid response format');
    }
  }
}
```

### Validation Logic

```dart
bool isValidAddress(Map<String, dynamic> properties, String targetCity) {
  // Must be housenumber type
  if (properties['type'] != 'housenumber') {
    return false;
  }

  // Must have complete address components
  if (properties['housenumber'] == null || properties['street'] == null) {
    return false;
  }

  // Must match target city (case-insensitive)
  final city = (properties['city'] as String).toLowerCase();
  final target = targetCity.toLowerCase();
  if (city != target) {
    return false;
  }

  return true;
}
```

### Retry Strategy

```dart
Future<RandomAddress> generateRandomAddressWithRetry(
  City city,
  {int maxAttempts = 10}
) async {
  final bounds = CityBounds.fromCityCenter(city);
  final random = Random();

  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    // Generate random coordinates
    final coords = bounds.generateRandomCoordinate(random);

    // Try reverse geocoding
    try {
      final address = await reverseGeocode(coords.latitude, coords.longitude);

      if (address != null && address.isInCity(city)) {
        return address;
      }
    } on RateLimitException {
      // Exponential backoff
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
      continue;
    } on NetworkException {
      throw NetworkException(); // Don't retry network issues
    }
  }

  throw NoAddressFoundException('Could not generate valid address after $maxAttempts attempts');
}
```

## Testing Contract

### Mock Responses

**Success Case (Valid Housenumber)**:
```dart
const mockSuccessResponse = '''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "geometry": {"type": "Point", "coordinates": [2.3376, 48.8606]},
    "properties": {
      "label": "42 Rue de Rivoli 75001 Paris",
      "housenumber": "42",
      "street": "Rue de Rivoli",
      "city": "Paris",
      "postcode": "75001",
      "type": "housenumber",
      "distance": 5
    }
  }]
}
''';
```

**Empty Result (No Address)**:
```dart
const mockEmptyResponse = '''
{
  "type": "FeatureCollection",
  "features": []
}
''';
```

**Invalid Type (Street Without Number)**:
```dart
const mockStreetResponse = '''
{
  "type": "FeatureCollection",
  "features": [{
    "type": "Feature",
    "properties": {
      "label": "Rue de Rivoli 75001 Paris",
      "street": "Rue de Rivoli",
      "city": "Paris",
      "postcode": "75001",
      "type": "street"
    }
  }]
}
''';
```

### Unit Test Scenarios

```dart
group('Reverse Geocoding', () {
  test('parses valid housenumber response', () async {
    // Arrange: Mock HTTP client returns success
    final client = MockClient((request) async {
      return http.Response(mockSuccessResponse, 200);
    });
    final service = ApiAdresseGeocodingService(client: client);

    // Act
    final address = await service.reverseGeocode(48.8606, 2.3376);

    // Assert
    expect(address, isNotNull);
    expect(address!.streetNumber, '42');
    expect(address.streetName, 'Rue de Rivoli');
    expect(address.cityName, 'Paris');
  });

  test('returns null for empty features', () async {
    // Arrange: Mock empty response
    final client = MockClient((request) async {
      return http.Response(mockEmptyResponse, 200);
    });
    final service = ApiAdresseGeocodingService(client: client);

    // Act
    final address = await service.reverseGeocode(48.0, 2.0);

    // Assert
    expect(address, isNull);
  });

  test('returns null for non-housenumber types', () async {
    // Arrange: Mock street (not housenumber) response
    final client = MockClient((request) async {
      return http.Response(mockStreetResponse, 200);
    });
    final service = ApiAdresseGeocodingService(client: client);

    // Act
    final address = await service.reverseGeocode(48.8606, 2.3376);

    // Assert
    expect(address, isNull);
  });

  test('throws RateLimitException on 429', () async {
    // Arrange: Mock 429 response
    final client = MockClient((request) async {
      return http.Response('', 429);
    });
    final service = ApiAdresseGeocodingService(client: client);

    // Act & Assert
    expect(
      () => service.reverseGeocode(48.8606, 2.3376),
      throwsA(isA<RateLimitException>()),
    );
  });
});
```

## Performance Characteristics

**Typical Response Times** (measured from French network):
- p50: ~150ms
- p95: ~500ms
- p99: ~1000ms

**Response Size**:
- Single result: ~800 bytes (JSON)
- Empty result: ~120 bytes (JSON)

**Timeout Strategy**:
- Connection timeout: 10 seconds
- Read timeout: 10 seconds
- Total request timeout: 10 seconds

**Caching**: Not recommended - each game session needs unique addresses

## Error Messages

### User-Facing (FR-010)

| Scenario | Message |
|----------|---------|
| No address found after retries | "Unable to generate address for this location. Please try a different city." |
| Network error | "Unable to generate address for this location. Please check your connection and try again." |
| Server error (500/503) | "Address service temporarily unavailable. Please try again later." |
| Rate limiting (429) | "Too many requests. Please wait a moment and try again." |

## References

- **Official Documentation**: https://adresse.data.gouv.fr/api-doc/adresse
- **Data Source**: Base Adresse Nationale (BAN)
- **License**: Open Database License (ODbL) 1.0
- **Attribution**: Required: "Données BAN" or similar

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-14 | 1.0 | Initial contract for reverse geocoding endpoint |
