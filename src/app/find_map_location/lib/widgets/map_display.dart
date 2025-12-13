import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:find_map_location/models/city_location.dart';

/// Widget that displays an interactive map centered on a city location.
///
/// Uses flutter_map with OpenStreetMap tiles to display a map at zoom level 13
/// (neighborhood/arrondissement scale) centered on the provided [location].
class MapDisplay extends StatelessWidget {
  final CityLocation location;

  const MapDisplay({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: location.coordinates,
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
            Marker(
              point: location.coordinates,
              width: 40,
              height: 40,
              child: const Icon(
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
              onTap: () {}, // Could add URL launcher if needed
            ),
            const TextSourceAttribution('API Adresse (data.gouv.fr)'),
          ],
        ),
      ],
    );
  }
}
