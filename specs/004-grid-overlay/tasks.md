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

- [ ] T001 Add `shared_preferences: ^2.0.0` to pubspec.yaml dependencies
- [ ] T002 Run `flutter pub get` to install new dependency
- [ ] T003 [P] Create directory structure: lib/models/, lib/services/, lib/widgets/ (if not exist)

**Checkpoint**: Dependencies installed, directory structure ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models and calculation logic that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Data Models

- [ ] T004 [P] Create GridCell immutable data class in lib/models/grid_cell.dart
  - Properties: id (String), columnIndex (int), rowIndex (int), bounds (LatLngBounds), centerPoint (LatLng)
  - Add const constructor
  - Add toString() override

- [ ] T005 [P] Create GridConfiguration state class in lib/models/grid_configuration.dart
  - Extends ChangeNotifier
  - Properties: cellSizeMeters (int), origin (LatLng?), isVisible (bool)
  - Methods: setOrigin(), setCellSize(), hide(), reset()
  - Add notifyListeners() calls

- [ ] T006 [P] Create GridSettings data class in lib/models/grid_settings.dart
  - Property: selectedCellSize (int)
  - Default value: 500
  - Validation: must be in [250, 500, 1000, 2000]

### Core Calculation Service (HIGH PRIORITY - Enables all grid functionality)

- [ ] T007 Create GridCalculationService static class in lib/services/grid_calculation_service.dart
  - Import latlong2 package
  - Stub all 5 methods (see contracts/grid-calculation-service.md)

- [ ] T008 [P] Implement indexToColumnName() method
  - Base-26 conversion algorithm (A-Z, AA-ZZ, etc.)
  - Include dartdoc comment with examples

- [ ] T009 [P] Implement calculateCellBounds() method
  - Use Haversine distance calculations (latlong2 Distance class)
  - Calculate north-west and south-east corners from indices
  - Return LatLngBounds

- [ ] T010 Implement calculateGridOrigin() method
  - Calculate offset west and north from address point
  - Use configurable gridWidth/gridHeight for centering
  - Default to 10x10 grid centering

- [ ] T011 Implement getCellForPoint() method
  - Calculate east/south distances from origin
  - Apply floor() for indices (implements north-west boundary rule)
  - Generate cell ID using indexToColumnName()
  - Call calculateCellBounds() for bounds
  - Return GridCell instance

- [ ] T012 Implement generateVisibleCells() method
  - Get topLeft and bottomRight cells from viewport bounds
  - Iterate through cell indices in range
  - Limit to maxCells (default 100)
  - Return List<GridCell>

### Foundational Tests (Test Calculation Logic FIRST)

- [ ] T013 Create test file test/services/grid_calculation_service_test.dart
  - Setup test group structure
  - Import flutter_test and latlong2

- [ ] T014 [P] Write unit tests for indexToColumnName()
  - Test A-Z (indices 0-25)
  - Test AA-AZ (indices 26-51)
  - Test wrap-around (ZZ → AAA)

- [ ] T015 [P] Write unit tests for getCellForPoint()
  - Test point in cell center
  - Test point on north edge (belongs to cell)
  - Test point on west edge (belongs to cell)
  - Test point on south edge (belongs to cell below)
  - Test point on east edge (belongs to cell to right)
  - Test point at exact corner (north-west priority)

- [ ] T016 [P] Write unit tests for calculateGridOrigin()
  - Test centering on known coordinates
  - Verify offset accuracy (±10m acceptable)
  - Test with different cell sizes

- [ ] T017 [P] Write unit tests for generateVisibleCells()
  - Test typical viewport (5x5 cells)
  - Test maxCells limit enforced
  - Test empty result when origin null

- [ ] T018 Run tests and verify all pass: `flutter test test/services/grid_calculation_service_test.dart`

### Settings Persistence Service

- [ ] T019 Create GridSettingsService in lib/services/grid_settings_service.dart
  - Constructor takes SharedPreferences instance
  - Method: getGridSize() → int (default 500)
  - Method: setGridSize(int) → Future<void>
  - Constant: _gridSizeKey = 'grid_cell_size_meters'

**Checkpoint**: Foundation complete. All models, calculation logic, and persistence ready. User stories can now be implemented independently.

---

## Phase 3: User Story 1 - Affichage du Carroyage sur la Carte (Priority: P1) 🎯 MVP

**Goal**: Display grid overlay on map with alphanumeric cell labels. Grid appears after first address search.

**Independent Test**: Launch app, search address, verify grid displays with cell IDs visible.

### Implementation for User Story 1

- [ ] T020 [P] [US1] Create GridOverlayWidget skeleton in lib/widgets/grid_overlay_widget.dart
  - StatefulWidget with GridConfiguration and MapController parameters
  - State class with _visibleCells list
  - Empty build() returning SizedBox.shrink()

