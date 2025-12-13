import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/screens/city_selection_screen.dart';

void main() {
  group('CitySelectionScreen', () {
    final testCities = [
      City(
        name: 'Saint-Genis-Pouilly',
        latitude: 46.2436,
        longitude: 6.0236,
        department: 'Ain',
        postalCode: '01630',
      ),
      City(
        name: 'Péron',
        latitude: 46.1987,
        longitude: 6.0123,
        department: 'Ain',
        postalCode: '01630',
      ),
      City(
        name: 'Sergy',
        latitude: 46.2589,
        longitude: 6.0445,
        department: 'Ain',
        postalCode: '01630',
      ),
    ];

    testWidgets('displays all cities in the list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitySelectionScreen(cities: testCities),
        ),
      );

      // Verify all city names are displayed
      expect(find.text('Saint-Genis-Pouilly'), findsOneWidget);
      expect(find.text('Péron'), findsOneWidget);
      expect(find.text('Sergy'), findsOneWidget);
    });

    testWidgets('returns selected city when tapped', (WidgetTester tester) async {
      City? selectedCity;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    selectedCity = await Navigator.push<City>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CitySelectionScreen(cities: testCities),
                      ),
                    );
                  },
                  child: const Text('Navigate'),
                ),
              );
            },
          ),
        ),
      );

      // Navigate to city selection screen
      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Tap on "Péron"
      await tester.tap(find.text('Péron'));
      await tester.pumpAndSettle();

      // Verify the selected city was returned
      expect(selectedCity, isNotNull);
      expect(selectedCity!.name, 'Péron');
    });

    testWidgets('displays cities with two-line ListTile format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitySelectionScreen(cities: testCities),
        ),
      );

      // Verify ListTile structure with title and subtitle
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles.length, 3);

      // Check first ListTile has title and subtitle
      final firstTile = listTiles.first;
      expect(firstTile.title, isA<Text>());
      expect(firstTile.subtitle, isA<Text>());

      // Verify department is shown in subtitle
      expect(find.text('Ain'), findsNWidgets(3)); // All cities have department "Ain"
    });

    testWidgets('displays cities sorted alphabetically', (WidgetTester tester) async {
      // Pass cities in unsorted order
      final unsortedCities = [
        testCities[2], // Sergy
        testCities[0], // Saint-Genis-Pouilly
        testCities[1], // Péron
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CitySelectionScreen(cities: unsortedCities),
        ),
      );

      // Find all ListTile widgets
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles.length, 3);

      // Extract titles and verify alphabetical order
      final titles = listTiles.map((tile) {
        final titleWidget = tile.title as Text;
        return titleWidget.data;
      }).toList();

      expect(titles[0], 'Péron');
      expect(titles[1], 'Saint-Genis-Pouilly');
      expect(titles[2], 'Sergy');
    });

    testWidgets('displays AppBar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitySelectionScreen(cities: testCities),
        ),
      );

      // Verify AppBar exists with title
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Select City'), findsOneWidget);
    });

    testWidgets('handles empty city list gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CitySelectionScreen(cities: []),
        ),
      );

      // Should display screen without errors
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('displays department in subtitle when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitySelectionScreen(cities: testCities),
        ),
      );

      // All cities have department, verify subtitles exist
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      for (final tile in listTiles) {
        expect(tile.subtitle, isA<Text>());
        final subtitleText = tile.subtitle as Text;
        expect(subtitleText.data, 'Ain');
      }
    });

    testWidgets('handles city without department', (WidgetTester tester) async {
      final citiesWithNoDept = [
        City(
          name: 'Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          department: null,
          postalCode: '75001',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CitySelectionScreen(cities: citiesWithNoDept),
        ),
      );

      // Verify city is displayed
      expect(find.text('Paris'), findsOneWidget);

      // Subtitle should still exist but might be empty
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isA<Text>());
    });
  });
}
