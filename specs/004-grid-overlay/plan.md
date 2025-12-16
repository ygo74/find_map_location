# Implementation Plan: Carte avec Carroyage Alphanumérique

**Branch**: `004-grid-overlay` | **Date**: 2025-12-16 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-grid-overlay/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a configurable grid overlay system for OpenStreetMap that divides the map into square cells with alphanumeric identifiers (letters for columns, numbers for rows). The system calculates grid origin dynamically centered on the first searched address, maintains fixed grid positioning for subsequent searches, and provides a game mechanism where users guess which cell contains an address (with optional solution reveal). Grid cell size is configurable via predefined values (250m, 500m, 1000m, 2000m) with 500m default. Technical approach uses existing flutter_map infrastructure with custom overlay painter for grid rendering and coordinate-to-cell calculation logic.

## Technical Context

**Language/Version**: Dart 3.10.4+ / Flutter 3.x (Flutter SDK from pubspec.yaml: ^3.10.4)

**Primary Dependencies**:
- `flutter_map` (^7.0.0) - Existing OpenStreetMap integration; will render grid overlay
- `latlong2` (^0.9.0) - Geographic coordinate handling for grid calculations
- `shared_preferences` (^2.0.0) - Persist user's grid size preference
- State Management: Built-in `StatefulWidget` with potential `ChangeNotifier` for grid configuration

**Storage**:
- `shared_preferences` - Persist grid cell size setting (250m/500m/1000m/2000m)
- No database required; grid state held in memory during session

**Testing**:
- `flutter_test` (SDK) - Unit tests for grid calculation logic (lat/lon to cell ID)
- Widget tests for grid overlay rendering and settings UI
- `integration_test` (SDK) - End-to-end test: change grid size, verify overlay updates
- Mock grid configurations for deterministic testing

**Target Platform**: iOS 12+ and Android API 21+ (mobile-first, cross-platform)

**Project Type**: Mobile (Flutter application feature enhancement)

**Performance Goals**:
- 60fps during map pan/zoom with grid overlay visible
- <100ms grid recalculation when changing cell size
- <3 seconds to redraw full grid after size change (FR-012, SC-003)
- Grid rendering optimized to only draw visible cells

**Constraints**:
- Grid overlay must not block map interaction (touch-through transparent areas)
- Maximum ~100 visible cells at once (performance ceiling for rendering)
- Grid labels must remain readable at zoom levels 12-16
- North-west priority rule for addresses on cell boundaries (FR-005a)

**Scale/Scope**:
- Add 4-6 new source files (grid model, grid painter, grid service, settings screen)
- Grid calculations pure functions (easily testable)
- Settings UI: single dropdown/selector for 4 predefined sizes
- "Show Solution" button integrated into existing address search UI

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Code Quality & Maintainability ✅ PASS
- **Static Analysis**: `flutter analyze` will be run before merge
- **Linting**: Existing `flutter_lints` ^6.0.0 applies to new code
- **Architecture**: Grid feature follows existing structure (models/, services/, widgets/)
- **Immutability**: GridCell and GridConfig models will use immutable classes with const constructors
- **Null Safety**: Dart 3.10.4+ enforces null safety throughout
- **Documentation**: All public grid APIs (calculateCellId, GridOverlay widget) will have dartdoc comments

**Status**: ✅ No violations. Grid overlay integrates cleanly with existing architecture.

### Principle II: Test-First Development ✅ PASS
- **TDD Cycle**: Unit tests for grid calculations will be written first
- **Coverage Gates**: 80% logic coverage achievable for pure grid calculation functions; 60% UI for GridOverlay widget
- **Test Pyramid**:
  - Unit: Grid coordinate calculations, cell ID generation, north-west boundary rule
  - Widget: GridOverlay rendering, settings dropdown
  - Integration: Full flow (search address → grid displayed → change size → solution reveal)
- **Widget Testing**: GridOverlay custom painter and settings UI will have widget tests
- **Golden Tests**: Grid overlay visual regression tests recommended for grid rendering accuracy
- **Integration Tests**: User workflow test covering search, grid display, and solution reveal

