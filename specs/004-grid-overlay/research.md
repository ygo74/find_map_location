# Research & Technical Decisions: Carte avec Carroyage Alphanumérique

**Feature**: 004-grid-overlay | **Date**: 2025-12-16
**Purpose**: Phase 0 research findings for grid overlay implementation

## Research Questions & Findings

### 1. Grid Coordinate System & Projection

**Question**: How to accurately map geographic coordinates (lat/lon) to square grid cells in meters?

**Decision**: Use Haversine formula for distance calculations with Mercator projection correction

**Rationale**:
- OpenStreetMap uses Web Mercator projection (EPSG:3857)
- At mid-latitudes, 1 degree longitude ≠ 1 degree latitude in meters
- Haversine provides accurate distance between two lat/lon points
- For grid cells, calculate offset from origin in meters, then convert to cell indices

**Alternatives Considered**:
- Simple degree-based grid: Inaccurate; cells wouldn't be square in meters
- UTM projection: Overly complex; requires zone management; overkill for feature

**Implementation Approach**:
```
Origin (A1) = first address location
Cell size = 500m (configurable: 250m, 500m, 1000m, 2000m)

For any point (lat, lon):
  1. Calculate distance in meters from origin (Haversine)
  2. Column index = floor(eastWestDistance / cellSize)
  3. Row index = floor(northSouthDistance / cellSize)
  4. Column letter = indexToLetter(columnIndex)  // A, B, C, ..., Z, AA, AB, ...
  5. Row number = rowIndex + 1  // 1-based numbering
  6. Cell ID = columnLetter + rowNumber  // e.g., "C7"
```

**Dependencies**: `latlong2` package (already in project) provides distance calculation utilities

---

### 2. Grid Rendering Strategy

**Question**: How to efficiently render grid overlay on flutter_map without performance degradation?

**Decision**: Custom FlutterMap PolylineLayer with dynamic line generation for visible bounds

**Rationale**:
- `flutter_map` supports custom layers via `PolylineLayer` for vector graphics
- Generate grid lines only for viewport bounds (cull off-screen cells)
- Polylines are lightweight; can render ~100 lines at 60fps
- Labels rendered as separate `MarkerLayer` with text widgets

**Alternatives Considered**:
- CustomPainter on top of map: Requires manual coordinate transformation; complex
- Image overlay: Not scalable; blurry at different zoom levels
- flutter_map plugin: No existing grid plugin; would add dependency overhead

**Implementation Approach**:
```
On map move/zoom:
  1. Get map viewport bounds (LatLngBounds)
  2. Calculate which cells are visible
  3. Generate Polyline objects for:
     - Vertical lines (column separators)
     - Horizontal lines (row separators)
  4. Generate Marker objects for:
     - Cell labels (e.g., "A1", "B3") at cell centers
  5. Add to map layers
```

**Performance Optimization**:
- Cache grid lines when map is idle (no pan/zoom)
- Debounce regeneration on rapid map movements
- Limit maximum visible cells to ~100 (zoom out triggers coarser grid?)

---

### 3. Alphanumeric Cell Naming (Excel-style)

**Question**: How to generate column names beyond Z (A, B, ..., Z, AA, AB, ...)?

**Decision**: Implement Excel-style base-26 conversion algorithm

**Rationale**:
- Standard convention familiar to users
- Well-documented algorithm; proven in spreadsheet applications
- Handles arbitrary column counts (A-Z = 26, AA-ZZ = 676, AAA-ZZZ = 17576)

**Implementation**:
```dart
String indexToColumnName(int index) {
  String name = '';
  while (index >= 0) {
    name = String.fromCharCode(65 + (index % 26)) + name;
    index = (index ~/ 26) - 1;
  }
  return name;
}

// Examples:
// 0 → "A", 1 → "B", 25 → "Z"
// 26 → "AA", 27 → "AB", 51 → "AZ"
// 52 → "BA", 701 → "ZZ"
```

**Edge Case Handling**: FR-011 requires this for maps covering >26 columns

---

### 4. North-West Boundary Rule

**Question**: How to deterministically assign addresses on cell boundaries?

**Decision**: Implement inclusive north-west boundary rule (address belongs to cell if within or on north/west edges)

**Rationale**:
- Common GIS convention; aligns with map grid standards
- Prevents ambiguity (each point belongs to exactly one cell)
- Easy to implement: use `<= westEdge` and `<= northEdge` comparisons

**Implementation**:
```dart
GridCell getCellForPoint(LatLng point, LatLng origin, double cellSizeMeters) {
  double distanceEast = calculateDistanceEast(origin, point);
  double distanceSouth = calculateDistanceSouth(origin, point);

  int colIndex = (distanceEast / cellSizeMeters).floor();
  int rowIndex = (distanceSouth / cellSizeMeters).floor();

  // North-west rule: if exactly on boundary, belongs to upper-left cell
  // floor() naturally implements this for positive distances

  return GridCell(
    columnIndex: colIndex,
    rowIndex: rowIndex,
    id: '${indexToColumnName(colIndex)}${rowIndex + 1}',
  );
}
```

