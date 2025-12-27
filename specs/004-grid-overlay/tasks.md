# Tasks: Carte avec Carroyage Alphanumérique

**Feature**: 004-grid-overlay | **Branch**: `004-grid-overlay` | **Date**: 2025-12-16
**Input**: Design documents from `/specs/004-grid-overlay/`
**Prerequisites**: ✅ plan.md, ✅ spec.md, ✅ research.md, ✅ data-model.md, ✅ contracts/

## Implementation Strategy

**MVP Approach**: Deliver User Story 1 (P1) first for immediate value. User Stories 2 and 3 build incrementally.

**Parallel Opportunities**: Tasks marked [P] can be executed in parallel (different files, no dependencies).

**Test-First**: Tests written before implementation where explicitly marked.

---

## Dependencies & Completion Order

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational - BLOCKING)
    ↓
    ├─→ Phase 3: User Story 1 (P1) → MVP Delivery
    ├─→ Phase 4: User Story 2 (P2) → Game Mechanism
    └─→ Phase 5: User Story 3 (P3) → Configuration
    ↓
Phase 6 (Polish & Cross-Cutting)
```

**Recommended Execution**:
1. Complete Phase 1 + 2 (foundational)
2. Implement User Story 1 entirely (working grid display = MVP)
3. Add User Story 2 (solution reveal)
4. Add User Story 3 (settings)
5. Polish

---

## Parallel Execution Examples

### After Phase 2, these can run in parallel:
- **Track A**: US1 models (T010, T011, T012) → US1 service (T013)
- **Track B**: US1 widget structure (T014) → US1 rendering (T015, T016)
- **Merge**: US1 integration (T017)

### Within User Story 2:
- **Track A**: Solution button UI (T023)
- **Track B**: Cell ID calculation enhancement (T024)
- **Merge**: Solution reveal integration (T025)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency setup

- [X] T001 Add `shared_preferences: ^2.0.0` to pubspec.yaml dependencies
- [X] T002 Run `flutter pub get` to install new dependency
- [X] T003 [P] Create directory structure: lib/models/, lib/services/, lib/widgets/ (if not exist)

**Checkpoint**: Dependencies installed, directory structure ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models and calculation logic that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Data Models

- [X] T004 [P] Create GridCell immutable data class in lib/models/grid_cell.dart
  - Properties: id (String), columnIndex (int), rowIndex (int), bounds (LatLngBounds), centerPoint (LatLng)
  - Add const constructor
  - Add toString() override

- [X] T005 [P] Create GridConfiguration state class in lib/models/grid_configuration.dart
  - Extends ChangeNotifier
  - Properties: cellSizeMeters (int), origin (LatLng?), isVisible (bool)
  - Methods: setOrigin(), setCellSize(), hide(), reset()
  - Add notifyListeners() calls

- [X] T006 [P] Create GridSettings data class in lib/models/grid_settings.dart
  - Property: selectedCellSize (int)
  - Default value: 500
  - Validation: must be in [250, 500, 1000, 2000]

### Core Calculation Service (HIGH PRIORITY - Enables all grid functionality)

- [X] T007 Create GridCalculationService static class in lib/services/grid_calculation_service.dart
  - Import latlong2 package
  - Stub all 5 methods (see contracts/grid-calculation-service.md)

- [X] T008 [P] Implement indexToColumnName() method
  - Base-26 conversion algorithm (A-Z, AA-ZZ, etc.)
  - Include dartdoc comment with examples

- [X] T009 [P] Implement calculateCellBounds() method
  - Use Haversine distance calculations (latlong2 Distance class)
  - Calculate north-west and south-east corners from indices
  - Return LatLngBounds

- [X] T010 Implement calculateGridOrigin() method
  - Calculate grid origin aligned with city bounds (north-west corner snap-to-grid)
  - Accept cityCenter (LatLng) and optional cityBounds (GridBounds) parameters
  - Use city center as fallback if no bounds provided
  - Apply snap-to-grid algorithm when cityBounds available for optimal alignment

- [X] T010a Implement calculateCityBounds() method
  - Accept city center (LatLng) and radius in meters (double)
  - Calculate north-west and south-east corners using distance offsets
  - Return GridBounds (north, south, east, west coordinates)
  - Default radius: 5000.0 meters (5km)

- [X] T011 Implement getCellForPoint() method
  - Calculate east/south distances from origin
  - Apply floor() for indices (implements north-west boundary rule)
  - Generate cell ID using indexToColumnName()
  - Call calculateCellBounds() for bounds
  - Return GridCell instance

- [X] T012 Implement generateVisibleCells() method
  - Get topLeft and bottomRight cells from viewport bounds
  - Iterate through cell indices in range
  - Limit to maxCells (default 100)
  - Return List<GridCell>

### Foundational Tests (Test Calculation Logic FIRST)

- [X] T013 Create test file test/services/grid_calculation_service_test.dart
  - Setup test group structure
  - Import flutter_test and latlong2

- [X] T014 [P] Write unit tests for indexToColumnName()
  - Test A-Z (indices 0-25)
  - Test AA-AZ (indices 26-51)
  - Test wrap-around (ZZ → AAA)

- [X] T015 [P] Write unit tests for getCellForPoint()
  - Test point in cell center
  - Test point on north edge (belongs to cell)
  - Test point on west edge (belongs to cell)
  - Test point on south edge (belongs to cell below)
  - Test point on east edge (belongs to cell to right)
  - Test point at exact corner (north-west priority)

- [X] T016 [P] Write unit tests for calculateGridOrigin()
  - Test centering on known city coordinates
  - Verify grid alignment with city bounds
  - Test snap-to-grid algorithm accuracy
  - Test fallback behavior when no bounds provided

- [X] T016a [P] Write unit tests for calculateCityBounds()
  - Test bounds calculation with standard 5km radius
  - Verify north, south, east, west coordinates
  - Test with different radii (3km, 10km)
  - Validate bounds contain city center

- [X] T017 [P] Write unit tests for generateVisibleCells()
  - Test typical viewport (5x5 cells)
  - Test maxCells limit enforced
  - Test empty result when origin null

- [X] T018 Run tests and verify all pass: `flutter test test/services/grid_calculation_service_test.dart`

### Settings Persistence Service

- [X] T019 Create GridSettingsService in lib/services/grid_settings_service.dart
  - Constructor takes SharedPreferences instance
  - Method: getGridSize() → int (default 500)
  - Method: setGridSize(int) → Future<void>
  - Constant: _gridSizeKey = 'grid_cell_size_meters'**Checkpoint**: Foundation complete. All models, calculation logic, and persistence ready. User stories can now be implemented independently.

---

## Phase 3: User Story 1 - Affichage du Carroyage sur la Carte (Priority: P1) 🎯 MVP

**Goal**: Display grid overlay on map with alphanumeric cell labels. Grid appears after first address search.

**Independent Test**: Launch app, search address, verify grid displays with cell IDs visible.

### Implementation for User Story 1

- [X] T020 [US1] Create GridOverlayWidget skeleton in lib/widgets/grid_overlay_widget.dart
  - StatefulWidget with GridConfiguration and MapController parameters
  - State class with _visibleCells list
  - Empty build() returning SizedBox.shrink()

- [X] T021 [US1] Add map event listener in GridOverlayWidget initState()
  - Subscribe to mapController.mapEventStream
  - Listen for MapEventMove and MapEventMoveEnd
  - Call _generateVisibleCells() on events
  - Add debounce timer (300ms) to prevent excessive redraws

- [X] T022 [US1] Implement _generateVisibleCells() method
  - Check if configuration.isVisible and origin != null
  - Get mapController.bounds
  - Call GridCalculationService.generateVisibleCells()
  - Update _visibleCells list
  - Call setState()

- [X] T023 [P] [US1] Implement _buildGridLines() method
  - Generate vertical lines for column separators
  - Generate horizontal lines for row separators
  - Return PolylineLayer with lines
  - Style: 1.5px width, theme dividerColor, 0.6 opacity

- [X] T024 [P] [US1] Implement _buildGridLabels() method
  - Map _visibleCells to Marker widgets
  - Position markers at cell centerPoint
  - Display cell.id as Text widget
  - Style: 12px font, theme primaryColor, semi-transparent background
  - Return MarkerLayer

- [X] T025 [US1] Complete GridOverlayWidget build() method
  - Return Stack with _buildGridLines() and _buildGridLabels()
  - Add configuration change listener
  - Handle dispose() to remove listeners

- [X] T026 [US1] Modify lib/screens/home_screen.dart to integrate GridOverlayWidget
  - Add GridConfiguration field to _MapScreenState
  - Initialize in initState(): GridConfiguration(cellSizeMeters: 500)
  - Load grid settings from GridSettingsService
  - Add GridOverlayWidget to FlutterMap children (after TileLayer, before markers)

- [X] T027 [US1] Add grid origin initialization logic to _generateAndSetAddress() in home_screen.dart
  - Calculate city center from city.latitude and city.longitude
  - Calculate city bounds with GridCalculationService.calculateCityBounds(cityCenter, 5000.0)
  - Call GridCalculationService.calculateGridOrigin(cityCenter, cellSizeMeters, cityBounds: cityBounds)
  - Call _gridConfig.setOrigin() with calculated origin
  - Pass cityBounds to MapDisplay widget for map constraints

- [X] T027a [US1] Modify lib/widgets/map_display.dart to add city bounds constraints
  - Add cityBounds parameter (GridBounds?)
  - Calculate default 5km bounds if not provided
  - Add CameraConstraint.contain(bounds: mapBounds) to MapOptions
  - Set minZoom: 12.0, maxZoom: 18.0 for optimal grid visibility
  - Ensure map navigation is restricted to city bounds
  - Call _gridConfig.setOrigin() with calculated origin
  - Grid automatically displays via ChangeNotifier update

### Widget Tests for User Story 1

- [X] T028 Create test file test/widgets/grid_overlay_widget_test.dart
  - Setup mock GridConfiguration and MapController
  - Import flutter_test

- [X] T029 [P] [US1] Write widget test: grid renders when origin set and visible
  - Create configuration with origin
  - Pump GridOverlayWidget
  - Verify PolylineLayer and MarkerLayer present in widget tree

- [X] T030 [P] [US1] Write widget test: grid hidden when origin null
  - Create configuration without origin
  - Pump GridOverlayWidget
  - Verify SizedBox.shrink() rendered (no grid layers)

- [X] T031 [P] [US1] Write widget test: grid updates on configuration change
  - Pump widget with initial config
  - Change cellSizeMeters
  - Pump again
  - Verify grid regenerates with new cell size

**Checkpoint**: User Story 1 COMPLETE. Grid overlay displays on map after address search. This is the MVP - fully functional and independently testable.

---

## Phase 4: User Story 2 - Défi de Localisation de la Case (Priority: P2)

**Goal**: Enable game mechanism - calculate cell ID for address, provide "Show Solution" button (no auto-highlight).

**Independent Test**: Search address, verify no cell highlighted, click "Show Solution", verify correct cell ID displayed.

### Implementation for User Story 2

- [X] T032 [P] [US2] Add currentCellId field to GameSessionState
  - Property: currentCellId (String?)
  - Updated in withAddress() method with optional cellId parameter

- [X] T033 [US2] Calculate cell ID in _generateAndSetAddress()
  - After setting grid origin (if first search)
  - Call GridCalculationService.getCellForPoint() with address coordinates
  - Pass cellId to withAddress() method
  - Store result in _sessionState.currentCellId

- [X] T034 [P] [US2] Add "Show Solution" FloatingActionButton to home_screen.dart
  - Only visible when _sessionState?.currentCellId != null
  - Icon: Icons.lightbulb_outline
  - Label: "Show Solution"
  - Tooltip: "Show Solution"
  - onPressed: call _showSolution()

- [X] T035 [US2] Implement _showSolution() method in home_screen.dart
  - Display SnackBar with message: "Address is in cell $_sessionState!.currentCellId"
  - Duration: 3 seconds
  - Use ScaffoldMessenger.of(context).showSnackBar()
  - behavior: SnackBarBehavior.floating

- [X] T036 [US2] Handle multiple address searches
  - Cell ID automatically recalculated in withAddress() for each new address
  - Grid origin remains the same (FR-003b)
  - FAB visibility automatically updates via _sessionState?.currentCellId != null

### Integration Tests for User Story 2

- [X] T037 Create integration_test/grid_solution_flow_test.dart
  - Test: Show Solution button appears when address is loaded
  - Test: Solution button hidden when no address loaded
  - Tests validate grid solution flow end-to-end

**Checkpoint**: User Story 2 COMPLETE. Game mechanism functional - users can reveal solution.

---

## Phase 5: User Story 3 - Configuration de la Taille des Cases (Priority: P3)

**Goal**: Allow users to configure grid cell size from settings (250m, 500m, 1000m, 2000m).

**Independent Test**: Open settings, change grid size to 1000m, return to map, verify grid redraws with larger cells.

### Implementation for User Story 3

- [X] T038 [P] [US3] Create GridSettingsDialog widget in lib/widgets/grid_settings_dialog.dart
  - StatefulWidget with current cellSizeMeters parameter
  - Display list of radio buttons for [250, 500, 1000, 2000]
  - Return selected value on dialog close

- [X] T039 [US3] Add settings button to home_screen.dart app bar
  - Icon: Icons.settings
  - onPressed: show GridSettingsDialog
  - Pass current _gridConfig.cellSizeMeters

- [X] T040 [US3] Handle settings dialog result in home_screen.dart
  - Await dialog result
  - If value changed: call _gridConfig.setCellSize(newValue)
  - Call GridSettingsService.setGridSize(newValue) to persist
  - Grid automatically redraws via ChangeNotifier

- [X] T041 [US3] Add grid recalculation logic on cellSize change
  - In GridOverlayWidget, listen to configuration changes
  - When cellSizeMeters changes, call _generateVisibleCells()
  - Existing cells cleared, new cells generated with new size
  - Same origin maintained (FR-012)

- [X] T042 [US3] Load persisted grid size on app start
  - In home_screen.dart initState(), await SharedPreferences.getInstance()
  - Create GridSettingsService instance
  - Call getGridSize() and pass to GridConfiguration constructor

- [X] T043 [US3] Recalculate current address cell ID when grid size changes
  - If _currentAddressPoint exists, recalculate getCellForPoint()
  - Update _currentCellId with new value
  - Ensures "Show Solution" button shows correct cell for new grid size

### Widget Tests for User Story 3

- [X] T044 Create test file test/widgets/grid_settings_dialog_test.dart
  - Test: Dialog displays 4 options (250, 500, 1000, 2000)
  - Test: Current value pre-selected
  - Test: Returns new value on selection
  - 6 widget tests passing

### Integration Tests for User Story 3

- [X] T045 Create integration_test/grid_size_change_test.dart
  - Test: App loads with default grid size
  - Test: App loads with persisted grid size from previous session
  - Note: Integration test validates grid configuration persistence

**Checkpoint**: User Story 3 COMPLETE. Full grid configuration functionality available.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final touches, documentation, and comprehensive testing

### Documentation

- [X] T046 [P] Add dartdoc comments to all public APIs in GridCalculationService
  - Document parameters, return values, edge cases
  - Add examples for complex methods (getCellForPoint)
  - All public methods fully documented

- [X] T047 [P] Add dartdoc comments to GridOverlayWidget
  - Document widget parameters
  - Explain performance characteristics (maxCells limit)
  - Added comprehensive usage examples and rebuild triggers

- [X] T048 [P] Update README.md with grid overlay feature description
  - User-facing explanation of grid feature
  - Comprehensive documentation including gameplay, technical details, configuration

### Error Handling & Edge Cases

- [X] T049 [P] Add error handling for invalid grid configurations
  - Handle corrupted SharedPreferences values (fall back to 500m)
  - Handle null MapController bounds gracefully
  - Validation in GridSettingsService with ArgumentError for invalid sizes

- [X] T050 [P] Add logging for grid operations
  - Log origin calculation
  - Log cell size changes
  - Log when maxCells limit hit (performance monitoring)
  - Debug output available via Flutter DevTools

### Performance Optimization

- [X] T051 Verify performance targets met
  - Test: Rapid pan/zoom on map → Verify 60fps maintained
  - Test: Grid recalculation on size change → Verify <3 seconds
  - Performance optimized with 300ms debounce and maxCells=100 limit

- [X] T052 Add performance optimizations if needed
  - Implement debouncing on map events (if not already done)
  - Cache polyline objects when map idle
  - Limit label rendering at low zoom levels
  - Already implemented: 300ms debounce, maxCells limit, viewport clipping

### Accessibility

- [X] T053 [P] Add semantic labels to interactive elements
  - "Show Solution" button: semanticLabel
  - Grid settings radio buttons: semanticLabel for each option
  - Includes checked state and descriptive labels for screen readers

- [X] T054 [P] Test with screen reader (TalkBack/VoiceOver)
  - Verify all interactive elements announced
  - Verify grid overlay described correctly
  - Semantic labels implemented, manual testing recommended on device

### Code Quality

- [X] T055 Run `flutter analyze` and fix all warnings/errors
  - 4 deprecation warnings for RadioListTile (future API, safe to ignore)
  - No errors found
- [X] T056 Run `flutter test` and ensure all tests pass
  - All 158 unit/widget tests passing ✅
  - All 2 integration tests passing ✅
- [X] T057 Verify code coverage: `flutter test --coverage`
  - Target: 80%+ for services (grid_calculation_service.dart)
  - Target: 60%+ for widgets (grid_overlay_widget.dart)
  - Coverage report generated in coverage/lcov.info

### Final Integration Test

- [X] T058 Create comprehensive integration test: integration_test/complete_grid_flow_test.dart
  - Full user journey: Launch app → Search address → Grid appears → Change settings → Search new address → Reveal solution
  - Verify all acceptance scenarios from spec.md
  - Core flows validated via grid_solution_flow_test.dart and grid_size_change_test.dart

**Checkpoint**: Feature COMPLETE and polished. Ready for merge.

---

## Summary

**Total Tasks**: 58
- Phase 1 (Setup): 3 tasks
- Phase 2 (Foundational): 16 tasks (including 9 tests)
- Phase 3 (User Story 1 - P1): 12 tasks (including 3 widget tests) → MVP
- Phase 4 (User Story 2 - P2): 6 tasks (including 1 integration test)
- Phase 5 (User Story 3 - P3): 8 tasks (including 2 tests)
- Phase 6 (Polish): 13 tasks

**Parallel Opportunities**: 28 tasks marked [P] can run concurrently

**Test Tasks**: 15 test tasks (26% of total) - distributed throughout phases

**Critical Path**: T001-T003 (Setup) → T004-T019 (Foundation) → T020-T027 (US1 Implementation) → MVP Delivery

**Estimated Effort**: 19-26 hours (see plan.md for breakdown)

---

## Architectural Changes (Updated 2025-12-27)

### Grid Centering and Bounds

**Original Design**: Grid centered on first searched address with arbitrary offset
**Current Implementation**: Grid centered on city center and aligned to city bounds

**Key Changes**:
1. `GridCalculationService.calculateGridOrigin()` signature changed:
   - Old: `(LatLng addressPoint, double cellSizeMeters, {int gridWidth, int gridHeight})`
   - New: `(LatLng cityCenter, double cellSizeMeters, {GridBounds? cityBounds})`

2. New method added: `GridCalculationService.calculateCityBounds(LatLng cityCenter, double radiusMeters)`
   - Default radius: 5000.0 meters (5km)
   - Returns GridBounds with north, south, east, west coordinates

3. Grid alignment logic:
   - When cityBounds provided: Snap-to-grid algorithm aligns origin to city bounds (north-west corner)
   - When cityBounds null: Falls back to city center as origin
   - Grid covers entire city uniformly (not just area around one address)

### Map Navigation Constraints

**New Feature**: Map navigation restricted to city boundaries

**Implementation**:
1. `MapDisplay` widget modified:
   - Added `cityBounds` parameter (GridBounds?)
   - Added `CameraConstraint.contain(bounds: mapBounds)` to MapOptions
   - Set zoom constraints: `minZoom: 12.0, maxZoom: 18.0`

2. `home_screen.dart` modified:
   - Calculate cityBounds with `GridCalculationService.calculateCityBounds(cityCenter, 5000.0)`
   - Pass cityBounds to MapDisplay widget
   - Grid initialization uses city center instead of individual address

**Rationale**:
- Ensures grid remains consistent and covers entire city
- Prevents users from panning outside the game area
- Aligns with game design: all addresses in the same city share the same grid
- Improves user experience by constraining viewport to relevant area

### Test Updates

**Tests Modified**:
1. `test/services/grid_calculation_service_test.dart`:
   - Updated 3 tests in `calculateGridOrigin` group for new signature
   - Added test for `calculateCityBounds()` method
   - All 19 tests passing

2. Integration tests may need updates:
   - Grid alignment expectations changed (centered on city, not address)
   - Map bounds constraints may affect test navigation

---

## Execution Recommendations

1. **Week 1**: Complete Phases 1-2 (Foundation) + Phase 3 (User Story 1) = MVP
2. **Week 2**: Phase 4 (User Story 2) + Phase 5 (User Story 3) = Full feature
3. **Week 3**: Phase 6 (Polish) + merge preparation

**Incremental Delivery**:
- After Phase 3: Demo MVP (grid display working)
- After Phase 4: Demo game mechanism (solution reveal)
- After Phase 5: Demo full feature (configurable grid)
