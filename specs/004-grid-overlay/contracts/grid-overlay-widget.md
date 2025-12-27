# Grid Overlay Widget Contract

**Feature**: 004-grid-overlay | **Date**: 2025-12-16
**Purpose**: UI component contract for rendering grid overlay on flutter_map

## Overview

The GridOverlay widget is a Flutter widget that renders the grid overlay on top of a flutter_map instance. It displays grid lines, cell labels, and responds to map viewport changes.

---

## Widget API

### GridOverlayWidget

Main widget for rendering the grid overlay.

**Signature**:
```dart
class GridOverlayWidget extends StatefulWidget {
  final GridConfiguration configuration;
  final FlutterMapController mapController;
  final VoidCallback? onGridUpdate;

  const GridOverlayWidget({
    Key? key,
    required this.configuration,
    required this.mapController,
    this.onGridUpdate,
  }) : super(key: key);
}
```

**Parameters**:
- `configuration`: Current grid configuration (origin, cell size, visibility)
- `mapController`: flutter_map controller for viewport access
- `onGridUpdate`: Optional callback when grid needs redraw

**Behavior**:
- Listens to `mapController.mapEventStream` for pan/zoom events
- Generates visible cells based on current viewport
- Renders grid lines as PolylineLayer
- Renders cell labels as MarkerLayer
- Updates automatically when configuration changes

**Lifecycle**:
1. `initState`: Subscribe to map events
2. `build`: Render grid layers if `configuration.isVisible`
3. `didUpdateWidget`: Regenerate grid if configuration changed
4. `dispose`: Unsubscribe from map events

---

## Rendering Layers

### 1. PolylineLayer (Grid Lines)

**Purpose**: Draw grid cell boundaries

**Implementation**:
```dart
PolylineLayer(
  polylines: [
    ...verticalLines,  // Column separators
    ...horizontalLines,  // Row separators
  ],
)
```

