# Quickstart: Postal Code Map Viewer

**Feature**: 001-postal-code-map
**Date**: 2025-12-13
**For**: Developers implementing the postal code map feature

This guide provides step-by-step instructions to implement, test, and run the postal code map viewer feature.

---

## Prerequisites

- Flutter SDK 3.x installed (`flutter --version` to verify)
- Dart 3.10.4+ (bundled with Flutter)
- IDE: VS Code with Flutter extension or Android Studio
- Device/Emulator: Android API 21+ or iOS 12+

---

## Setup Instructions

### 1. Add Dependencies

Update `src/app/find_map_location/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^7.0.0      # OpenStreetMap integration
  latlong2: ^0.9.0         # Geographic coordinates
  http: ^1.2.0             # HTTP client

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  integration_test:
    sdk: flutter
```

Run:
```bash
cd src/app/find_map_location
flutter pub get
```

### 2. Verify Linting

Ensure `analysis_options.yaml` includes:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    avoid_print: true
```

Run analysis:
```bash
flutter analyze
```

Expected output: `No issues found!`

---

## Implementation Steps

### Phase 1: Models (Test-First)

#### 1.1 Create PostalCode Value Object

**Test First** (`test/models/postal_code_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/postal_code.dart';

void main() {
  group('PostalCode', () {
    test('accepts valid 5-digit postal code', () {
      final postalCode = PostalCode('75001');
      expect(postalCode.isValid, true);
    });

    test('rejects postal code with letters', () {
      final postalCode = PostalCode('7500A');
      expect(postalCode.isValid, false);
    });

    test('rejects too short postal code', () {
      final postalCode = PostalCode('123');
      expect(postalCode.isValid, false);
    });

    test('recognizes empty postal code', () {
      final postalCode = PostalCode('');
      expect(postalCode.isEmpty, true);
    });
  });
}
```

**Run Test** (should fail):
```bash
flutter test test/models/postal_code_test.dart
```

**Implement** (`lib/models/postal_code.dart`):
```dart
class PostalCode {
  static final RegExp _validationPattern = RegExp(r'^[0-9]{5}$');

  final String value;

  const PostalCode(this.value);

  bool get isValid => _validationPattern.hasMatch(value);
  bool get isEmpty => value.isEmpty;

  @override
  String toString() => value;
}
```

**Run Test** (should pass):
```bash
flutter test test/models/postal_code_test.dart
```

#### 1.2 Create CityLocation Entity

**Test First** (`test/models/city_location_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/city_location.dart';

void main() {
  test('fromJson parses API response correctly', () {
    final json = {
      'geometry': {
        'coordinates': [2.347870, 48.862270]  // [lon, lat]
      },
      'properties': {
        'city': 'Paris',
        'postcode': '75001',
        'label': 'Paris 1er Arrondissement'
      }
    };

    final location = CityLocation.fromJson(json);

    expect(location.latitude, 48.862270);
    expect(location.longitude, 2.347870);
    expect(location.cityName, 'Paris');
    expect(location.postalCode, '75001');
  });
}
```

**Implement** (`lib/models/city_location.dart`):
```dart
import 'package:latlong2/latlong.dart';

class CityLocation {
  final double latitude;
  final double longitude;
  final String cityName;
  final String postalCode;
  final String? label;

  const CityLocation({
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
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
      cityName: properties['city'] as String,
      postalCode: properties['postcode'] as String,
      label: properties['label'] as String?,
    );
  }
}
```

### Phase 2: Services (Test-First with Mocks)

**Create mock HTTP client** (`test/services/geocoding_service_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/models/postal_code.dart';

void main() {
  test('fetchLocation returns CityLocation on success', () async {
    final mockClient = MockClient((request) async {
      return http.Response('''
        {
          "features": [{
            "geometry": {"coordinates": [2.347870, 48.862270]},
            "properties": {"city": "Paris", "postcode": "75001"}
          }]
        }
      ''', 200);
    });

    final service = ApiAdresseGeocodingService(client: mockClient);
    final location = await service.fetchLocation(const PostalCode('75001'));

    expect(location.cityName, 'Paris');
  });

  test('throws PostalCodeNotFoundException when features empty', () async {
    final mockClient = MockClient((request) async {
      return http.Response('{"features": []}', 200);
    });

    final service = ApiAdresseGeocodingService(client: mockClient);

    expect(
      () => service.fetchLocation(const PostalCode('00000')),
      throwsA(isA<PostalCodeNotFoundException>()),
    );
  });
}
```

**Implement service** (`lib/services/geocoding_service.dart`):
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:find_map_location/models/postal_code.dart';
import 'package:find_map_location/models/city_location.dart';

abstract class GeocodingService {
  Future<CityLocation> fetchLocation(PostalCode postalCode);
}

class ApiAdresseGeocodingService implements GeocodingService {
  static const String baseUrl = 'https://api-adresse.data.gouv.fr/search';
  final http.Client client;

  ApiAdresseGeocodingService({http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<CityLocation> fetchLocation(PostalCode postalCode) async {
    final uri = Uri.parse('$baseUrl/?q=${postalCode.value}&type=municipality&limit=1');

    try {
      final response = await client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;

        if (features.isEmpty) {
          throw PostalCodeNotFoundException(postalCode.value);
        }

        return CityLocation.fromJson(features[0]);
      } else {
        throw ServerException('HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw ServerException('Request timeout');
    }
  }
}

class PostalCodeNotFoundException implements Exception {
  final String postalCode;
  PostalCodeNotFoundException(this.postalCode);
}

class NetworkException implements Exception {}
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}
```

