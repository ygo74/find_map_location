# API Contract: Geocoding Service (Multiple Cities)

**Provider**: API Adresse (French Government)
**Base URL**: https://api-adresse.data.gouv.fr
**Authentication**: None required
**Rate Limits**: Fair use policy (no strict limits documented)
**Change Summary**: Updated `limit` parameter from `1` to `50` to support multiple cities per postal code

---

## Endpoint: Search Address/Postal Code

**Method**: GET
**Path**: `/search/`
**Purpose**: Geocode French postal codes to geographic coordinates (supports multiple cities per postal code)

### Request Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `q` | string | Yes | Postal code to search | `01630` |
| `type` | string | No | Filter by type (use `municipality`) | `municipality` |
| `limit` | integer | No | Maximum results (**use `50` for all cities**) | `50` |

**Change from Feature 001**: `limit` parameter changed from `1` to `50` to retrieve all cities sharing a postal code.

### Request Example

```http
GET /search/?q=01630&type=municipality&limit=50 HTTP/1.1
Host: api-adresse.data.gouv.fr
Accept: application/json
```

```dart
// Dart/Flutter example
final uri = Uri.parse('https://api-adresse.data.gouv.fr/search/?q=01630&type=municipality&limit=50');
final response = await http.get(uri);
```

---

### Response Format

**Content-Type**: `application/json; charset=utf-8`

#### Success Response - Single City (200 OK)

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
        "label": "Paris 1er Arrondissement, Paris",
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
  "limit": 50
}
```

**Application Handling**: Single feature → Display map immediately (FR-005)

---

#### Success Response - Multiple Cities (200 OK)

```json
{
  "type": "FeatureCollection",
  "version": "draft",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [6.023600, 46.243600]
      },
      "properties": {
        "label": "Saint-Genis-Pouilly, Ain",
        "score": 0.98,
        "id": "01354",
        "type": "municipality",
        "name": "Saint-Genis-Pouilly",
        "postcode": "01630",
        "citycode": "01354",
        "x": 953217.89,
        "y": 6570123.45,
        "city": "Saint-Genis-Pouilly",
        "context": "01, Ain, Auvergne-Rhône-Alpes",
        "importance": 0.52341,
        "municipality": "Saint-Genis-Pouilly"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [6.012300, 46.198700]
      },
      "properties": {
        "label": "Péron, Ain",
        "score": 0.97,
        "id": "01288",
        "type": "municipality",
        "name": "Péron",
        "postcode": "01630",
        "citycode": "01288",
        "x": 952145.67,
        "y": 6565234.89,
        "city": "Péron",
        "context": "01, Ain, Auvergne-Rhône-Alpes",
        "importance": 0.41234,
        "municipality": "Péron"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [6.044500, 46.258900]
      },
      "properties": {
        "label": "Sergy, Ain",
        "score": 0.96,
        "id": "01407",
        "type": "municipality",
        "name": "Sergy",
        "postcode": "01630",
        "citycode": "01407",
        "x": 954789.23,
        "y": 6571890.12,
        "city": "Sergy",
        "context": "01, Ain, Auvergne-Rhône-Alpes",
        "importance": 0.38567,
        "municipality": "Sergy"
      }
    }
  ],
  "attribution": "BAN",
  "licence": "ODbL 1.0",
  "query": "01630",
  "limit": 50
}
```

**Application Handling**: Multiple features → Show city selection screen (FR-002, FR-003)

---

#### Empty Result (200 OK - No Matches)

```json
{
  "type": "FeatureCollection",
  "version": "draft",
  "features": [],
  "attribution": "BAN",
  "licence": "ODbL 1.0",
  "query": "00000",
  "limit": 50
}
```

**Status**: `200 OK` but `features` array is empty
**Application Handling**: Treat as "postal code not found" error (FR-009)

---

### Response Fields

#### FeatureCollection

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `type` | string | Always "FeatureCollection" | Yes |
| `features` | array | Array of Feature objects | Yes |
| `query` | string | Original query (postal code) | Yes |
| `limit` | integer | Maximum results requested | Yes |

#### Feature Object

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `type` | string | Always "Feature" | Yes |
| `geometry` | object | Geographic coordinates | Yes |
| `properties` | object | City metadata | Yes |

#### Geometry Object

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `type` | string | Geometry type (always "Point") | Yes |
| `coordinates` | array | `[longitude, latitude]` (note: **longitude first**) | Yes |

**Important**: API returns coordinates as `[longitude, latitude]` but most mapping libraries expect `[latitude, longitude]`. Ensure proper ordering when constructing `LatLng` objects.

```dart
// Correct parsing
final coordinates = geometry['coordinates'] as List<dynamic>;
final longitude = (coordinates[0] as num).toDouble();
final latitude = (coordinates[1] as num).toDouble();

