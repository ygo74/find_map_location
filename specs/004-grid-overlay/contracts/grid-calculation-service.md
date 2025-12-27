# Grid Calculation Service Contract

**Feature**: 004-grid-overlay | **Date**: 2025-12-16
**Purpose**: Internal API contract for grid calculation logic

## Overview

The GridCalculationService provides pure functions for calculating grid cells, cell IDs, and coordinate-to-cell mappings. This service has no UI dependencies and can be unit tested in isolation.

---

## API Methods

### 1. calculateGridOrigin

Calculates the grid origin (top-left of cell A1) centered on a given address point.

**Signature**:
```dart
LatLng calculateGridOrigin(
  LatLng addressPoint,
  double cellSizeMeters,
  int gridWidth,  // Number of columns to center
  int gridHeight  // Number of rows to center
)
```

**Parameters**:
- `addressPoint`: Geographic coordinates of the address to center on
- `cellSizeMeters`: Size of each grid cell in meters (250, 500, 1000, or 2000)
- `gridWidth`: Number of columns for centering (e.g., 10 means address at column E)
- `gridHeight`: Number of rows for centering (e.g., 10 means address at row 5)

**Returns**: `LatLng` representing the grid origin (north-west corner of cell A1)

**Behavior**:
- Calculates offset in meters: `offsetEast = (gridWidth / 2) * cellSizeMeters`, `offsetSouth = (gridHeight / 2) * cellSizeMeters`
- Applies offset to `addressPoint` to find origin
- Uses Haversine inverse formula to convert meter offsets to lat/lon deltas

**Example**:
```dart
LatLng address = LatLng(48.8566, 2.3522);  // Paris
double cellSize = 500;  // 500m cells
LatLng origin = calculateGridOrigin(address, cellSize, 10, 10);
// Result: origin ~2.5km west and ~2.5km north of Paris center
```

---

### 2. getCellForPoint

Determines which grid cell contains a given geographic point.

**Signature**:
```dart
GridCell getCellForPoint(
  LatLng point,
  LatLng origin,
  double cellSizeMeters
)
```

**Parameters**:
- `point`: Geographic coordinates to locate
- `origin`: Grid origin (top-left of cell A1)
- `cellSizeMeters`: Size of each cell in meters

**Returns**: `GridCell` containing the point

**Behavior**:
- Calculates distance from origin to point in meters (Haversine)
- Computes `columnIndex = floor(eastDistance / cellSizeMeters)`
- Computes `rowIndex = floor(southDistance / cellSizeMeters)`
- Applies north-west boundary rule: points exactly on north or west edges belong to cell
- Generates cell ID from indices: `columnLetter + (rowIndex + 1)`

**Boundary Rule (FR-005a)**:
```
If point.lon == cellWestEdge: Belongs to this cell (west priority)
If point.lat == cellNorthEdge: Belongs to this cell (north priority)
If point.lon > cellWestEdge AND point.lon < cellEastEdge: Inside cell
If point.lat < cellNorthEdge AND point.lat > cellSouthEdge: Inside cell
```

**Example**:
```dart
LatLng origin = LatLng(48.87, 2.33);
LatLng point = LatLng(48.865, 2.345);  // ~500m south, ~1000m east of origin
GridCell cell = getCellForPoint(point, origin, 500);
// Result: GridCell(columnIndex: 2, rowIndex: 1, id: "C2")
```

---

### 3. indexToColumnName

Converts a zero-based column index to an Excel-style letter name.

**Signature**:
```dart
String indexToColumnName(int columnIndex)
```

**Parameters**:
- `columnIndex`: Zero-based column index (0 = A, 1 = B, ..., 25 = Z, 26 = AA, ...)

**Returns**: Column name as string (e.g., "A", "Z", "AA", "ABC")

**Behavior**:
- Implements base-26 conversion algorithm
- Supports arbitrary column counts (A-Z, AA-ZZ, AAA-ZZZ, ...)

**Algorithm**:
```dart
String indexToColumnName(int index) {
  String name = '';
  while (index >= 0) {
    name = String.fromCharCode(65 + (index % 26)) + name;
    index = (index ~/ 26) - 1;
  }
  return name;
}
```

**Examples**:
```dart
indexToColumnName(0)   // "A"
indexToColumnName(25)  // "Z"
indexToColumnName(26)  // "AA"
indexToColumnName(51)  // "AZ"
indexToColumnName(52)  // "BA"
indexToColumnName(701) // "ZZ"
indexToColumnName(702) // "AAA"
```

**Edge Cases**:
- Negative indices: Undefined behavior (invalid input)
- Large indices (>18278 = "ZZZ"): Supported but impractical for map grids

---

### 4. generateVisibleCells

Generates all grid cells visible within a map viewport.

**Signature**:
```dart
List<GridCell> generateVisibleCells(
  LatLngBounds viewportBounds,
  LatLng origin,
  double cellSizeMeters,
  {int maxCells = 100}
)
```

**Parameters**:
- `viewportBounds`: Geographic bounds of the map viewport (north, south, east, west)
- `origin`: Grid origin (top-left of cell A1)
- `cellSizeMeters`: Size of each cell in meters
- `maxCells`: Maximum number of cells to generate (performance limit)

