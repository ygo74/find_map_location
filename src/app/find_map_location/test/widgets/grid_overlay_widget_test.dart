import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:find_map_location/widgets/grid_overlay_widget.dart';
import 'package:find_map_location/models/grid_configuration.dart';

void main() {
  group('GridOverlayWidget', () {
    late GridConfiguration configuration;
    late MapController mapController;

    setUp(() {
      configuration = GridConfiguration(cellSizeMeters: 500);
      mapController = MapController();
    });

    testWidgets('grid renders when origin set and visible', (tester) async {
      // Set origin to trigger grid display
      final origin = LatLng(48.8566, 2.3522); // Paris
      configuration.setOrigin(origin);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: origin,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                GridOverlayWidget(
                  mapController: mapController,
                  configuration: configuration,
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for initial build and map initialization
      await tester.pumpAndSettle();

      // Verify grid layers are present
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
    });

    testWidgets('grid hidden when origin null', (tester) async {
      // Configuration without origin
      expect(configuration.origin, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(48.8566, 2.3522),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                GridOverlayWidget(
                  mapController: mapController,
                  configuration: configuration,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify SizedBox.shrink() is rendered (no grid layers)
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(PolylineLayer), findsNothing);
      expect(find.byType(MarkerLayer), findsNothing);
    });

    testWidgets('grid hidden when isVisible false', (tester) async {
      // Set origin but hide grid
      final origin = LatLng(48.8566, 2.3522);
      configuration.setOrigin(origin);
      configuration.hide();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: origin,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                GridOverlayWidget(
                  mapController: mapController,
                  configuration: configuration,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify grid is hidden
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(PolylineLayer), findsNothing);
      expect(find.byType(MarkerLayer), findsNothing);
    });

    testWidgets('grid updates on configuration change', (tester) async {
      // Initial configuration
      final origin = LatLng(48.8566, 2.3522);
      configuration.setOrigin(origin);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: origin,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                GridOverlayWidget(
                  mapController: mapController,
                  configuration: configuration,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial grid renders
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);

      // Change cell size
      configuration.setCellSize(1000);

      // Wait for rebuild
      await tester.pumpAndSettle();

      // Grid should still be visible with new cell size
      expect(find.byType(PolylineLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(configuration.cellSizeMeters, equals(1000));
    });

    testWidgets('grid resets on configuration reset', (tester) async {
      // Set up grid
      final origin = LatLng(48.8566, 2.3522);
      configuration.setOrigin(origin);
      configuration.setCellSize(1000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: origin,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                GridOverlayWidget(
                  mapController: mapController,
                  configuration: configuration,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify grid renders
      expect(find.byType(PolylineLayer), findsOneWidget);

      // Reset configuration
      configuration.reset();

      await tester.pumpAndSettle();

      // Grid should be hidden after reset
      expect(configuration.origin, isNull);
      expect(configuration.isVisible, isFalse);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(PolylineLayer), findsNothing);
    });
  });
}
