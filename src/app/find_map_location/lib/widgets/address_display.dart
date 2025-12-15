import 'package:flutter/material.dart';
import 'package:find_map_location/models/random_address.dart';

/// Displays the target address prominently for the user to find.
///
/// Shows the address in a Card with a header label. The address is displayed
/// as text only and is NOT marked on the map (core game mechanic).
/// Optionally includes a refresh button to generate a new address.
class AddressDisplay extends StatelessWidget {
  /// The random address to display
  final RandomAddress address;

  /// Callback when refresh button is pressed (optional)
  final VoidCallback? onRefresh;

  /// Creates an AddressDisplay widget.
  ///
  /// Example:
  /// ```dart
  /// AddressDisplay(
  ///   address: RandomAddress(
  ///     streetNumber: '42',
  ///     streetName: 'Rue de Rivoli',
  ///     cityName: 'Paris',
  ///     ...
  ///   ),
  ///   onRefresh: () => generateNewAddress(),
  /// )
  /// ```
  const AddressDisplay({
    super.key,
    required this.address,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
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
            if (onRefresh != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Generate new address',
                iconSize: 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