**Status**: ✅ No violations. Grid calculation logic is highly testable; painter widget follows Flutter testing patterns.

### Principle III: User Experience Consistency ✅ PASS
- **Material Design**: Settings UI will use Material dropdown/list; "Show Solution" button follows MD3
- **Responsive Design**: Grid adapts to all screen sizes; labels scale with zoom level
- **Platform Conventions**: Grid overlay respects map gesture handling on both platforms
- **Accessibility**: "Show Solution" button has semantic label; grid size selector accessible
- **Theme System**: Grid line colors and text use theme colors (primary, onSurface)
- **Loading States**: Grid recalculation shows brief loading indicator (< 100ms so may not be visible)
- **Error Handling**: Invalid grid configurations prevented by predefined values; no user-facing errors expected

**Status**: ✅ No violations. Grid feature maintains consistency with existing map UI.

### Principle IV: Performance & Efficiency ✅ PASS
- **Build Performance**: Custom painter for grid overlay; rebuilds only on grid config change
- **Frame Rate**: 60fps target maintained; grid overlay uses efficient canvas drawing
- **Memory Management**: Grid state disposed when leaving map screen; no memory leaks
- **Image Optimization**: N/A (grid is vector-based, no images)
- **Bundle Size**: shared_preferences adds ~50KB; negligible impact
- **Startup Time**: No impact on cold start; grid initialized only when map screen active
- **Network Efficiency**: N/A (grid calculations are local; no network calls)

**Status**: ✅ No violations. Grid rendering optimized to draw only visible cells; performance goals achievable.

### Flutter Standards ✅ PASS
- **Dependency Management**: shared_preferences pinned; well-maintained official Flutter plugin
- **State Management**: ChangeNotifier for GridConfig aligns with existing StatefulWidget pattern
- **Platform Integration**: No platform-specific code required; pure Dart/Flutter implementation