- [ ] T021 [US1] Add map event listener in GridOverlayWidget initState()
  - Subscribe to mapController.mapEventStream
  - Listen for MapEventMove and MapEventMoveEnd
  - Call _generateVisibleCells() on events
  - Add debounce timer (300ms) to prevent excessive redraws

- [ ] T022 [US1] Implement _generateVisibleCells() method
  - Check if configuration.isVisible and origin != null
  - Get mapController.bounds
  - Call GridCalculationService.generateVisibleCells()
  - Update _visibleCells list
  - Call setState()

- [ ] T023 [P] [US1] Implement _buildGridLines() method
  - Generate vertical lines for column separators
  - Generate horizontal lines for row separators
  - Return PolylineLayer with lines
  - Style: 1.5px width, theme dividerColor, 0.6 opacity

- [ ] T024 [P] [US1] Implement _buildGridLabels() method
  - Map _visibleCells to Marker widgets
  - Position markers at cell centerPoint
  - Display cell.id as Text widget
  - Style: 12px font, theme primaryColor, semi-transparent background
  - Return MarkerLayer

- [ ] T025 [US1] Complete GridOverlayWidget build() method
  - Return Stack with _buildGridLines() and _buildGridLabels()
  - Add configuration change listener
  - Handle dispose() to remove listeners

- [ ] T026 [US1] Modify lib/screens/map_screen.dart to integrate GridOverlayWidget
  - Add GridConfiguration field to _MapScreenState
  - Initialize in initState(): GridConfiguration(cellSizeMeters: 500)
  - Load grid settings from GridSettingsService
  - Add GridOverlayWidget to FlutterMap children (after TileLayer, before markers)

- [ ] T027 [US1] Add grid origin initialization logic to _onAddressSearched() in map_screen.dart
  - Check if _gridConfig.origin == null
  - If null, call GridCalculationService.calculateGridOrigin()
  - Call _gridConfig.setOrigin() with calculated origin
  - Grid automatically displays via ChangeNotifier update

### Widget Tests for User Story 1

- [ ] T028 Create test file test/widgets/grid_overlay_widget_test.dart
  - Setup mock GridConfiguration and MapController
  - Import flutter_test

- [ ] T029 [P] [US1] Write widget test: grid renders when origin set and visible
  - Create configuration with origin
  - Pump GridOverlayWidget
  - Verify PolylineLayer and MarkerLayer present in widget tree

- [ ] T030 [P] [US1] Write widget test: grid hidden when origin null
  - Create configuration without origin
  - Pump GridOverlayWidget
  - Verify SizedBox.shrink() rendered (no grid layers)

- [ ] T031 [P] [US1] Write widget test: grid updates on configuration change
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

- [ ] T032 [P] [US2] Add AddressPoint field to map_screen.dart _MapScreenState
  - Property: _currentAddressPoint (AddressPoint?)
  - Updated in _onAddressSearched() after geocoding

- [ ] T033 [US2] Calculate cell ID in _onAddressSearched()
  - After setting grid origin (if first search)
  - Call GridCalculationService.getCellForPoint() with address coordinates
  - Store result in _currentAddressPoint
  - Extract cell.id and save to _currentCellId (String?)

- [ ] T034 [P] [US2] Add "Show Solution" FloatingActionButton to map_screen.dart
  - Only visible when _currentCellId != null
  - Icon: Icons.lightbulb_outline
  - Tooltip: "Show Solution"
  - onPressed: call _showSolution()

- [ ] T035 [US2] Implement _showSolution() method in map_screen.dart
  - Display SnackBar with message: "Address is in cell $_currentCellId"
  - Duration: 3 seconds
  - Use ScaffoldMessenger.of(context).showSnackBar()

- [ ] T036 [US2] Handle multiple address searches
  - Clear previous _currentCellId before new search
  - Recalculate cell ID for new address (using SAME grid origin - FR-003b)
  - Update FAB visibility based on new address presence

### Integration Tests for User Story 2

- [ ] T037 Create integration_test/grid_solution_flow_test.dart
  - Test: Search address → Verify grid displays → Click "Show Solution" → Verify cell ID shown
  - Test: Search second address → Verify grid origin unchanged → New cell ID calculated correctly

**Checkpoint**: User Story 2 COMPLETE. Game mechanism functional - users can reveal solution.

---

## Phase 5: User Story 3 - Configuration de la Taille des Cases (Priority: P3)

**Goal**: Allow users to configure grid cell size from settings (250m, 500m, 1000m, 2000m).

**Independent Test**: Open settings, change grid size to 1000m, return to map, verify grid redraws with larger cells.

### Implementation for User Story 3

- [ ] T038 [P] [US3] Create GridSettingsDialog widget in lib/widgets/grid_settings_dialog.dart
  - StatefulWidget with current cellSizeMeters parameter
  - Display list of radio buttons for [250, 500, 1000, 2000]
  - Return selected value on dialog close

