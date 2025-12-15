# Quickstart: Random Address Selection Implementation

**Date**: 2025-12-14
**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

This quickstart guide walks through implementing the random address selection feature for the location game in the existing Flutter application.

**Estimated Time**: 6-8 hours (including tests)
**Prerequisites**: Flutter/Dart environment set up, access to existing codebase
**Test-First**: Yes - write tests before implementation

## Development Workflow

### Phase 1: Setup & Dependencies (30 minutes)

1. **Update dependencies** in `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_map: ^8.2.2
  latlong2: ^0.9.0
  http: ^1.2.0
  geolocator: ^11.0.0           # NEW
  permission_handler: ^11.0.0   # NEW

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mockito: ^5.4.0               # For HTTP mocking
  build_runner: ^2.4.0          # For mockito code generation
```

2. **Install dependencies**:
```bash
cd src/app/find_map_location
flutter pub get
```

3. **Configure permissions**:

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to help you find addresses on the map</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### Phase 2: Data Models (1 hour)

**Test-First**: Write model tests first

#### 2.1: Create `test/models/random_address_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/random_address.dart';
import 'package:find_map_location/models/city.dart';

void main() {
  group('RandomAddress', () {
    test('toDisplayString formats address correctly', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      expect(address.toDisplayString(), '42 Rue de Rivoli, Paris');
    });

    test('toUniqueKey generates consistent key', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      expect(address.toUniqueKey(), 'Paris|Rue de Rivoli|42');
    });

    test('isInCity validates city match', () {
      final address = RandomAddress(
        streetNumber: '42',
        streetName: 'Rue de Rivoli',
        cityName: 'Paris',
        postcode: '75001',
        latitude: 48.8606,
        longitude: 2.3376,
        generatedAt: DateTime.now().toUtc(),
      );

      final parisCity = City(name: 'Paris', postcode: '75001', lat: 48.86, lon: 2.34, department: 'Paris');
      final lyonCity = City(name: 'Lyon', postcode: '69000', lat: 45.75, lon: 4.85, department: 'Rhône');

      expect(address.isInCity(parisCity), isTrue);
      expect(address.isInCity(lyonCity), isFalse);
    });
  });
}
```

#### 2.2: Implement `lib/models/random_address.dart`

Run tests: `flutter test test/models/random_address_test.dart` (should fail)

```dart
import 'package:find_map_location/models/city.dart';

/// Represents a random address within a city for the location game.
/// The address coordinates are used for validation but NOT displayed on the map.
class RandomAddress {
  final String streetNumber;
  final String streetName;
  final String cityName;
  final String postcode;
  final double latitude;
  final double longitude;
  final DateTime generatedAt;

  const RandomAddress({
    required this.streetNumber,
    required this.streetName,
    required this.cityName,
    required this.postcode,
    required this.latitude,
    required this.longitude,
    required this.generatedAt,
  });

  /// Formats address for display: "42 Rue de Rivoli, Paris"
  String toDisplayString() {
    return '$streetNumber $streetName, $cityName';
  }

  /// Generates unique key for deduplication: "Paris|Rue de Rivoli|42"
  String toUniqueKey() {
    return '$cityName|$streetName|$streetNumber';
  }

