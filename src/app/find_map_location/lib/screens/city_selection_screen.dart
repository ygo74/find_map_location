import 'package:flutter/material.dart';
import 'package:find_map_location/models/city.dart';

/// Screen for selecting a city from multiple matches for a postal code.
///
/// Displays cities in alphabetical order with department names for disambiguation.
/// User taps a city to select it, which pops the screen and returns the selected city.
class CitySelectionScreen extends StatelessWidget {
  final List<City> cities;

  const CitySelectionScreen({
    super.key,
    required this.cities,
  });

  @override
  Widget build(BuildContext context) {
    // Sort cities alphabetically by name
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
          return Semantics(
            label: city.department != null
                ? '${city.name}, ${city.department}'
                : city.name,
            button: true,
            child: ListTile(
              title: Text(
                city.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 2, // Allow wrapping for long city names
              ),
              subtitle: Text(
                city.department ?? '',
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                // Pop with selected city
                Navigator.pop(context, city);
              },
            ),
          );
        },
      ),
    );
  }
}