**Clarification from spec**: Addresses exactly on boundaries belong to north-west cell (FR-005a)

---

### 5. Grid Configuration Persistence

**Question**: How to persist user's grid size preference across app sessions?

**Decision**: Use `shared_preferences` plugin to store selected grid size

**Rationale**:
- Lightweight key-value storage; perfect for simple settings
- Official Flutter plugin; well-maintained
- Works on both iOS and Android
- Synchronous read access after initial load (fast startup)

**Implementation**:
```dart
class GridConfigService {
  static const String _gridSizeKey = 'grid_cell_size_meters';
  static const int _defaultGridSize = 500;

  final SharedPreferences _prefs;

  int getGridSize() => _prefs.getInt(_gridSizeKey) ?? _defaultGridSize;

  Future<void> setGridSize(int sizeMeters) async {
    await _prefs.setInt(_gridSizeKey, sizeMeters);
  }
}
```

**Validation**: Only allow predefined values (250, 500, 1000, 2000) - enforced in settings UI

---

### 6. Grid Origin Calculation & Persistence

**Question**: Should grid origin be recalculated or persisted across sessions?

**Decision**: Calculate origin dynamically on first address search; do NOT persist across app restarts

**Rationale**:
- Persisting origin creates confusion if user changes cities
- Fresh grid on each session provides clean state
- Clarification (spec): Origin fixed for session after first address (FR-003b)
- New session = new game = new grid origin

**Session Lifecycle**:
1. App start: No grid displayed (no origin yet)
2. First address search: Calculate origin centered on address, display grid
3. Subsequent searches: Grid origin remains fixed (FR-003b)
4. App restart: Grid origin reset (requires new first search)

**State Management**: Hold origin in `GridState` (in-memory, not persisted)

---

### 7. Solution Reveal Mechanism

**Question**: How should users reveal the correct cell ID (game solution)?

**Decision**: Add "Show Solution" floating action button visible when address is searched

**Rationale**:
- Unobtrusive: FAB doesn't clutter main UI
- Intentional action: User must click to reveal (preserves game challenge)
- Clear affordance: Button label "Show Solution" is self-explanatory

**UI Flow**:
```
Initial state: No address searched → No "Show Solution" button
Address searched: Button appears → User can click to reveal cell ID
Solution revealed: Show dialog/snackbar: "Address is in cell C7"
New address searched: Hide previous solution; button available again
```

**Clarification from spec**: No automatic highlighting (FR-006a); user reveals solution voluntarily (FR-006)

---

## Technology Stack Summary

| Component | Technology | Justification |
|-----------|------------|---------------|
| Grid Calculations | Dart (pure functions) | Haversine distance, cell index math; easily unit tested |
| Grid Rendering | flutter_map PolylineLayer + MarkerLayer | Leverages existing map infrastructure; vector-based (scalable) |
| Configuration Storage | shared_preferences | Simple key-value persistence for grid size |
| State Management | StatefulWidget + ChangeNotifier | Aligns with existing app architecture; sufficient for grid state |
| Testing | flutter_test (unit, widget), integration_test | Standard Flutter testing; mock GridConfigService for deterministic tests |

---

## Open Questions / Future Enhancements

1. **Grid Visibility Toggle**: Should users be able to hide/show grid overlay? (Not in current spec)
2. **Grid Color Customization**: Should grid line color be themeable? (Use theme colors by default)
3. **Zoom-Dependent Grid Density**: At very zoomed-out levels, should grid disappear or show coarser cells? (FR-010 implies grid stays consistent)
4. **Multiple Grid Origins**: Should app support multiple games/origins simultaneously? (Not in spec; single session = single origin)

**Resolution**: All open questions are out of scope for current spec; can be addressed in future iterations if user feedback warrants.

---

## Dependencies Added

- `shared_preferences: ^2.0.0` (new dependency for grid size persistence)

**Total New Dependencies**: 1 (lightweight, official Flutter plugin)

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Grid rendering performance degrades at high zoom | Medium | High | Limit visible cells to ~100; cull off-screen lines |
| Haversine distance inaccuracies at extreme latitudes | Low | Medium | Document latitude limitations (~85°N/S); acceptable for most use cases |
| Excel-style naming confusion for non-technical users | Low | Low | Familiar convention; provide tooltip/help text if needed |
| Grid origin calculation fails for invalid addresses | Low | Medium | Handled by existing geocoding error handling; grid only appears on successful search |

**Overall Risk Level**: Low. Techniques are well-established; performance optimizations proven in similar applications.

---

## Conclusion

All technical unknowns from spec have been researched and resolved. Grid overlay implementation is feasible with existing flutter_map infrastructure, requiring minimal new dependencies. Performance and accuracy goals are achievable with proposed approach. Ready to proceed to Phase 1 (Design).
