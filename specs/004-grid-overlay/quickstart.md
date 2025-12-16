# Developer Quickstart: Carte avec Carroyage Alphanumérique

**Feature**: 004-grid-overlay | **Date**: 2025-12-16
**Audience**: Developers implementing this feature

## Overview

This feature adds a configurable grid overlay to the map with alphanumeric cell identifiers. Users can adjust grid cell size and play a game of guessing which cell contains a searched address.

**Key Components**:
- Grid calculation logic (pure Dart functions)
- Grid overlay widget (flutter_map layers)
- Settings UI (cell size configuration)
- Solution reveal mechanism (game feature)

---

## Prerequisites

**Existing Codebase**:
- Flutter project with `flutter_map` integration
- Address search functionality (geocoding)
- Map screen displaying OpenStreetMap

**Dependencies to Add**:
```yaml
dependencies:
  shared_preferences: ^2.0.0  # New: for grid size persistence

  # Existing (no changes needed)
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
```

Run `flutter pub get` after updating `pubspec.yaml`.

---

## File Structure

Create the following new files:

```
lib/
├── models/
│   ├── grid_cell.dart              # GridCell data class
│   ├── grid_configuration.dart     # GridConfiguration state
│   └── grid_settings.dart          # GridSettings (persisted)
├── services/
│   ├── grid_calculation_service.dart  # Pure calculation functions
│   └── grid_settings_service.dart     # shared_preferences wrapper
├── widgets/
│   ├── grid_overlay_widget.dart    # Main grid rendering widget
│   └── grid_settings_dialog.dart   # Settings UI
└── screens/
    └── [existing map_screen.dart]  # Modify to integrate grid

test/
├── services/
│   └── grid_calculation_service_test.dart  # Unit tests
└── widgets/
    └── grid_overlay_widget_test.dart       # Widget tests
```

---

## Step-by-Step Implementation

### Step 1: Data Models

#### 1.1 GridCell Model

```dart
// lib/models/grid_cell.dart
import 'package:latlong2/latlong.dart';

class GridCell {
  final String id;
  final int columnIndex;
  final int rowIndex;
  final LatLngBounds bounds;
  final LatLng centerPoint;

  const GridCell({
    required this.id,
    required this.columnIndex,
    required this.rowIndex,
    required this.bounds,
    required this.centerPoint,
  });

  @override
  String toString() => 'GridCell($id)';
}
```

#### 1.2 GridConfiguration Model

```dart
// lib/models/grid_configuration.dart
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'grid_cell.dart';

class GridConfiguration extends ChangeNotifier {
  int _cellSizeMeters;
  LatLng? _origin;
  bool _isVisible = false;

  GridConfiguration({int cellSizeMeters = 500})
      : _cellSizeMeters = cellSizeMeters;

  int get cellSizeMeters => _cellSizeMeters;
  LatLng? get origin => _origin;
  bool get isVisible => _isVisible && _origin != null;

  void setOrigin(LatLng origin) {
    _origin = origin;
    _isVisible = true;
    notifyListeners();
  }

  void setCellSize(int sizeMeters) {
    if ([250, 500, 1000, 2000].contains(sizeMeters)) {
      _cellSizeMeters = sizeMeters;
      notifyListeners();
    }
  }

  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  void reset() {
    _origin = null;
    _isVisible = false;
    notifyListeners();
  }
}
```

---

### Step 2: Grid Calculation Service