  /// Validates that address belongs to the given city
  bool isInCity(City city) {
    return cityName.toLowerCase() == city.name.toLowerCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RandomAddress &&
          streetNumber == other.streetNumber &&
          streetName == other.streetName &&
          cityName == other.cityName;

  @override
  int get hashCode => Object.hash(streetNumber, streetName, cityName);
}
```

Run tests again: `flutter test test/models/random_address_test.dart` (should pass)

#### 2.3: Create remaining models

Follow same test-first pattern for:
- `address_selection_result.dart` / `address_selection_result_test.dart`
- `game_session_state.dart` / `game_session_state_test.dart`
- `city_bounds.dart` / `city_bounds_test.dart`

Refer to [data-model.md](./data-model.md) for complete specifications.

### Phase 3: Services (2-3 hours)

#### 3.1: Extend GeocodingService with reverse geocoding

**Test**: `test/services/geocoding_service_test.dart`

Add test cases:
```dart
group('reverseGeocode', () {
  test('returns RandomAddress for valid housenumber', () async {
    final mockClient = MockClient((request) async {
      return http.Response(mockSuccessResponse, 200);
    });

    final service = ApiAdresseGeocodingService(client: mockClient);
    final address = await service.reverseGeocode(48.8606, 2.3376);

    expect(address, isNotNull);
    expect(address!.streetNumber, '42');
    expect(address.cityName, 'Paris');
  });

  test('returns null for empty features', () async {
    // ... test implementation
  });
});
```

**Implementation**: Modify `lib/services/geocoding_service.dart`

Add method:
```dart
Future<RandomAddress?> reverseGeocode(double lat, double lon) async {
  final uri = Uri.parse('$baseUrl/reverse/?lat=$lat&lon=$lon&type=housenumber');

  try {
    final response = await client.get(uri).timeout(timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = json['features'] as List<dynamic>;

      if (features.isEmpty) return null;

      final properties = features[0]['properties'] as Map<String, dynamic>;

      // Validate housenumber type
      if (properties['type'] != 'housenumber') return null;

      return RandomAddress(
        streetNumber: properties['housenumber'] as String,
        streetName: properties['street'] as String,
        cityName: properties['city'] as String,
        postcode: properties['postcode'] as String,
        latitude: features[0]['geometry']['coordinates'][1] as double,
        longitude: features[0]['geometry']['coordinates'][0] as double,
        generatedAt: DateTime.now().toUtc(),
      );
    }

    throw ServerException('HTTP ${response.statusCode}');
  } catch (e) {
    rethrow;
  }
}
```

#### 3.2: Create RandomAddressService

**Test**: `test/services/random_address_service_test.dart`
**Implementation**: `lib/services/random_address_service.dart`

See [contracts/geocoding-api.md](./contracts/geocoding-api.md) for retry logic.

#### 3.3: Create LocationService

**Test**: `test/services/location_service_test.dart`
**Implementation**: `lib/services/location_service.dart`

```dart
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service for obtaining user location (transient use only - no storage)
class LocationService {
  /// Gets current user location with high accuracy for street-level zoom.
  /// Returns null if location unavailable or permission denied.
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return null;
        }
      }

      // Get location with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null; // Location unavailable
    }
  }
}
```

### Phase 4: UI Widgets (2 hours)

#### 4.1: AddressDisplay Widget

**Test**: `test/widgets/address_display_test.dart`

```dart
group('AddressDisplay', () {
  testWidgets('displays address correctly', (tester) async {
    final address = RandomAddress(
      streetNumber: '42',
      streetName: 'Rue de Rivoli',
      cityName: 'Paris',
      postcode: '75001',
      latitude: 48.8606,
      longitude: 2.3376,
      generatedAt: DateTime.now().toUtc(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AddressDisplay(address: address)),
    ));

    expect(find.text('42 Rue de Rivoli, Paris'), findsOneWidget);
  });

  testWidgets('handles special characters', (tester) async {
    final address = RandomAddress(
      streetNumber: '5',
      streetName: "Rue de l'Église",
      cityName: 'Paris',
      postcode: '75001',
      latitude: 48.86,
      longitude: 2.34,
      generatedAt: DateTime.now().toUtc(),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AddressDisplay(address: address)),
    ));

    expect(find.text("5 Rue de l'Église, Paris"), findsOneWidget);
  });
});
```

**Implementation**: `lib/widgets/address_display.dart`

```dart
import 'package:flutter/material.dart';
import 'package:find_map_location/models/random_address.dart';

/// Displays the target address prominently for the user to find
class AddressDisplay extends StatelessWidget {
  final RandomAddress address;

