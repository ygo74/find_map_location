# API Contract: Geocoding Service

**Provider**: API Adresse (French Government)
**Base URL**: https://api-adresse.data.gouv.fr
**Authentication**: None required
**Rate Limits**: Fair use policy (no strict limits documented)

---

## Endpoint: Search Address/Postal Code

**Method**: GET
**Path**: `/search/`
**Purpose**: Geocode French postal codes to geographic coordinates

### Request Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `q` | string | Yes | Postal code to search | `75001` |
| `type` | string | No | Filter by type (use `municipality`) | `municipality` |
| `limit` | integer | No | Maximum results (use `1` for single result) | `1` |

### Request Example

```http
GET /search/?q=75001&type=municipality&limit=1 HTTP/1.1
Host: api-adresse.data.gouv.fr
Accept: application/json
```

```dart
// Dart/Flutter example
final uri = Uri.parse('https://api-adresse.data.gouv.fr/search/?q=75001&type=municipality&limit=1');
final response = await http.get(uri);
```

---

### Response Format

**Content-Type**: `application/json; charset=utf-8`

#### Success Response (200 OK)

```json
{
  "type": "FeatureCollection",
  "version": "draft",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [2.347870, 48.862270]
      },
      "properties": {
        "label": "Paris 1er Arrondissement",
        "score": 0.99,
        "id": "75101",
        "type": "municipality",
        "name": "Paris 1er Arrondissement",
        "postcode": "75001",
        "citycode": "75101",
        "x": 651367.05,
        "y": 6862305.26,
        "city": "Paris",
        "context": "75, Paris, Île-de-France",
        "importance": 0.67897,
        "municipality": "Paris 1er Arrondissement"
      }
    }
  ],
  "attribution": "BAN",
  "licence": "ODbL 1.0",
  "query": "75001",
  "limit": 1
}
```

#### Empty Result (200 OK - No Matches)

```json
{
  "type": "FeatureCollection",
  "version": "draft",
  "features": [],
  "attribution": "BAN",
  "licence": "ODbL 1.0",
  "query": "00000",
  "limit": 1
}
```

**Status**: `200 OK` but `features` array is empty
**Application Handling**: Treat as "postal code not found" error (FR-006)

---

### Response Fields

#### Geometry Object

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `type` | string | Geometry type (always "Point") | Yes |
| `coordinates` | array | `[longitude, latitude]` (note: **longitude first**) | Yes |

**Important**: API returns coordinates as `[longitude, latitude]` but most mapping libraries expect `[latitude, longitude]`. Ensure proper ordering when constructing `LatLng` objects.

#### Properties Object (Relevant Fields)

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `label` | string | Full formatted address label | Yes |
| `city` | string | City name | Yes |
| `postcode` | string | Postal code (5 digits) | Yes |
| `name` | string | Administrative area name | Yes |
| `context` | string | Administrative hierarchy | No |
| `score` | number | Relevance score (0-1) | Yes |

---

### Error Responses

#### 400 Bad Request

```json
{
  "error": "Missing query parameter"
}
```

**Application Handling**: Should not occur if app validates input correctly

#### 429 Too Many Requests

```
HTTP/1.1 429 Too Many Requests
Content-Type: text/plain

Too Many Requests
```

**Application Handling**: Show "Service temporarily unavailable. Please try again later."

#### 500 Internal Server Error

```
HTTP/1.1 500 Internal Server Error
```

**Application Handling**: Show "Service temporarily unavailable. Please try again later."

#### Network Errors (SocketException)

**Cause**: No internet connectivity
**Application Handling**: Show "No internet connection. Please check your network and try again." (FR-011)

#### Timeout (TimeoutException)

**Cause**: Request exceeds timeout duration (10 seconds)
**Application Handling**: Show "Service temporarily unavailable. Please try again later."

---

## Contract Validation

### Required Validations

1. **HTTP Status Check**: Verify `response.statusCode == 200`
2. **JSON Structure**: Ensure `features` key exists
3. **Empty Results**: Check `features.length == 0` for not found case
4. **Coordinate Order**: API returns `[lon, lat]` - reverse to `[lat, lon]` for Flutter
5. **Required Fields**: Verify `geometry.coordinates`, `properties.city`, `properties.postcode` exist