**Returns**: List of `GridCell` objects intersecting the viewport

**Behavior**:
- Calculates min/max column and row indices for viewport
- Iterates through cells in range, creating GridCell instances
- Stops if `maxCells` limit reached (prevents performance issues on extreme zoom-out)
- Includes small buffer around viewport (e.g., +1 cell on each edge) for smooth panning

**Performance**:
- Optimized for typical viewport: 5x5 to 10x10 cells (~25-100 cells)
- Culls off-screen cells automatically
- Returns empty list if origin not set (grid not initialized)

**Example**:
```dart
LatLngBounds viewport = LatLngBounds(
  LatLng(48.87, 2.33),  // North-west
  LatLng(48.85, 2.36),  // South-east
);
List<GridCell> cells = generateVisibleCells(viewport, origin, 500);
// Result: ~6x6 grid = 36 cells
```

---

### 5. calculateCellBounds

Calculates the geographic bounds of a grid cell given its indices.

**Signature**:
```dart
LatLngBounds calculateCellBounds(
  int columnIndex,
  int rowIndex,
  LatLng origin,
  double cellSizeMeters
)
```

**Parameters**:
- `columnIndex`: Zero-based column index
- `rowIndex`: Zero-based row index
- `origin`: Grid origin
- `cellSizeMeters`: Cell size in meters

**Returns**: `LatLngBounds` representing the cell's geographic rectangle

**Behavior**:
- Calculates north-west corner: `origin + (columnIndex * cellSize, rowIndex * cellSize)`
- Calculates south-east corner: `north-west + (cellSize, cellSize)`
- Uses Haversine inverse to convert meter offsets to lat/lon

**Example**:
```dart
LatLngBounds bounds = calculateCellBounds(2, 3, origin, 500);
// Cell C4 (columnIndex 2, rowIndex 3)
// Result: Bounds 1000m-1500m east and 1500m-2000m south of origin
```

---

## Error Handling

### Invalid Inputs
- **Null parameters**: Throw `ArgumentError` with descriptive message
- **Invalid cellSizeMeters**: Accept any positive number (validation done at UI layer)
- **Invalid coordinates**: Accept any valid LatLng (-90 ≤ lat ≤ 90, -180 ≤ lon ≤ 180)

### Edge Cases
- **Origin not set**: Return empty list for `generateVisibleCells`, throw error for `getCellForPoint`
- **Point far from origin**: May result in very large column/row indices (acceptable)
- **Viewport exceeds maxCells**: Truncate list to maxCells, prioritize center cells

### Performance Constraints
- All methods must complete in <100ms for typical inputs
- `generateVisibleCells` must not generate >100 cells (hard limit)
- Distance calculations use efficient Haversine approximation (not full great-circle)

---

## Testing Requirements

### Unit Tests (Required)

1. **calculateGridOrigin**:
   - Test centering on known coordinates
   - Verify offset calculation accuracy (±10m acceptable)
   - Test with different cell sizes (250, 500, 1000, 2000)

2. **getCellForPoint**:
   - Test point clearly inside cell (mid-point)
   - Test point on north edge (should belong to cell)
   - Test point on west edge (should belong to cell)
   - Test point on south edge (should belong to cell below)
   - Test point on east edge (should belong to cell to right)
   - Test point at exact corner (north-west priority)

3. **indexToColumnName**:
   - Test A-Z (indices 0-25)
   - Test AA-AZ (indices 26-51)
   - Test BA-ZZ (indices 52-701)
   - Test AAA+ (indices 702+)

4. **generateVisibleCells**:
   - Test typical viewport (5x5 cells)
   - Test large viewport (exceeds maxCells limit)
   - Test viewport with no cells (outside grid)
   - Test viewport at grid boundaries

5. **calculateCellBounds**:
   - Test cell A1 (indices 0, 0)
   - Test arbitrary cell (e.g., C4)
   - Verify bounds accuracy (±10m acceptable)

### Integration Tests
- Full flow: Set origin → Generate cells → Find cell for point → Verify cell ID
- Map pan/zoom: Verify cells regenerate correctly on viewport change

---

## Dependencies

**Required Packages**:
- `latlong2` (^0.9.0): LatLng, LatLngBounds, distance calculations
- Dart math library: `dart:math` for floor, conversion functions

**No External Dependencies**: Service is pure Dart; no Flutter UI dependencies

---

## Performance Benchmarks

**Target Performance** (measured on mid-range device):
- `getCellForPoint`: <1ms per call
- `generateVisibleCells`: <50ms for 100 cells
- `calculateGridOrigin`: <5ms
- `indexToColumnName`: <0.1ms

**Acceptable Performance**:
- All operations <100ms total for grid recalculation
- No frame drops during map pan/zoom

---

## Summary

**Contract Stability**: ✅ Stable. Methods cover all requirements from spec and data model.

**Test Coverage Target**: 90%+ for calculation logic (pure functions, easily testable)

**Breaking Changes**: None expected. API designed to accommodate future enhancements (e.g., custom grid shapes) without breaking existing methods.
