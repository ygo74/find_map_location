import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget that displays an interactive map centered on a city location.
///
/// Uses flutter_map with OpenStreetMap tiles to display a map at zoom level 13
/// (neighborhood/arrondissement scale) centered on the provided coordinates.
/// Optionally displays a target address marker when targetLatitude and targetLongitude are provided.
class MapDisplay extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String cityName;
  final MapController? mapController;
  final double? targetLatitude;
  final double? targetLongitude;

  const MapDisplay({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
    this.mapController,
    this.targetLatitude,
    this.targetLongitude,
  });

  @override
  Widget build(BuildContext context) {
    final coordinates = LatLng(latitude, longitude);
    final controller = mapController ?? MapController();

    return Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: coordinates,
            initialZoom: 13.0, // Neighborhood/arrondissement scale
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.find_map_location',
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