### Error Mapping

| Condition | Exception | Error Message (FR) |
|-----------|-----------|-------------------|
| `features.isEmpty` | `PostalCodeNotFoundException` | FR-006: "No city found for postal code {code}" |
| `SocketException` | `NetworkException` | FR-011: "No internet connection..." |
| `TimeoutException` | `ServerException` | "Service temporarily unavailable..." |
| `statusCode == 429` | `ServerException` | "Too many requests..." |
| `statusCode >= 500` | `ServerException` | "Service temporarily unavailable..." |

---

## Dart Implementation Contract

```dart
/// Contract interface for geocoding services
abstract class GeocodingService {
  /// Fetches geographic location for a valid postal code.
  ///
  /// Throws:
  /// - [PostalCodeNotFoundException] if postal code doesn't exist
  /// - [NetworkException] if no internet connectivity
  /// - [ServerException] if API returns error or timeout
  Future<CityLocation> fetchLocation(PostalCode postalCode);
}

/// Response data contract
class CityLocation {
  final double latitude;   // -90 to 90
  final double longitude;  // -180 to 180
  final String cityName;   // Human-readable city name
  final String postalCode; // 5-digit postal code
  final String? label;     // Optional full address label

  CityLocation({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.postalCode,
    this.label,
  });

  /// Factory constructor to parse API Adresse JSON response
  factory CityLocation.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;

    return CityLocation(
      longitude: (coords[0] as num).toDouble(),  // API: [lon, lat]
      latitude: (coords[1] as num).toDouble(),
      cityName: properties['city'] as String,
      postalCode: properties['postcode'] as String,
      label: properties['label'] as String?,
    );
  }
}
```

---

## Testing Contract

### Unit Test Requirements

1. **Parse Valid Response**: Verify `CityLocation.fromJson` correctly parses API response
2. **Handle Empty Features**: Verify throws `PostalCodeNotFoundException` when `features.isEmpty`
3. **Network Error**: Verify throws `NetworkException` on `SocketException`
4. **Timeout**: Verify throws `ServerException` on `TimeoutException`
5. **Coordinate Order**: Verify latitude/longitude are correctly swapped from API format

### Mock Response Examples

```dart
// Mock success response for tests
const mockSuccessResponse = '''
{
  "features": [{
    "geometry": {"coordinates": [2.347870, 48.862270]},
    "properties": {
      "city": "Paris",
      "postcode": "75001",
      "label": "Paris 1er Arrondissement"
    }
  }]
}
''';

// Mock empty response for tests
const mockEmptyResponse = '{"features": []}';
```

---

## Attribution Requirements

Per OpenStreetMap and API Adresse terms:

```dart
// Display attribution on map
const attribution = 'Map data © OpenStreetMap | Geocoding © API Adresse (data.gouv.fr)';
```

**Placement**: Bottom of map widget (flutter_map handles OSM attribution automatically; add API Adresse credit)

---

## Rate Limiting & Best Practices

1. **Reasonable Use**: API has no strict rate limits but expects fair use
2. **Caching**: Consider caching results for repeated postal codes (not required for MVP)
3. **Request Cancellation**: Cancel pending requests when user submits new postal code (FR-013)
4. **Timeout**: Use 10-second timeout to avoid indefinite waiting
5. **Retry Logic**: Do not auto-retry on errors; require user action

---

## Version & Stability

- **API Version**: Draft (stable, in production use)
- **Breaking Changes**: None expected; government-maintained API
- **Monitoring**: No API status page; handle errors gracefully
- **Fallback**: No fallback API planned for MVP

---

## Summary

✅ **Contract Complete**
- Single GET endpoint: `/search/?q={postalCode}&type=municipality&limit=1`
- Returns GeoJSON with coordinates and city information
- No authentication required
- Error handling covers network, timeout, not found, and server errors
- Coordinate order: API gives `[lon, lat]`, app needs `[lat, lon]`
