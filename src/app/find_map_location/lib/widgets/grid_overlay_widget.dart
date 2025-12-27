import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../models/grid_configuration.dart';
import '../models/grid_cell.dart';
import '../models/lat_lng_bounds.dart';
import '../services/grid_calculation_service.dart';

/// Widget that renders a grid overlay on a flutter_map instance.
///
/// Displays grid lines and alphanumeric cell labels that update dynamically
/// as the user pans or zooms the map.
///
/// ## Performance Characteristics
///
/// - Uses 300ms debounce timer to prevent excessive regeneration during panning
/// - Limits rendering to maximum 100 cells (configurable in GridCalculationService)
/// - Adds +1 cell buffer on each viewport edge for smooth panning
/// - Automatically hides when [GridConfiguration.isVisible] is false or origin is null
///
/// ## Usage
///
/// ```dart
/// GridOverlayWidget(
///   configuration: gridConfiguration, // ChangeNotifier
///   mapController: mapController,     // flutter_map MapController
/// )
/// ```
///
/// The widget automatically rebuilds when:
/// - GridConfiguration changes (cell size, origin, visibility)
/// - Map viewport changes (pan, zoom)
/// - Map events occur (move, move end)
class GridOverlayWidget extends StatefulWidget {
  /// Configuration for the grid (origin, cell size, visibility)
  final GridConfiguration configuration;

  /// MapController for accessing viewport bounds and map events
  final MapController mapController;

  const GridOverlayWidget({
    super.key,
    required this.configuration,
    required this.mapController,
  });

  @override
  State<GridOverlayWidget> createState() => _GridOverlayWidgetState();
}

class _GridOverlayWidgetState extends State<GridOverlayWidget> {
  /// Currently visible grid cells
  List<GridCell> _visibleCells = [];

  /// Debounce timer for map events
  Timer? _debounceTimer;

  /// Stream subscription for map events
  StreamSubscription<MapEvent>? _mapEventSubscription;

  @override
  void initState() {
    super.initState();
    widget.configuration.addListener(_onConfigChanged);
    _mapEventSubscription =
        widget.mapController.mapEventStream.listen(_onMapEvent);
    _generateVisibleCells();
  }

  @override
  void dispose() {
    widget.configuration.removeListener(_onConfigChanged);
    _mapEventSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Called when grid configuration changes
  void _onConfigChanged() {
    setState(() {
      _generateVisibleCells();
    });
  }

  /// Called when map events occur (pan, zoom, etc.)
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove || event is MapEventMoveEnd) {
      // Debounce to prevent excessive regeneration during rapid panning
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _generateVisibleCells();
          });
        }
      });
    }
  }

  /// Generates the list of visible cells based on current map viewport
  void _generateVisibleCells() {
    if (!widget.configuration.isVisible ||
        widget.configuration.origin == null) {
      _visibleCells = [];
      return;
    }

    final camera = widget.mapController.camera;
    // Convert flutter_map's LatLngBounds to our GridBounds
    final bounds = GridBounds(
      LatLng(camera.visibleBounds.north, camera.visibleBounds.west),
      LatLng(camera.visibleBounds.south, camera.visibleBounds.east),
    );

    _visibleCells = GridCalculationService.generateVisibleCells(
      bounds,
      widget.configuration.origin!,
      widget.configuration.cellSizeMeters.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.configuration.isVisible || _visibleCells.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        _buildGridLines(),
        _buildGridLabels(),
      ],
    );
  }

  /// Builds the grid lines layer (vertical and horizontal lines)
  Widget _buildGridLines() {
    final theme = Theme.of(context);
    final List<Polyline> polylines = [];

    // Generate vertical and horizontal lines for each cell
    for (final cell in _visibleCells) {
      final bounds = cell.bounds;

      // Vertical line (west edge of cell)
      polylines.add(Polyline(
        points: [
          LatLng(bounds.north, bounds.west),
          LatLng(bounds.south, bounds.west),
        ],
        strokeWidth: 1.5,
        color: theme.dividerColor.withValues(alpha: 0.6),
      ));

      // Horizontal line (north edge of cell)
      polylines.add(Polyline(
        points: [
          LatLng(bounds.north, bounds.west),
          LatLng(bounds.north, bounds.east),
        ],
        strokeWidth: 1.5,
        color: theme.dividerColor.withValues(alpha: 0.6),
      ));
    }

    // Add closing lines for the grid (south and east edges of last cells)
    if (_visibleCells.isNotEmpty) {
      // Find rightmost and bottommost cells
      double maxEast = _visibleCells.first.bounds.east;
      double minSouth = _visibleCells.first.bounds.south;

      for (final cell in _visibleCells) {
        if (cell.bounds.east > maxEast) maxEast = cell.bounds.east;
        if (cell.bounds.south < minSouth) minSouth = cell.bounds.south;
      }

      // Find bounds of entire grid
      final gridNorth = _visibleCells
          .map((c) => c.bounds.north)
          .reduce((a, b) => a > b ? a : b);
      final gridWest = _visibleCells
          .map((c) => c.bounds.west)
          .reduce((a, b) => a < b ? a : b);

      // Add east edge line
      polylines.add(Polyline(
        points: [
          LatLng(gridNorth, maxEast),
          LatLng(minSouth, maxEast),
        ],
        strokeWidth: 1.5,
        color: theme.dividerColor.withValues(alpha: 0.6),
      ));

      // Add south edge line
      polylines.add(Polyline(
        points: [
          LatLng(minSouth, gridWest),
          LatLng(minSouth, maxEast),
        ],
        strokeWidth: 1.5,
        color: theme.dividerColor.withValues(alpha: 0.6),
      ));
    }

    return PolylineLayer(polylines: polylines);
  }

  /// Builds the cell labels layer (alphanumeric identifiers)
  Widget _buildGridLabels() {
    final theme = Theme.of(context);

    return MarkerLayer(
      markers: _visibleCells.map((cell) {
        return Marker(
          point: cell.centerPoint,
          width: 60,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                cell.id,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