### Phase 3: UI Widgets

**Create home screen** (`lib/screens/home_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:find_map_location/models/postal_code.dart';
import 'package:find_map_location/models/city_location.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/widgets/postal_code_input.dart';
import 'package:find_map_location/widgets/map_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _geocodingService = ApiAdresseGeocodingService();
  final _postalCodeController = TextEditingController();

  bool _isLoading = false;
  CityLocation? _currentLocation;
  String? _errorMessage;

  @override
  void dispose() {
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final postalCode = PostalCode(_postalCodeController.text.trim());

    if (postalCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a postal code';
        _currentLocation = null;
      });
      return;
    }

    if (!postalCode.isValid) {
      setState(() {
        _errorMessage = 'Please enter a valid 5-digit French postal code';
        _currentLocation = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = await _geocodingService.fetchLocation(postalCode);
      setState(() {
        _isLoading = false;
        _currentLocation = location;
      });
    } on PostalCodeNotFoundException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No city found for postal code ${e.postalCode}. Please verify and try again.';
      });
    } on NetworkException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No internet connection. Please check your network and try again.';
      });
    } on ServerException {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Service temporarily unavailable. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Map Location')),
      body: Column(
        children: [
          PostalCodeInput(
            controller: _postalCodeController,
            onSubmit: _handleSubmit,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
          ),
          if (_currentLocation != null)
            Expanded(
              child: MapDisplay(location: _currentLocation!),
            ),
        ],
      ),
    );
  }
}
```

**Create input widget** (`lib/widgets/postal_code_input.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostalCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const PostalCodeInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'French Postal Code',
              hintText: '75001',
              errorText: errorMessage,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Find Location'),
          ),
        ],
      ),
    );
  }
}
```

**Create map widget** (`lib/widgets/map_display.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:find_map_location/models/city_location.dart';

class MapDisplay extends StatelessWidget {
  final CityLocation location;

  const MapDisplay({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: location.coordinates,
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.find_map_location',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: location.coordinates,
              builder: (ctx) => const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => {}, // Add URL launcher if needed
            ),
            const TextSourceAttribution('API Adresse (data.gouv.fr)'),
          ],
        ),
      ],
    );
  }
}
```

**Update main.dart**:
```dart
import 'package:flutter/material.dart';
import 'package:find_map_location/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find Map Location',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

---

## Running the Application

### Run on Emulator/Device

```bash
cd src/app/find_map_location
flutter run
```

**Test manually**:
1. Enter `75001` → Should show Paris 1st arrondissement map
2. Enter `69001` → Should show Lyon 1st arrondissement map
3. Enter `123` → Should show format error
4. Enter empty → Should show "Please enter a postal code"
5. Turn off network → Should show network error

### Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/models/postal_code_test.dart

# With coverage
flutter test --coverage
```

### Run Integration Tests

```bash
flutter test integration_test/app_test.dart
```

---

## Verification Checklist

✅ **Code Quality**:
- [ ] `flutter analyze` returns no issues
- [ ] All tests pass (`flutter test`)
- [ ] Test coverage ≥80% logic, ≥60% UI

✅ **Functional Requirements**:
- [ ] FR-001: Input accepts 5 digits
- [ ] FR-002: Validation on submission only
- [ ] FR-003: Format error messages display
- [ ] FR-004: Geocoding retrieves coordinates
- [ ] FR-005: Map displays centered on location
- [ ] FR-006: Not found error displays
- [ ] FR-007: Loading indicator shows during fetch
- [ ] FR-010: Empty field error displays
- [ ] FR-011: Network error message displays
- [ ] FR-012: Map supports zoom and pan

✅ **Performance**:
- [ ] Format validation <500ms
- [ ] Map displays within 5 seconds
- [ ] 60fps during map interaction
- [ ] Cold start <3 seconds

---

## Troubleshooting

**Issue**: Map tiles not loading
**Solution**: Check internet connectivity; ensure `userAgentPackageName` is set

**Issue**: Coordinates reversed on map
**Solution**: API returns `[lon, lat]` but LatLng expects `(lat, lon)` - verify order in `CityLocation.fromJson`

**Issue**: Tests fail with HTTP errors
**Solution**: Ensure using mock HTTP client in tests, not real network calls

---

## Next Steps

After successful implementation:
1. Review tasks.md for complete implementation checklist (53 tasks organized by user story)
2. Begin implementation following TDD cycle per tasks.md execution order
3. Submit PRs following constitution quality gates (Principles I-IV)
4. Refer to tasks.md for parallel execution opportunities

**Estimated Implementation Time**: 8-12 hours for experienced Flutter developer