```dart
// lib/services/grid_calculation_service.dart
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/grid_cell.dart';

class GridCalculationService {
  static const Distance _distance = Distance();

  /// Calculates grid origin centered on an address point
  static LatLng calculateGridOrigin(
    LatLng addressPoint,
    double cellSizeMeters, {
    int gridWidth = 10,
    int gridHeight = 10,
  }) {
    double offsetEastMeters = (gridWidth / 2) * cellSizeMeters;
    double offsetNorthMeters = (gridHeight / 2) * cellSizeMeters;

    // Calculate origin (top-left of A1) by offsetting west and north
    double lat = _distance.offset(
      addressPoint.latitude,
      offsetNorthMeters,
      0,  // North (bearing 0°)
    ).latitude;

    double lon = _distance.offset(
      addressPoint.longitude,
      offsetEastMeters,
      270,  // West (bearing 270°)
    ).longitude;

    return LatLng(lat, lon);
  }

  /// Gets the grid cell containing a point
  static GridCell getCellForPoint(
    LatLng point,
    LatLng origin,
    double cellSizeMeters,
  ) {
    // Calculate distances in meters
    double eastDistance = _distance.as(
      LengthUnit.Meter,
      origin,
      LatLng(origin.latitude, point.longitude),
    );
    double southDistance = _distance.as(
      LengthUnit.Meter,
      origin,
      LatLng(point.latitude, origin.longitude),
    );

    // Calculate indices (north-west boundary rule via floor)
    int colIndex = (eastDistance / cellSizeMeters).floor();
    int rowIndex = (southDistance / cellSizeMeters).floor();

    // Generate cell ID
    String cellId = '${indexToColumnName(colIndex)}${rowIndex + 1}';

    // Calculate cell bounds
    LatLngBounds bounds = calculateCellBounds(
      colIndex,
      rowIndex,
      origin,
      cellSizeMeters,
    );

    // Calculate center point
    LatLng center = LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );

    return GridCell(
      id: cellId,
      columnIndex: colIndex,
      rowIndex: rowIndex,
      bounds: bounds,
      centerPoint: center,
    );
  }

  /// Converts column index to Excel-style name
  static String indexToColumnName(int index) {
    String name = '';
    int temp = index;
    while (temp >= 0) {
      name = String.fromCharCode(65 + (temp % 26)) + name;
      temp = (temp ~/ 26) - 1;
    }
    return name;
  }

  /// Generates visible cells for a viewport
  static List<GridCell> generateVisibleCells(
    LatLngBounds viewportBounds,
    LatLng origin,
    double cellSizeMeters, {
    int maxCells = 100,
  }) {
    List<GridCell> cells = [];

    // Calculate min/max indices for viewport
    GridCell topLeft = getCellForPoint(
      LatLng(viewportBounds.north, viewportBounds.west),
      origin,
      cellSizeMeters,
    );
    GridCell bottomRight = getCellForPoint(
      LatLng(viewportBounds.south, viewportBounds.east),
      origin,
      cellSizeMeters,
    );

    int minCol = topLeft.columnIndex;
    int maxCol = bottomRight.columnIndex;
    int minRow = topLeft.rowIndex;
    int maxRow = bottomRight.rowIndex;

    // Generate cells
    for (int row = minRow; row <= maxRow; row++) {
      for (int col = minCol; col <= maxCol; col++) {
        if (cells.length >= maxCells) return cells;

        String cellId = '${indexToColumnName(col)}${row + 1}';
        LatLngBounds bounds = calculateCellBounds(
          col,
          row,
          origin,
          cellSizeMeters,
        );
        LatLng center = LatLng(
          (bounds.north + bounds.south) / 2,
          (bounds.east + bounds.west) / 2,
        );

        cells.add(GridCell(
          id: cellId,
          columnIndex: col,
          rowIndex: row,
          bounds: bounds,
          centerPoint: center,
        ));
      }
    }

    return cells;
  }

  /// Calculates geographic bounds for a cell
  static LatLngBounds calculateCellBounds(
    int columnIndex,
    int rowIndex,
    LatLng origin,
    double cellSizeMeters,
  ) {
    double northWestLat = _distance.offset(
      origin.latitude,
      rowIndex * cellSizeMeters,
      180,  // South
    ).latitude;

    double northWestLon = _distance.offset(
      origin.longitude,
      columnIndex * cellSizeMeters,
      90,  // East
    ).longitude;

    double southEastLat = _distance.offset(
      northWestLat,
      cellSizeMeters,
      180,  // South
    ).latitude;

    double southEastLon = _distance.offset(
      northWestLon,
      cellSizeMeters,
      90,  // East
    ).longitude;

    return LatLngBounds(
      LatLng(northWestLat, northWestLon),
      LatLng(southEastLat, southEastLon),
    );
  }
}
```

---

### Step 3: Grid Overlay Widget (Simplified)

```dart
// lib/widgets/grid_overlay_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/grid_configuration.dart';
import '../models/grid_cell.dart';
import '../services/grid_calculation_service.dart';

class GridOverlayWidget extends StatefulWidget {
  final GridConfiguration configuration;
  final MapController mapController;

  const GridOverlayWidget({
    Key? key,
    required this.configuration,
    required this.mapController,
  }) : super(key: key);

  @override
  State<GridOverlayWidget> createState() => _GridOverlayWidgetState();
}

class _GridOverlayWidgetState extends State<GridOverlayWidget> {
  List<GridCell> _visibleCells = [];

  @override
  void initState() {
    super.initState();
    widget.configuration.addListener(_onConfigChanged);
    widget.mapController.mapEventStream.listen(_onMapEvent);
  }

  @override
  void dispose() {
    widget.configuration.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    setState(() {
      _generateVisibleCells();
    });
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove || event is MapEventMoveEnd) {
      _generateVisibleCells();
    }
  }

  void _generateVisibleCells() {
    if (!widget.configuration.isVisible) {
      _visibleCells = [];
      return;
    }

    final bounds = widget.mapController.bounds;
    if (bounds != null) {
      _visibleCells = GridCalculationService.generateVisibleCells(
        bounds,
        widget.configuration.origin!,
        widget.configuration.cellSizeMeters.toDouble(),
      );
    }
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

  Widget _buildGridLines() {
    // Implement polyline layer for grid lines
    // See contracts/grid-overlay-widget.md for full implementation
    return Container();  // Placeholder
  }

  Widget _buildGridLabels() {
    // Implement marker layer for cell labels
    // See contracts/grid-overlay-widget.md for full implementation
    return Container();  // Placeholder
  }
}
```

---