  const AddressDisplay({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find this address:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              address.toDisplayString(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 4.2: StartSearchButton Widget

**Test**: `test/widgets/start_search_button_test.dart`
**Implementation**: `lib/widgets/start_search_button.dart`

Follow same test-first pattern. Button should:
- Call onPressed callback
- Disable itself after press (setState with bool flag)
- Show grayed-out appearance when disabled

### Phase 5: Integration (1-2 hours)

#### 5.1: Update HomeScreen

Modify `lib/screens/home_screen.dart` to:
1. Add GameSessionState management
2. Generate random address after city selection
3. Display AddressDisplay widget
4. Add StartSearchButton
5. Handle location zoom on button press

```dart
class _HomeScreenState extends State<HomeScreen> {
  final _geocodingService = ApiAdresseGeocodingService();
  final _randomAddressService = RandomAddressService();
  final _locationService = LocationService();

  GameSessionState _gameState = const GameSessionState();

  Future<void> _handleCitySelected(City city) async {
    setState(() {
      _gameState = _gameState.withNewCity(city);
    });

    // Generate random address
    try {
      final result = await _randomAddressService.generateAddress(city, _gameState);

      if (result.isSuccess) {
        setState(() {
          _gameState = _gameState
              .withAddress(result.address!)
              .addUsedAddress(result.address!.toUniqueKey());
        });
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!)),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _handleStartSearch() async {
    setState(() {
      _gameState = _gameState.withSearchStarted();
    });

    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      // Zoom map to location at street-level (zoom 17)
      _mapController.move(location, 17);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Existing postal code input
          // ...

          // NEW: Address display
          if (_gameState.currentAddress != null)
            AddressDisplay(address: _gameState.currentAddress!),

          // NEW: Start Search button
          if (_gameState.currentAddress != null && !_gameState.hasStartedSearch)
            StartSearchButton(onPressed: _handleStartSearch),

          // Existing map
          // ...
        ],
      ),
    );
  }
}
```

### Phase 6: Integration Tests (1 hour)

Create `integration_test/random_address_flow_test.dart`:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Random Address Flow', () {
    testWidgets('complete game flow', (tester) async {
      await tester.pumpWidget(const MyApp());

      // Enter postal code
      await tester.enterText(find.byType(TextField), '75001');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // Verify address displayed
      expect(find.byType(AddressDisplay), findsOneWidget);

      // Tap Start Search
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Search'));
      await tester.pumpAndSettle();

      // Verify button disabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Start Search'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
```

### Phase 7: Verification (30 minutes)

1. **Run all tests**:
```bash
flutter test
flutter test integration_test
```

2. **Static analysis**:
```bash
flutter analyze
```

3. **Test on device**:
```bash
flutter run
```

4. **Verify requirements**:
- ✅ FR-001: Address generated after city selection
- ✅ FR-002: Address displayed as text
- ✅ FR-003: Address NOT marked on map
- ✅ FR-014: Map zooms to user location
- ✅ FR-017: Button becomes disabled
- ✅ FR-018: No location storage

## Common Issues & Solutions

### Issue: Location permission always denied
**Solution**: Verify Info.plist (iOS) and AndroidManifest.xml (Android) have correct permission declarations

### Issue: Reverse geocoding returns null frequently
**Solution**: Increase retry count or adjust bounding box delta (currently 0.05°)

### Issue: Address display overflows on small screens
**Solution**: Wrap Text in Flexible or Expanded widget

### Issue: Tests fail with "Bad state: Uninitialized binding"
**Solution**: Add `TestWidgetsFlutterBinding.ensureInitialized();` at start of test

## Performance Checklist

- [ ] Address generation completes in <2s (SC-001)
- [ ] Location zoom completes in <1s (SC-007)
- [ ] No frame drops during UI transitions
- [ ] Memory usage stable (check DevTools)
- [ ] No memory leaks (dispose controllers)

## Next Steps

After completing this quickstart:
1. Review code with team
2. Perform manual testing on physical devices
3. Run performance profiling in DevTools
4. Create PR for review
5. Update documentation if needed

## References

- [spec.md](./spec.md) - Feature specification
- [data-model.md](./data-model.md) - Entity definitions
- [contracts/geocoding-api.md](./contracts/geocoding-api.md) - API contract
- [research.md](./research.md) - Technical decisions
