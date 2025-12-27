import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:find_map_location/models/grid_configuration.dart';
import 'package:find_map_location/models/lat_lng_bounds.dart';
import 'package:find_map_location/widgets/grid_overlay_widget.dart';
import 'package:find_map_location/services/grid_calculation_service.dart';

/// Widget that displays an interactive map centered on a city location.
///
/// Uses flutter_map with OpenStreetMap tiles to display a map at zoom level 13
/// (neighborhood/arrondissement scale) centered on the provided coordinates.
/// Optionally displays a target address marker when targetLatitude and targetLongitude are provided.
/// Optionally displays a grid overlay when gridConfiguration is provided.
class MapDisplay extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String cityName;
  final MapController? mapController;
  final double? targetLatitude;
  final double? targetLongitude;
  final GridConfiguration? gridConfiguration;
  final GridBounds? cityBounds;

  const MapDisplay({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.mapController,
    this.targetLatitude,
    this.targetLongitude,
    this.gridConfiguration,
    this.cityBounds,
  });

  @override
  Widget build(BuildContext context) {
    final coordinates = LatLng(latitude, longitude);
    final controller = mapController ?? MapController();

    // Calculate city bounds for map constraints (default 5km radius)
    final bounds = cityBounds ?? GridCalculationService.calculateCityBounds(
      coordinates,
      5000.0, // 5km radius for typical city
    );

    // Convert to flutter_map LatLngBounds
    final mapBounds = LatLngBounds(
      LatLng(bounds.south, bounds.west),
      LatLng(bounds.north, bounds.east),
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: coordinates,
            initialZoom: 13.0, // Neighborhood/arrondissement scale
            minZoom: 12.0, // Prevent zooming out too far
            maxZoom: 18.0, // Allow detailed street view
            cameraConstraint: CameraConstraint.contain(
              bounds: mapBounds,
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.find_map_location',
            ),
            // Grid overlay (if configured)
            if (gridConfiguration != null)
              GridOverlayWidget(
                configuration: gridConfiguration!,
                mapController: controller,
              ),
            MarkerLayer(
              markers: [
                // Target address marker (red pin) - only if target coordinates provided
                if (targetLatitude != null && targetLongitude != null)
                  Marker(
                    point: LatLng(targetLatitude!, targetLongitude!),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {}, // Could add URL launcher if needed
                ),
                const TextSourceAttribution('API Adresse (data.gouv.fr)'),
              ],
            ),
          ],
        ),
        // Zoom controls
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  final currentZoom = controller.camera.zoom;
                  controller.move(
                    controller.camera.center,
                    currentZoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  final currentZoom = controller.camera.zoom;
                  controller.move(
                    controller.camera.center,
                    currentZoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