### Step 4: Integration with Map Screen

Modify existing map screen to integrate grid:

```dart
// In existing map_screen.dart

class MapScreen extends StatefulWidget {
  // ... existing code
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  late GridConfiguration _gridConfig;
  String? _currentAddressCellId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _gridConfig = GridConfiguration(cellSizeMeters: 500);
    _loadGridSettings();
  }

  Future<void> _loadGridSettings() async {
    // Load saved grid size from shared_preferences
    // Set _gridConfig.setCellSize(loadedValue)
  }

  void _onAddressSearched(LatLng coordinates) {
    // Existing address search logic...

    // NEW: Initialize grid origin on first search
    if (_gridConfig.origin == null) {
      LatLng origin = GridCalculationService.calculateGridOrigin(
        coordinates,
        _gridConfig.cellSizeMeters.toDouble(),
      );
      _gridConfig.setOrigin(origin);
    }

    // NEW: Calculate cell ID for address
    GridCell cell = GridCalculationService.getCellForPoint(
      coordinates,
      _gridConfig.origin!,
      _gridConfig.cellSizeMeters.toDouble(),
    );
    setState(() {
      _currentAddressCellId = cell.id;
    });
  }

  void _showSolution() {
    if (_currentAddressCellId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Address is in cell $_currentAddressCellId'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(...),
        children: [
          TileLayer(...),  // Existing map tiles
          // NEW: Add grid overlay
          GridOverlayWidget(
            configuration: _gridConfig,
            mapController: _mapController,
          ),
          // Existing markers, etc.
        ],
      ),
      floatingActionButton: _currentAddressCellId != null
          ? FloatingActionButton(
              onPressed: _showSolution,
              tooltip: 'Show Solution',
              child: const Icon(Icons.lightbulb_outline),
            )
          : null,
    );
  }
}
```

---

## Testing Strategy

### 1. Unit Tests (Priority: High)

Test calculation logic first:

```dart
// test/services/grid_calculation_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('GridCalculationService', () {
    test('indexToColumnName converts indices correctly', () {
      expect(GridCalculationService.indexToColumnName(0), 'A');
      expect(GridCalculationService.indexToColumnName(25), 'Z');
      expect(GridCalculationService.indexToColumnName(26), 'AA');
    });

    test('getCellForPoint applies north-west boundary rule', () {
      // Test point on north edge belongs to cell
      // Test point on west edge belongs to cell
      // Test point on south/east edge belongs to adjacent cell
    });

    // Add more tests...
  });
}
```

Run tests: `flutter test test/services/grid_calculation_service_test.dart`

### 2. Widget Tests

Test grid rendering:

```dart
// test/widgets/grid_overlay_widget_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GridOverlay renders when visible', (tester) async {
    // Create mock configuration with origin set
    // Pump widget
    // Verify grid layers present
  });

  testWidgets('GridOverlay hidden when origin null', (tester) async {
    // Create configuration without origin
    // Pump widget
    // Verify no grid rendered
  });
}
```

### 3. Integration Tests

Test full user flow:

```bash
flutter test integration_test/grid_overlay_flow_test.dart
```

---

## Troubleshooting

### Issue: Grid not appearing after address search

**Check**:
1. Is `_gridConfig.origin` set after search?
2. Is `_gridConfig.isVisible` true?
3. Are visible cells generated? (Debug print `_visibleCells.length`)

**Solution**: Ensure `setOrigin()` called after successful geocoding.

---

### Issue: Grid lines misaligned with map

**Check**:
- Coordinate conversion accuracy in `calculateCellBounds`
- Haversine distance calculation

**Solution**: Verify `latlong2` package using correct distance formula.

---

### Issue: Performance degradation on zoom out

**Check**:
- Number of visible cells (should be <100)
- Debounce timer working?

**Solution**: Implement `maxCells` limit in `generateVisibleCells`.

---

## Next Steps

1. **Implement full GridOverlayWidget**: Add polyline and marker layers (see contracts/)
2. **Add settings UI**: Create GridSettingsDialog for cell size selection
3. **Persist settings**: Implement GridSettingsService with shared_preferences
4. **Write comprehensive tests**: Achieve 80% coverage for calculation logic
5. **Golden tests**: Add visual regression tests for grid rendering

---

## Key Decisions Reference

- **Origin Calculation**: Centered on first searched address (clarification #1)
- **No Auto-Highlight**: User must click "Show Solution" (clarification #2)
- **Predefined Sizes**: 250m, 500m, 1000m, 2000m only (clarification #3)
- **Fixed Grid**: Origin persists across searches in same session (clarification #4)
- **Boundary Rule**: North-west priority for addresses on edges (clarification #5)

---

## Resources

- **Spec**: [spec.md](spec.md)
- **Research**: [research.md](research.md)
- **Data Model**: [data-model.md](data-model.md)
- **Contracts**: [contracts/](contracts/)
- **flutter_map docs**: https://docs.fleaflet.dev/
- **latlong2 docs**: https://pub.dev/packages/latlong2