// Use with flutter_map (expects LatLng with latitude first)
final position = LatLng(latitude, longitude);
```

#### Properties Object (Relevant Fields)

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `city` | string | City/village name | Yes | Use for City.name |
| `postcode` | string | Postal code (5 digits) | Yes | Use for City.postalCode |
| `context` | string | Administrative hierarchy | No | Parse for department |
| `label` | string | Full formatted label | Yes | Backup if context missing |
| `score` | number | Relevance score (0-1) | Yes | Higher = more relevant |

**Context Field Format**: `"{departmentCode}, {departmentName}, {regionName}"`

Examples:
- `"01, Ain, Auvergne-Rhône-Alpes"` → Department: "Ain"
- `"75, Paris, Île-de-France"` → Department: "Paris"
- `"13, Bouches-du-Rhône, Provence-Alpes-Côte d'Azur"` → Department: "Bouches-du-Rhône"

**Parsing Logic**:
```dart
String? parseDepartment(String? context) {
  if (context == null || context.isEmpty) return null;
  final parts = context.split(',');
  if (parts.length >= 2) {
    return parts[1].trim();
  }
  return null;
}
```

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

**Application Handling**: Show "Service temporarily unavailable. Please try again later." (FR-009)

#### 500 Internal Server Error

```
HTTP/1.1 500 Internal Server Error
Content-Type: text/plain

Internal Server Error
```

**Application Handling**: Show "Service temporarily unavailable. Please try again later." (FR-009)

---

## Client Implementation Requirements

### 1. Parse Multiple Cities

```dart
Future<PostalCodeResult> fetchLocations(PostalCode postalCode) async {
  final uri = Uri.parse(
    'https://api-adresse.data.gouv.fr/search/'
    '?q=${postalCode.value}&type=municipality&limit=50'
  );

  final response = await client.get(uri).timeout(Duration(seconds: 10));

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;

    if (features.isEmpty) {
      throw PostalCodeNotFoundException(postalCode.value);
    }

    // Parse ALL features, not just first
    final cities = features
        .map((feature) => City.fromJson(
              feature as Map<String, dynamic>,
              postalCode.value,
            ))
        .toList();

    return PostalCodeResult(
      postalCode: postalCode.value,
      cities: cities,
    );
  }

  throw ServerException('HTTP ${response.statusCode}');
}
```

### 2. Handle Single vs Multiple Cities

```dart
final result = await geocodingService.fetchLocations(postalCode);

if (result.isSingleCity) {
  // Feature 001 behavior: Display map immediately
  _displayMap(result.singleCity);
} else if (result.requiresSelection) {
  // Feature 002 behavior: Show selection screen
  final selectedCity = await Navigator.push<City>(
    context,
    MaterialPageRoute(
      builder: (context) => CitySelectionScreen(cities: result.cities),
    ),
  );

  if (selectedCity != null) {
    _displayMap(selectedCity);
  }
}
```

### 3. Error Handling

```dart
try {
  final result = await geocodingService.fetchLocations(postalCode);
  // ... handle result
} on PostalCodeNotFoundException catch (e) {
  _showError('No cities found for this postal code. Please verify and try again.');
} on NetworkException catch (e) {
  _showError('Unable to retrieve city list. Please check your connection and try again.');
} on ServerException catch (e) {
  _showError('Service temporarily unavailable. Please try again later.');
}
```

---

## Testing Recommendations

### Test Postal Codes

| Postal Code | Expected Cities | Purpose |
|-------------|----------------|---------|
| `75001` | 1 (Paris 1er) | Test single city (bypass selection) |
| `01630` | 3 (Saint-Genis-Pouilly, Péron, Sergy) | Test multiple cities |
| `35530` | 2+ cities | Test disambiguation |
| `00000` | 0 (not found) | Test error handling |
| `99999` | 0 (not found) | Test error handling |

### Mock Responses

```dart
// Mock HTTP client for unit tests
final mockClient = MockClient((request) async {
  if (request.url.toString().contains('01630')) {
    return http.Response(multipleCitiesJson, 200);
  } else if (request.url.toString().contains('75001')) {
    return http.Response(singleCityJson, 200);
  } else {
    return http.Response(emptyResultJson, 200);
  }
});
```

---

## Migration from Feature 001

### Breaking Changes

1. **Service Method Signature**:
   - Old: `Future<CityLocation> fetchLocation(PostalCode postalCode)`
   - New: `Future<PostalCodeResult> fetchLocations(PostalCode postalCode)`

2. **API Request Parameter**:
   - Old: `limit=1`
   - New: `limit=50`

3. **Response Parsing**:
   - Old: Parse only `features[0]`
   - New: Parse all items in `features` array

### Backward Compatibility

Feature 002 maintains backward compatibility by:
- Detecting single-city results via `PostalCodeResult.isSingleCity`
- Displaying map immediately for single cities (same UX as feature 001)
- Only showing selection screen when multiple cities exist

---

## Attribution Requirements

Per OpenStreetMap and API Adresse terms:
- Display attribution: "© API Adresse" and "© OpenStreetMap contributors"
- Respect usage policy (fair use, no abuse)
- No caching beyond session duration (optional optimization)

```dart
// Example attribution widget
Text(
  '© API Adresse | © OpenStreetMap contributors',
  style: TextStyle(fontSize: 10, color: Colors.grey),
)
```