- [ ] T039 [US3] Add settings button to map_screen.dart app bar
  - Icon: Icons.settings
  - onPressed: show GridSettingsDialog
  - Pass current _gridConfig.cellSizeMeters

- [ ] T040 [US3] Handle settings dialog result in map_screen.dart
  - Await dialog result
  - If value changed: call _gridConfig.setCellSize(newValue)
  - Call GridSettingsService.setGridSize(newValue) to persist
  - Grid automatically redraws via ChangeNotifier

- [ ] T041 [US3] Add grid recalculation logic on cellSize change
  - In GridOverlayWidget, listen to configuration changes
  - When cellSizeMeters changes, call _generateVisibleCells()
  - Existing cells cleared, new cells generated with new size
  - Same origin maintained (FR-012)

- [ ] T042 [US3] Load persisted grid size on app start
  - In map_screen.dart initState(), await SharedPreferences.getInstance()
  - Create GridSettingsService instance
  - Call getGridSize() and pass to GridConfiguration constructor

- [ ] T043 [US3] Recalculate current address cell ID when grid size changes
  - If _currentAddressPoint exists, recalculate getCellForPoint()
  - Update _currentCellId with new value
  - Ensures "Show Solution" button shows correct cell for new grid size

### Widget Tests for User Story 3

- [ ] T044 Create test file test/widgets/grid_settings_dialog_test.dart
  - Test: Dialog displays 4 options (250, 500, 1000, 2000)
  - Test: Current value pre-selected
  - Test: Returns new value on selection

### Integration Tests for User Story 3

- [ ] T045 Create integration_test/grid_size_change_test.dart
  - Test: Open settings → Change to 1000m → Return to map → Verify cells larger
  - Test: Restart app → Verify 1000m setting persisted
  - Test: Change size with address searched → Verify cell ID updated

**Checkpoint**: User Story 3 COMPLETE. Full grid configuration functionality available.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final touches, documentation, and comprehensive testing

### Documentation

- [ ] T046 [P] Add dartdoc comments to all public APIs in GridCalculationService
  - Document parameters, return values, edge cases
  - Add examples for complex methods (getCellForPoint)

- [ ] T047 [P] Add dartdoc comments to GridOverlayWidget
  - Document widget parameters
  - Explain performance characteristics (maxCells limit)

- [ ] T048 [P] Update README.md with grid overlay feature description
  - User-facing explanation of grid feature
  - Screenshots showing grid overlay

### Error Handling & Edge Cases

- [ ] T049 [P] Add error handling for invalid grid configurations
  - Handle corrupted SharedPreferences values (fall back to 500m)
  - Handle null MapController bounds gracefully

- [ ] T050 [P] Add logging for grid operations
  - Log origin calculation
  - Log cell size changes
  - Log when maxCells limit hit (performance monitoring)

### Performance Optimization

- [ ] T051 Verify performance targets met
  - Test: Rapid pan/zoom on map → Verify 60fps maintained
  - Test: Grid recalculation on size change → Verify <3 seconds
  - Profile using Flutter DevTools if issues detected

- [ ] T052 Add performance optimizations if needed
  - Implement debouncing on map events (if not already done)
  - Cache polyline objects when map idle
  - Limit label rendering at low zoom levels

### Accessibility

- [ ] T053 [P] Add semantic labels to interactive elements
  - "Show Solution" button: semanticLabel
  - Grid settings radio buttons: semanticLabel for each option

- [ ] T054 [P] Test with screen reader (TalkBack/VoiceOver)
  - Verify all interactive elements announced
  - Verify grid overlay described correctly

### Code Quality

- [ ] T055 Run `flutter analyze` and fix all warnings/errors
- [ ] T056 Run `flutter test` and ensure all tests pass
- [ ] T057 Verify code coverage: `flutter test --coverage`
  - Target: 80%+ for services (grid_calculation_service.dart)
  - Target: 60%+ for widgets (grid_overlay_widget.dart)

### Final Integration Test

- [ ] T058 Create comprehensive integration test: integration_test/complete_grid_flow_test.dart
  - Full user journey: Launch app → Search address → Grid appears → Change settings → Search new address → Reveal solution
  - Verify all acceptance scenarios from spec.md

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

## Execution Recommendations

1. **Week 1**: Complete Phases 1-2 (Foundation) + Phase 3 (User Story 1) = MVP
2. **Week 2**: Phase 4 (User Story 2) + Phase 5 (User Story 3) = Full feature
3. **Week 3**: Phase 6 (Polish) + merge preparation

**Incremental Delivery**:
- After Phase 3: Demo MVP (grid display working)
- After Phase 4: Demo game mechanism (solution reveal)
- After Phase 5: Demo full feature (configurable grid)