**Line Style**:
- Color: `Theme.of(context).dividerColor` or custom grid color
- Width: 1.5px at zoom 13, scales slightly with zoom
- Opacity: 0.6 (semi-transparent, doesn't obscure map)
- StrokeJoin: `StrokeJoin.round` (smooth corners)

**Optimization**:
- Generate only lines for visible cells (culling)
- Reuse polyline objects when map is idle
- Debounce regeneration on rapid pan/zoom

### 2. MarkerLayer (Cell Labels)

**Purpose**: Display cell IDs (e.g., "A1", "C7") at cell centers

**Implementation**:
```dart
MarkerLayer(
  markers: visibleCells.map((cell) => Marker(
    point: cell.centerPoint,
    width: 40,
    height: 20,
    builder: (ctx) => Container(
      alignment: Alignment.center,
      child: Text(
        cell.id,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withOpacity(0.7),
        ),
      ),
    ),
  )).toList(),
)
```

**Label Style**:
- Font size: 12px at zoom 13, scales with zoom (10px at zoom 11, 14px at zoom 15)
- Color: Theme primary color (high contrast)
- Background: Semi-transparent white for readability
- Positioned at cell center

**Visibility Rules**:
- Labels visible at zoom levels 12-16
- Hide labels if >50 cells visible (too crowded)
- Prioritize labels for cells near viewport center

---

## State Management

### GridOverlayState

Internal state for the widget.

**State Variables**:
```dart
class _GridOverlayWidgetState extends State<GridOverlayWidget> {
  List<GridCell> _visibleCells = [];
  StreamSubscription<MapEvent>? _mapEventSubscription;
  Timer? _debounceTimer;

  // ...
}
```

**State Updates**:
- `_visibleCells`: Regenerated on map move/zoom
- `_mapEventSubscription`: Listens to map events, triggers cell regeneration
- `_debounceTimer`: Delays regeneration during rapid pan/zoom (300ms debounce)

**Update Triggers**:
1. Map pan/zoom → Debounced regeneration
2. Configuration change (didUpdateWidget) → Immediate regeneration
3. Origin set (first address search) → Initial generation

---

## Performance Optimizations

### 1. Viewport Culling

Only generate cells intersecting current viewport:
```dart
List<GridCell> _generateVisibleCells() {
  if (widget.configuration.origin == null) return [];

  LatLngBounds viewport = widget.mapController.bounds!;
  return GridCalculationService.generateVisibleCells(
    viewport,
    widget.configuration.origin!,
    widget.configuration.cellSizeMeters,
    maxCells: 100,  // Hard limit
  );
}
```

### 2. Debounced Regeneration

Prevent excessive redraws during rapid map movements:
```dart
void _onMapEvent(MapEvent event) {
  if (event is MapEventMove || event is MapEventZoom) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      setState(() {
        _visibleCells = _generateVisibleCells();
      });
    });
  }
}
```

### 3. Conditional Label Rendering

Hide labels at extreme zoom levels or high cell counts:
```dart
bool _shouldShowLabels() {
  double zoom = widget.mapController.zoom;
  return zoom >= 12 && zoom <= 16 && _visibleCells.length <= 50;
}
```

---

## Interaction Handling

### Touch Events

Grid overlay is non-interactive (touch-through):
- `IgnorePointer` wrapper around grid layers (if needed)
- Map gestures (pan, zoom, tap) pass through to underlying map
- Grid updates automatically as map moves

### "Show Solution" Button Integration

Button handled by parent screen, not GridOverlay widget:
```dart
// In MapScreen (parent widget)
if (hasSearchedAddress && gridConfiguration.origin != null) {
  FloatingActionButton(
    onPressed: _showSolution,
    child: Icon(Icons.lightbulb_outline),
    tooltip: 'Show Solution',
  )
}

void _showSolution() {
  String cellId = addressPoint.containingCellId;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Address is in cell $cellId')),
  );
}
```

---

## Accessibility

### Semantic Labels

Grid overlay is decorative (not interactive), but support screen readers:
```dart
Semantics(
  label: 'Grid overlay with ${_visibleCells.length} cells visible',
  readOnly: true,
  child: PolylineLayer(...),
)
```

### High Contrast Mode

Respect system theme and accessibility settings:
```dart
Color _getGridLineColor(BuildContext context) {
  bool highContrast = MediaQuery.of(context).highContrast;
  return highContrast
    ? Theme.of(context).colorScheme.onSurface
    : Theme.of(context).dividerColor;
}
```

---

## Error Handling

### Invalid Configuration

Handle missing or invalid configuration gracefully:
```dart
@override
Widget build(BuildContext context) {
  if (!widget.configuration.isVisible ||
      widget.configuration.origin == null) {
    return SizedBox.shrink();  // Render nothing
  }

  if (_visibleCells.isEmpty) {
    return SizedBox.shrink();  // No cells to display
  }

  return Stack(
    children: [
      PolylineLayer(...),
      if (_shouldShowLabels()) MarkerLayer(...),
    ],
  );
}
```

### Map Controller Errors

Handle null or uninitialized map controller:
```dart
void _onMapEvent(MapEvent event) {
  try {
    if (widget.mapController.bounds == null) return;
    // ... regenerate cells
  } catch (e) {
    debugPrint('GridOverlay error: $e');
    // Graceful degradation: don't crash, just skip update
  }
}
```

---

## Testing Requirements

### Widget Tests

1. **Rendering**:
   - Test grid renders when origin set and visible
   - Test grid hidden when origin null or not visible
   - Test grid updates on configuration change

2. **Layers**:
   - Test PolylineLayer contains correct number of lines
   - Test MarkerLayer contains cell labels
   - Test label visibility at different zoom levels

3. **Performance**:
   - Test debouncing works (no excessive rebuilds)
   - Test culling limits cells to maxCells
   - Test no frame drops during simulated pan/zoom

### Integration Tests

- Full map interaction: Pan, zoom, verify grid stays aligned
- Configuration change: Change cell size, verify grid redraws
- Solution reveal: Search address, click button, verify cell ID displayed

---

## Theme Integration

### Default Styling

Grid uses theme colors for consistency:
```dart
PolylineLayerOptions(
  polylines: lines.map((line) => Polyline(
    points: line,
    color: Theme.of(context).dividerColor,
    strokeWidth: 1.5,
  )).toList(),
)
```

### Custom Styling (Optional)

Allow customization via GridConfiguration (future enhancement):
```dart
class GridConfiguration {
  final Color? customGridColor;
  final double? customLineWidth;
  // ...
}
```

---

## Dependencies

**Required Packages**:
- `flutter_map` (^7.0.0): PolylineLayer, MarkerLayer
- `latlong2` (^0.9.0): LatLng, LatLngBounds
- Flutter SDK: Widgets, Theme, Stream

**Internal Dependencies**:
- `GridCalculationService`: Generate visible cells
- `GridConfiguration`: Configuration state
- `GridCell`: Cell data model

---

## Summary

**Widget Responsibility**: Rendering only. No business logic (calculations delegated to GridCalculationService).

**Performance Target**: 60fps during map interactions with <100 visible cells.

**Accessibility**: Supports screen readers and high contrast mode.

**Test Coverage Target**: 70%+ (widget rendering logic).
