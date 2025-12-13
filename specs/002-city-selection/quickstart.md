# Quickstart: City Selection for Duplicate Postal Codes

**Feature**: 002-city-selection
**Date**: 2025-12-13
**For**: Developers implementing the city selection feature

This guide provides step-by-step instructions to extend the postal code map viewer to handle multiple cities per postal code.

---

## Prerequisites

- Feature 001-postal-code-map completed and functional
- Flutter SDK 3.x installed
- Dart 3.10.4+ (bundled with Flutter)
- IDE: VS Code with Flutter extension or Android Studio
- Device/Emulator: Android API 21+ or iOS 12+

---

## Overview

This feature extends the existing postal code lookup to:
1. Detect when a postal code returns multiple cities
2. Display a selection screen if multiple cities exist
3. Center the map on the user-selected city

**No new dependencies required** - uses existing Flutter Material widgets.

---

## Implementation Steps

### Phase 1: Models (Test-First)

#### 1.1 Create City Model

**Test First** (`test/models/city_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/city.dart';

void main() {
  group('City', () {
    test('fromJson parses API response correctly', () {
      final json = {
        'geometry': {
          'coordinates': [6.0236, 46.2436]  // [lon, lat]
        },
        'properties': {
          'city': 'Saint-Genis-Pouilly',
          'postcode': '01630',
          'context': '01, Ain, Auvergne-Rhône-Alpes'
        }
      };

      final city = City.fromJson(json, '01630');

      expect(city.name, 'Saint-Genis-Pouilly');
      expect(city.latitude, 46.2436);
      expect(city.longitude, 6.0236);
      expect(city.department, 'Ain');
      expect(city.postalCode, '01630');
    });

    test('displayLabel includes department when available', () {
      final city = City(
        name: 'Péron',
        latitude: 46.1987,
        longitude: 6.0123,
        department: 'Ain',
        postalCode: '01630',
      );

      expect(city.displayLabel, 'Péron (Ain)');
    });

    test('displayLabel is name only when department missing', () {
      final city = City(
        name: 'Paris',
        latitude: 48.8629,
        longitude: 2.3364,
        department: null,
        postalCode: '75001',
      );

      expect(city.displayLabel, 'Paris');
    });

    test('fromJson handles missing context field', () {
      final json = {
        'geometry': {
          'coordinates': [2.3478, 48.8622]
        },
        'properties': {
          'city': 'Paris',
          'postcode': '75001'
        }
      };

      final city = City.fromJson(json, '75001');

      expect(city.department, null);
      expect(city.displayLabel, 'Paris');
    });
  });
}
```

**Run Test** (should fail):
```bash
flutter test test/models/city_test.dart
```

**Implement** (`lib/models/city.dart`):
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

**Run Test** (should pass):
```bash
flutter test test/models/city_test.dart
```

---

#### 1.2 Create PostalCodeResult Wrapper

**Test First** (`test/models/postal_code_result_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/postal_code_result.dart';
import 'package:find_map_location/models/city.dart';

void main() {
  group('PostalCodeResult', () {
    test('isSingleCity returns true for one city', () {
      final result = PostalCodeResult(
        postalCode: '75001',
        cities: [
          City(
            name: 'Paris',
            latitude: 48.8629,
            longitude: 2.3364,
            postalCode: '75001',
          ),
        ],
      );

      expect(result.isSingleCity, true);
      expect(result.requiresSelection, false);
    });

    test('requiresSelection returns true for multiple cities', () {
      final result = PostalCodeResult(
        postalCode: '01630',
        cities: [
          City(name: 'City1', latitude: 46.0, longitude: 6.0, postalCode: '01630'),
          City(name: 'City2', latitude: 46.1, longitude: 6.1, postalCode: '01630'),
        ],
      );

      expect(result.isSingleCity, false);
      expect(result.requiresSelection, true);
    });

    test('singleCity returns first city for single-city results', () {
      final city = City(
        name: 'Paris',
        latitude: 48.8629,
        longitude: 2.3364,
        postalCode: '75001',
      );
      final result = PostalCodeResult(
        postalCode: '75001',
        cities: [city],
      );

      expect(result.singleCity, city);
    });

    test('singleCity throws StateError for multi-city results', () {
      final result = PostalCodeResult(
        postalCode: '01630',
        cities: [
          City(name: 'City1', latitude: 46.0, longitude: 6.0, postalCode: '01630'),
          City(name: 'City2', latitude: 46.1, longitude: 6.1, postalCode: '01630'),
        ],
      );

      expect(() => result.singleCity, throwsStateError);
    });

    test('sortedCities returns alphabetically sorted list', () {
      final result = PostalCodeResult(
        postalCode: '01630',
        cities: [
          City(name: 'Sergy', latitude: 46.2, longitude: 6.0, postalCode: '01630'),
          City(name: 'Péron', latitude: 46.1, longitude: 6.0, postalCode: '01630'),
          City(name: 'Saint-Genis-Pouilly', latitude: 46.0, longitude: 6.0, postalCode: '01630'),
        ],
      );

      final sorted = result.sortedCities;
      expect(sorted[0].name, 'Péron');
      expect(sorted[1].name, 'Saint-Genis-Pouilly');
      expect(sorted[2].name, 'Sergy');
    });
  });
}
```

**Implement** (`lib/models/postal_code_result.dart`):
```dart
import 'city.dart';

class PostalCodeResult {
  final String postalCode;
  final List<City> cities;

  const PostalCodeResult({
    required this.postalCode,
    required this.cities,
  });

  bool get isSingleCity => cities.length == 1;
  bool get requiresSelection => cities.length > 1;

  City get singleCity {
    if (!isSingleCity) {
      throw StateError('Cannot get singleCity when multiple cities exist');
    }
    return cities.first;
  }

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

**Run Test** (should pass):
```bash
flutter test test/models/postal_code_result_test.dart
```

---

### Phase 2: Update GeocodingService (Test-First)

#### 2.1 Modify Service to Return Multiple Cities

**Update Test** (`test/services/geocoding_service_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/models/postal_code.dart';

@GenerateMocks([http.Client])
import 'geocoding_service_test.mocks.dart';

void main() {
  group('ApiAdresseGeocodingService', () {
    late MockClient mockClient;
    late ApiAdresseGeocodingService service;

    setUp(() {
      mockClient = MockClient();
      service = ApiAdresseGeocodingService(client: mockClient);
    });

    test('fetchLocations returns single city result', () async {
      final jsonResponse = '''
      {
        "features": [
          {
            "geometry": {"coordinates": [2.3478, 48.8622]},
            "properties": {
              "city": "Paris",
              "postcode": "75001",
              "context": "75, Paris, Île-de-France"
            }
          }
        ]
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await service.fetchLocations(PostalCode('75001'));

      expect(result.isSingleCity, true);
      expect(result.cities.length, 1);
      expect(result.cities.first.name, 'Paris');
    });

    test('fetchLocations returns multiple cities', () async {
      final jsonResponse = '''
      {
        "features": [
          {
            "geometry": {"coordinates": [6.0236, 46.2436]},
            "properties": {
              "city": "Saint-Genis-Pouilly",
              "postcode": "01630",
              "context": "01, Ain, Auvergne-Rhône-Alpes"
            }
          },
          {
            "geometry": {"coordinates": [6.0123, 46.1987]},
            "properties": {
              "city": "Péron",
              "postcode": "01630",
              "context": "01, Ain, Auvergne-Rhône-Alpes"
            }
          },
          {
            "geometry": {"coordinates": [6.0445, 46.2589]},
            "properties": {
              "city": "Sergy",
              "postcode": "01630",
              "context": "01, Ain, Auvergne-Rhône-Alpes"
            }
          }
        ]
      }
      ''';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await service.fetchLocations(PostalCode('01630'));

      expect(result.requiresSelection, true);
      expect(result.cities.length, 3);
      expect(result.cities[0].name, 'Saint-Genis-Pouilly');
      expect(result.cities[1].name, 'Péron');
      expect(result.cities[2].name, 'Sergy');
    });

    test('fetchLocations throws PostalCodeNotFoundException for empty results', () async {
      final jsonResponse = '{"features": []}';

      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(jsonResponse, 200));

      expect(
        () => service.fetchLocations(PostalCode('00000')),
        throwsA(isA<PostalCodeNotFoundException>()),
      );
    });
  });
}
```

**Update Implementation** (`lib/services/geocoding_service.dart`):
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:find_map_location/models/postal_code.dart';
import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/models/postal_code_result.dart';

abstract class GeocodingService {
  Future<PostalCodeResult> fetchLocations(PostalCode postalCode);
}

class ApiAdresseGeocodingService implements GeocodingService {
  static const String baseUrl = 'https://api-adresse.data.gouv.fr/search';
  static const Duration timeout = Duration(seconds: 10);

  final http.Client client;

  ApiAdresseGeocodingService({http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<PostalCodeResult> fetchLocations(PostalCode postalCode) async {
    // Changed limit from 1 to 50 to get all cities
    final uri = Uri.parse('$baseUrl/?q=${postalCode.value}&type=municipality&limit=50');

    try {
      final response = await client.get(uri).timeout(timeout);

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

// Exception classes (same as feature 001)
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

**Run Tests**:
```bash
flutter test test/services/geocoding_service_test.dart
```

---

### Phase 3: City Selection UI

#### 3.1 Create City Selection Screen

**Widget Test** (`test/screens/city_selection_screen_test.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/screens/city_selection_screen.dart';
import 'package:find_map_location/models/city.dart';

void main() {
  group('CitySelectionScreen', () {
    testWidgets('displays all cities in list', (tester) async {
      final cities = [
        City(name: 'City1', latitude: 46.0, longitude: 6.0, department: 'Dept1', postalCode: '01630'),
        City(name: 'City2', latitude: 46.1, longitude: 6.1, department: 'Dept2', postalCode: '01630'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CitySelectionScreen(cities: cities),
        ),
      );

      expect(find.text('City1'), findsOneWidget);
      expect(find.text('City2'), findsOneWidget);
    });

    testWidgets('tapping city pops with selected city', (tester) async {
      final cities = [
        City(name: 'TestCity', latitude: 46.0, longitude: 6.0, postalCode: '01630'),
      ];

      City? selectedCity;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selectedCity = await Navigator.push<City>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CitySelectionScreen(cities: cities),
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TestCity'));
      await tester.pumpAndSettle();

      expect(selectedCity?.name, 'TestCity');
    });
  });
}
```

**Implement** (`lib/screens/city_selection_screen.dart`):
```dart
import 'package:flutter/material.dart';
import 'package:find_map_location/models/city.dart';

class CitySelectionScreen extends StatelessWidget {
  final List<City> cities;

  const CitySelectionScreen({
    super.key,
    required this.cities,
  });

  @override
  Widget build(BuildContext context) {
    // Sort cities alphabetically for better UX
    final sortedCities = List<City>.from(cities)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select City'),
      ),
      body: ListView.builder(
        itemCount: sortedCities.length,
        itemBuilder: (context, index) {
          final city = sortedCities[index];
          return ListTile(
            title: Text(city.name),
            subtitle: city.department != null
                ? Text(city.department!)
                : null,
            onTap: () {
              Navigator.pop(context, city);
            },
          );
        },
      ),
    );
  }
}
```

**Run Widget Test**:
```bash
flutter test test/screens/city_selection_screen_test.dart
```

---

### Phase 4: Update Postal Code Screen

#### 4.1 Modify Existing Screen to Handle Multiple Cities

**Update** (`lib/screens/postal_code_screen.dart`):
```dart
// Add import
import 'package:find_map_location/screens/city_selection_screen.dart';

// In _PostalCodeScreenState class, update _submitPostalCode method:

Future<void> _submitPostalCode() async {
  // ... existing validation code ...

  try {
    setState(() {
      _mapState = MapState.loading;
      _errorMessage = null;
    });

    final result = await _geocodingService.fetchLocations(postalCode);

    if (result.isSingleCity) {
      // Single city: display map immediately (same as feature 001)
      setState(() {
        _selectedCity = result.singleCity;
        _mapState = MapState.success;
      });
    } else if (result.requiresSelection) {
      // Multiple cities: show selection screen
      final selectedCity = await Navigator.push<City>(
        context,
        MaterialPageRoute(
          builder: (context) => CitySelectionScreen(cities: result.cities),
        ),
      );

      if (selectedCity != null) {
        setState(() {
          _selectedCity = selectedCity;
          _mapState = MapState.success;
        });
      } else {
        // User pressed back without selecting
        setState(() {
          _mapState = MapState.idle;
        });
      }
    }
  } on PostalCodeNotFoundException catch (e) {
    setState(() {
      _mapState = MapState.error;
      _errorMessage = 'No cities found for this postal code. Please verify and try again.';
    });
  } on NetworkException catch (e) {
    setState(() {
      _mapState = MapState.error;
      _errorMessage = 'Unable to retrieve city list. Please check your connection and try again.';
    });
  } on ServerException catch (e) {
    setState(() {
      _mapState = MapState.error;
      _errorMessage = 'Service temporarily unavailable. Please try again later.';
    });
  }
}
```

---

## Testing

### Unit Tests

Run all unit tests:
```bash
flutter test
```

Expected: All tests pass with no errors.

### Integration Test

Create (`integration_test/multi_city_flow_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:find_map_location/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Multi-city postal code flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Enter multi-city postal code
    await tester.enterText(find.byType(TextField), '01630');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // Verify selection screen appears
    expect(find.text('Select City'), findsOneWidget);
    expect(find.text('Saint-Genis-Pouilly'), findsOneWidget);

    // Select a city
    await tester.tap(find.text('Saint-Genis-Pouilly'));
    await tester.pumpAndSettle();

    // Verify map displays
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
```

Run integration test:
```bash
flutter test integration_test/multi_city_flow_test.dart
```

---

## Verification

### Manual Testing Checklist

- [ ] Enter postal code "75001" → Map displays immediately (no selection)
- [ ] Enter postal code "01630" → Selection screen appears with 3 cities
- [ ] Select "Péron" → Map centers on Péron
- [ ] Press back on selection screen → Returns to postal code entry
- [ ] Enter postal code "00000" → Error message displays
- [ ] No internet → Appropriate error message displays

### Test Postal Codes

| Postal Code | Expected Behavior |
|-------------|-------------------|
| `75001` | Single city (Paris) - immediate map display |
| `01630` | 3 cities (selection required) |
| `35530` | Multiple cities (selection required) |
| `00000` | Not found error |

---

## Running the App

```bash
cd src/app/find_map_location

# Run on device/emulator
flutter run

# Or specific device
flutter devices
flutter run -d <device-id>
```

---

## Troubleshooting

### Issue: "City model not found"
**Solution**: Ensure you've created `lib/models/city.dart` and `lib/models/postal_code_result.dart`

### Issue: Tests fail with "MockClient not found"
**Solution**: Run `flutter pub run build_runner build` to generate mocks

### Issue: Selection screen doesn't show cities
**Solution**: Verify API returns limit=50 and all features are parsed

### Issue: Map doesn't update after selection
**Solution**: Check that `setState` is called with selected city

---

## Next Steps

After completing this feature:
1. Run `flutter analyze` to ensure no linting issues
2. Run full test suite: `flutter test`
3. Run integration tests
4. Test on both iOS and Android devices
5. Proceed to `/speckit.tasks` to break down implementation into granular tasks
