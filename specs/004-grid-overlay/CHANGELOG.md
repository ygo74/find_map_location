# Changelog - Feature 004: Grid Overlay

## [2025-12-27] - Architectural Refinements

### Changed

**Grid Centering and Alignment**
- Grid is now centered on the **city center** instead of the first searched address
- Grid origin aligns to **city bounds** (north-west corner) for optimal city coverage
- Grid remains **fixed for the entire city**, not per-address
- Snap-to-grid algorithm ensures consistent alignment with city boundaries

**Map Navigation Constraints**
- Map navigation is now **restricted to city boundaries** (5km radius default)
- Users cannot pan outside the game area
- Zoom levels constrained: minimum 12.0, maximum 18.0
- Implemented using `flutter_map` CameraConstraint.contain()

**API Changes**
- `GridCalculationService.calculateGridOrigin()` signature updated:
  - Old: `(LatLng addressPoint, double cellSizeMeters, {int gridWidth = 10, int gridHeight = 10})`
  - New: `(LatLng cityCenter, double cellSizeMeters, {GridBounds? cityBounds})`
  - Removed: gridWidth, gridHeight parameters (no longer needed)
  - Added: optional cityBounds parameter for alignment

**New Features**
- Added `GridCalculationService.calculateCityBounds()` method
  - Calculates city boundaries with specified radius (default 5km)
  - Returns GridBounds with north, south, east, west coordinates
  - Used for both grid alignment and map constraints

**Technical Updates**
- Updated `flutter_map` dependency to ^8.2.2 (for CameraConstraint support)
- Modified `MapDisplay` widget to accept cityBounds parameter
- Enhanced `home_screen.dart` to calculate and pass city bounds

### Rationale

**Why These Changes?**

1. **Better Game Design**:
   - Grid should represent the entire city uniformly
   - All addresses in the same city use the same consistent grid
   - Prevents confusion from grid shifting between addresses

2. **Improved User Experience**:
   - Constraining map to city bounds focuses attention on relevant area
   - Prevents accidental navigation outside game zone
   - Zoom constraints ensure grid remains visible and readable

3. **Technical Consistency**:
   - Grid alignment with city bounds produces cleaner, more predictable layout
   - Snap-to-grid algorithm eliminates arbitrary offsets
   - City-based approach scales better for multi-address gameplay

### Testing

**Unit Tests**
- ✅ All 19 grid calculation tests passing
- ✅ Updated 3 tests in calculateGridOrigin group
- ✅ Added test for calculateCityBounds method

**Integration Tests**
- ⚠️ Some integration tests need updates for new behavior
- Grid expectations changed (city-centered, not address-centered)
- Map bounds constraints may affect navigation tests

### Files Modified

**Core Logic**:
- `lib/services/grid_calculation_service.dart`
  - Modified: calculateGridOrigin() method
  - Added: calculateCityBounds() method

**UI Components**:
- `lib/widgets/map_display.dart`
  - Added: cityBounds parameter
  - Added: CameraConstraint configuration
  - Added: Zoom level constraints

**Screens**:
- `lib/screens/home_screen.dart`
  - Modified: Grid initialization logic (uses city center)
  - Added: City bounds calculation
  - Modified: Passes cityBounds to MapDisplay

**Tests**:
- `test/services/grid_calculation_service_test.dart`
  - Updated: 3 calculateGridOrigin tests
  - Added: calculateCityBounds test

**Documentation**:
- `specs/004-grid-overlay/spec.md`
  - Updated: FR-003a, FR-003b, FR-003c requirements
  - Added: FR-013, FR-014, FR-015 for map constraints
  - Added: Session 2025-12-27 clarifications

- `specs/004-grid-overlay/plan.md`
  - Updated: Summary section
  - Updated: Primary dependencies (flutter_map ^8.2.2)
  - Updated: Constraints and key integration points

- `specs/004-grid-overlay/tasks.md`
  - Updated: T010 description
  - Added: T010a (calculateCityBounds)
  - Added: T016a (calculateCityBounds tests)
  - Updated: T027 (grid initialization)
  - Added: T027a (map constraints)
  - Added: Architectural Changes section

---

## [2025-12-16] - Initial Implementation

### Added

**Core Features**
- Grid overlay system with alphanumeric cell identifiers (A1, B2, etc.)
- Configurable cell sizes: 250m, 500m (default), 1000m, 2000m
- "Show Solution" button to reveal correct cell for searched address
- Grid settings dialog with persistent preferences
- North-west boundary rule for addresses on cell edges

**Components Created**
- GridCell model (immutable data class)
- GridConfiguration state (ChangeNotifier)
- GridSettings model (persisted)
- GridCalculationService (pure calculation functions)
- GridSettingsService (shared_preferences wrapper)
- GridOverlayWidget (rendering component)
- GridSettingsDialog (configuration UI)

**Testing**
- 19 unit tests for grid calculations
- 6 widget tests for UI components
- 2 integration tests for user flows

**Documentation**
- Complete specification in spec.md
- Technical plan in plan.md
- Implementation tasks in tasks.md
- API contracts in contracts/
- Developer guide in quickstart.md

### Dependencies

- `flutter_map` ^7.0.0 (later updated to ^8.2.2)
- `latlong2` ^0.9.0
- `shared_preferences` ^2.0.0

---

## Migration Guide

### For Developers Using Old calculateGridOrigin API

**Before**:
```dart
final origin = GridCalculationService.calculateGridOrigin(
  addressPoint,
  500.0,
  gridWidth: 10,
  gridHeight: 10,
);
```

**After**:
```dart
// Calculate city bounds
final cityBounds = GridCalculationService.calculateCityBounds(
  cityCenter,
  5000.0, // 5km radius
);

// Calculate grid origin aligned with city
final origin = GridCalculationService.calculateGridOrigin(
  cityCenter,
  500.0,
  cityBounds: cityBounds,
);
```

### For MapDisplay Widget Users

**Before**:
```dart
MapDisplay(
  cityCenter: cityCenter,
  currentAddress: address,
)
```

**After**:
```dart
// Calculate city bounds
final cityBounds = GridCalculationService.calculateCityBounds(
  cityCenter,
  5000.0,
);

MapDisplay(
  cityCenter: cityCenter,
  currentAddress: address,
  cityBounds: cityBounds, // NEW: Required for map constraints
)
```

### Breaking Changes

1. `GridCalculationService.calculateGridOrigin()` signature changed
   - Removed: `gridWidth` and `gridHeight` parameters
   - Added: optional `cityBounds` parameter
   - Parameter order changed: city center first, then cell size

2. Grid behavior changed from address-centered to city-centered
   - Tests expecting address-based centering will need updates
   - Grid no longer shifts between different addresses in same city

3. Map navigation is now constrained
   - Tests that pan outside city bounds will fail
   - Zoom level tests must respect min/max constraints (12.0-18.0)