**Constitution Compliance Summary**: ✅ ALL GATES PASSED. Feature design fully compliant with constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
src/app/find_map_location/
├── lib/
│   ├── main.dart                        # Existing entry point
│   ├── models/
│   │   ├── grid_cell.dart               # NEW: GridCell data class
│   │   ├── grid_configuration.dart      # NEW: GridConfiguration state (ChangeNotifier)
│   │   └── grid_settings.dart           # NEW: GridSettings (persisted model)
│   ├── services/
│   │   ├── grid_calculation_service.dart  # NEW: Pure calculation functions
│   │   └── grid_settings_service.dart     # NEW: shared_preferences wrapper
│   ├── widgets/
│   │   ├── grid_overlay_widget.dart     # NEW: Grid rendering widget
│   │   └── grid_settings_dialog.dart    # NEW: Settings UI dialog
│   └── screens/
│       ├── home_screen.dart             # Existing (may need minor updates)
│       └── map_screen.dart              # MODIFY: Integrate grid overlay
├── test/
│   ├── models/
│   │   ├── grid_cell_test.dart          # NEW: Unit tests for GridCell
│   │   └── grid_configuration_test.dart # NEW: State management tests
│   ├── services/
│   │   └── grid_calculation_service_test.dart  # NEW: Calculation logic tests (HIGH PRIORITY)
│   └── widgets/
│       └── grid_overlay_widget_test.dart  # NEW: Widget rendering tests
├── integration_test/
│   └── grid_overlay_flow_test.dart      # NEW: End-to-end grid feature test
└── pubspec.yaml                          # MODIFY: Add shared_preferences dependency
```

**Structure Decision**: Flutter mobile single-app architecture. Grid feature adds 6 new source files (3 models, 2 services, 2 widgets) and corresponding test files. Integrates into existing `src/app/find_map_location/` structure following feature-first organization (models/, services/, widgets/, screens/).

**Key Integration Points**:
- `map_screen.dart`: Modified to instantiate GridConfiguration and GridOverlayWidget
- `pubspec.yaml`: Add `shared_preferences: ^2.0.0` dependency
- Existing geocoding service: Used to trigger grid origin calculation on first address search

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No Violations**: All constitution checks passed. No complexity justifications required

---

## Implementation Phases

### Phase 0: Research & Discovery ✅ COMPLETED

**Deliverables**:
- [x] `research.md`: Technical decisions documented
- [x] All [NEEDS CLARIFICATION] items resolved
- [x] Technology choices validated

**Key Findings**:
- Haversine formula for coordinate-to-meter conversion
- flutter_map PolylineLayer for grid rendering
- Excel-style base-26 naming for columns
- North-west boundary rule for deterministic cell assignment
- shared_preferences for settings persistence

---

### Phase 1: Design & Contracts ✅ COMPLETED

**Deliverables**:
- [x] `data-model.md`: Entity definitions (GridCell, GridConfiguration, AddressPoint, GridSettings)
- [x] `contracts/grid-calculation-service.md`: Calculation API contract
- [x] `contracts/grid-overlay-widget.md`: UI component contract
- [x] `quickstart.md`: Developer implementation guide
- [x] Constitution re-check: All gates still passed

**Key Decisions**:
- GridConfiguration uses ChangeNotifier for reactive UI updates
- GridCell immutable value objects
- Pure function design for GridCalculationService (highly testable)
- Max 100 visible cells performance limit

---

### Phase 2: Task Breakdown → NEXT STEP

**Command**: `/speckit.tasks` (run this next)

**Expected Deliverables**:
- `tasks.md`: Ordered implementation tasks with test-first approach
- Task categories: Setup, Core Logic, UI, Integration, Testing, Documentation
- Each task includes acceptance criteria and test requirements

**Blocked Until**: This plan is reviewed and approved

---

## Summary & Next Steps

### Implementation Ready? ✅ YES

**Confidence Level**: High

All technical unknowns resolved. Design validated against constitution. Contracts define clear API boundaries. Implementation path straightforward with existing flutter_map infrastructure.

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Grid rendering performance | Low | Culling + maxCells limit proven effective |
| Coordinate calculation accuracy | Low | Haversine well-tested; acceptable margin of error |
| User confusion on cell naming | Low | Excel-style familiar; documentation clear |

### Development Estimates

**Complexity**: Medium (pure logic + UI integration)

**Estimated Effort** (for experienced Flutter developer):
- Core calculation logic: 4-6 hours (includes tests)
- Grid overlay widget: 6-8 hours (rendering + tests)
- Settings integration: 2-3 hours (UI + persistence)
- Integration & polish: 3-4 hours (map screen updates, solution button)
- Testing & documentation: 4-5 hours (comprehensive test suite)

**Total**: 19-26 hours (~3-4 days)

**Critical Path**: GridCalculationService → GridOverlayWidget → Map Screen Integration

### Prerequisites for Implementation

1. ✅ Feature branch created (`004-grid-overlay`)
2. ✅ Specification clarified (no ambiguities remain)
3. ✅ Constitution compliance verified
4. ⏳ Plan reviewed and approved
5. ⏳ Tasks generated (`/speckit.tasks`)

### Success Criteria Alignment

All functional requirements (FR-001 through FR-012) covered in design:
- Grid display with alphanumeric IDs → GridOverlayWidget + GridCalculationService
- Dynamic origin calculation → calculateGridOrigin() on first search
- Fixed grid for session → Origin persisted in GridConfiguration (not in storage)
- Configurable sizes → GridSettings + GridSettingsDialog
- No auto-highlight → Explicit "Show Solution" button
- North-west boundary rule → Implemented in getCellForPoint()

### Approval Checklist

Before proceeding to task generation:
- [ ] Review `research.md` for technical soundness
- [ ] Review `data-model.md` for entity completeness
- [ ] Review `contracts/` for API clarity
- [ ] Confirm constitution compliance acceptable
- [ ] Verify file structure matches project conventions

**Once approved**: Run `/speckit.tasks` to generate ordered implementation tasks.
