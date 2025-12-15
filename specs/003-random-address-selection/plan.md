# Implementation Plan: Random Address Selection for Location Game

**Branch**: `003-random-address-selection` | **Date**: 2025-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-random-address-selection/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement random address selection within a selected city for a location-finding game. After city selection, the system generates random coordinates within the city's bounding box, uses reverse geocoding (API Adresse) to obtain a real address, and displays it as text only (not marked on map). Users press "Start Search" to zoom to their current location at street-level and begin finding the hidden address. Minimum 5 addresses required per city for game eligibility. Location data handled transiently (no storage) for privacy.

## Technical Context

**Language/Version**: Dart 3.10.4+ / Flutter SDK 3.x
**Primary Dependencies**: flutter_map ^8.2.2, latlong2 ^0.9.0, http ^1.2.0, geolocator (NEW), permission_handler (NEW)
**Storage**: N/A (stateless game session, no persistence required)
**Testing**: flutter_test (unit/widget), integration_test (E2E flows), golden tests for UI states
**Target Platform**: iOS 15+ / Android 8.0+ (mobile cross-platform)
**Project Type**: mobile (Flutter feature-first architecture)
**Performance Goals**: <2s address generation (SC-001), <1s location zoom (SC-007), 60fps UI, 99% address uniqueness (SC-002)
**Constraints**: Privacy-first (no location storage - FR-018), offline graceful degradation, min 5 addresses per city (FR-019)
**Scale/Scope**: Single-screen feature extension, ~3-5 new models, 1 service extension, 2-3 widget updates, 15-20 unit tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Core Principles Assessment

**I. Code Quality & Maintainability**: ✅ PASS
- Feature follows existing feature-first architecture (models/, services/, screens/, widgets/)
- Will comply with flutter_lints and pass `flutter analyze`
- Immutable models with const constructors planned
- Null safety maintained throughout
- Public APIs will have dartdoc comments

**II. Test-First Development**: ✅ PASS
- TDD cycle planned: write tests → implement → verify
- Target coverage: 80%+ business logic, 60%+ widgets
- Unit tests for: RandomAddressService, address validation, coordinate generation
- Widget tests for: address display, button states, error states
- Integration tests for: full game flow (city → address → start search → zoom)

**III. User Experience Consistency**: ✅ PASS
- Material Design 3 compliance (ElevatedButton for "Start Search", Card for address display)
- Responsive design (address text wraps on small screens - FR-012)
- Accessibility: semantic labels for button, address text, screen reader support
- Loading states: progress indicator during address generation
- Error handling: user-friendly messages for API failures, location issues

**IV. Performance & Efficiency**: ✅ PASS
- Performance targets documented: 2s address gen, 1s zoom, 60fps
- Lazy evaluation: address generated only after city selection
- Proper disposal: GeolocatorService listeners, HTTP client cleanup
- Memory efficient: transient location data (no storage)
- Network efficiency: single reverse geocoding call, existing API client reuse

**Quality Gates**:
1. ✅ Static Analysis: Will pass flutter analyze (no new warnings)
2. ✅ Test Execution: Comprehensive test suite planned (15-20 tests minimum)
3. ✅ Code Review: Standard PR review process
4. ✅ Performance Check: DevTools profiling for frame rate, memory leaks
5. ✅ Constitution Compliance: All principles I-IV satisfied

**Complex Feature Gate**: ⚠️ EVALUATION NEEDED
- **New Dependencies**: geolocator, permission_handler (location services)
- **Justification**: Required for FR-014 (zoom to user location) and FR-015 (permission handling)
- **ADR Status**: Document in research.md - evaluate geolocator vs alternatives
- **Performance Benchmarks**: Verify location acquisition <1s on mid-range devices

**GATE STATUS**: ✅ CONDITIONAL PASS - Proceed to Phase 0 research to document ADR for location dependencies

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
│   ├── models/
│   │   ├── random_address.dart          # NEW: Random address entity
│   │   ├── address_selection_result.dart # NEW: Result wrapper
│   │   ├── game_session_state.dart      # NEW: Game phase tracking
│   │   ├── city.dart                     # EXISTING: City entity
│   │   └── postal_code.dart              # EXISTING: Postal code value object
│   ├── services/
│   │   ├── geocoding_service.dart        # MODIFY: Add reverse geocoding
│   │   ├── random_address_service.dart   # NEW: Address generation logic
│   │   └── location_service.dart         # NEW: Geolocator wrapper
│   ├── screens/
│   │   └── home_screen.dart              # MODIFY: Integrate game flow
│   ├── widgets/
│   │   ├── address_display.dart          # NEW: Address text display widget
│   │   └── start_search_button.dart      # NEW: Game initiation button
│   └── main.dart                          # EXISTING: Entry point
├── test/
│   ├── models/
│   │   ├── random_address_test.dart      # NEW
│   │   ├── address_selection_result_test.dart # NEW
│   │   └── game_session_state_test.dart  # NEW
│   ├── services/
│   │   ├── geocoding_service_test.dart   # MODIFY: Add reverse geocoding tests
│   │   ├── random_address_service_test.dart # NEW
│   │   └── location_service_test.dart    # NEW
│   └── widgets/
│       ├── address_display_test.dart     # NEW
│       └── start_search_button_test.dart # NEW
├── integration_test/
│   ├── random_address_flow_test.dart     # NEW: Full game flow
│   └── location_permission_test.dart     # NEW: Permission scenarios
└── pubspec.yaml                           # MODIFY: Add geolocator, permission_handler
```

**Structure Decision**: Flutter mobile app with feature-first organization. New feature components integrate into existing architecture:
- **models/**: 3 new immutable entities (RandomAddress, AddressSelectionResult, GameSessionState)
- **services/**: 2 new services + 1 modification (RandomAddressService, LocationService, GeocodingService extension)
- **widgets/**: 2 new stateless/stateful widgets (AddressDisplay, StartSearchButton)
- **screens/**: Modify existing HomeScreen to orchestrate game flow
- **tests/**: Parallel structure for unit/widget/integration tests following test pyramid

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| New dependencies (geolocator, permission_handler) | FR-014 requires user location for map zoom; FR-015/18 require permission handling and privacy compliance | Manual platform channel implementation would require iOS/Android native code, increase maintenance burden, and reduce reliability compared to well-tested community packages |

**ADR Required**: Yes - document rationale for geolocator selection over alternatives (location package, manual implementation) in research.md Phase 0

## Phase 1 Summary

**Completed**: 2025-12-14

### Data Model Design

Created comprehensive data model in [data-model.md](./data-model.md) with 4 entities:

1. **RandomAddress** (7 properties):
   - Core entity representing game target address
   - Properties: streetNumber, streetName, cityName, postcode, latitude, longitude, generatedAt
   - Methods: `toDisplayString()` for UI formatting, `toUniqueKey()` for deduplication, `isInCity()` for validation
   - Immutable with const constructor, equality operators for Set operations

2. **AddressSelectionResult** (wrapper pattern):
   - Success/failure wrapper for address generation
   - Properties: success (bool), address (nullable), error (nullable), attemptedCount
   - Named constructors: `AddressSelectionResult.success()`, `AddressSelectionResult.failure()`
   - Enables explicit error handling per FR-010

3. **GameSessionState** (session tracking):
   - Manages game phase: city selection → address display → search started
   - Properties: currentCity, currentAddress, usedAddresses (Set<String>), hasStartedSearch
   - Methods: `withNewCity()`, `withAddress()`, `withSearchStarted()`, `addUsedAddress()`
   - Ensures address uniqueness per SC-002 via in-memory Set

4. **CityBounds** (helper class):
   - Encapsulates bounding box for coordinate generation
   - Properties: minLat, maxLat, minLon, maxLon
   - Factory: `CityBounds.fromCenter(lat, lon, delta)` with default delta=0.05° (~5.5km)
   - Method: `generateRandomPoint()` using dart:math Random
   - Prevents coordinates outside city boundaries per FR-004

**Design Patterns**:
- Immutability: All entities use `final` fields, `const` constructors
- Value objects: RandomAddress equality based on address components (not coordinates)
- Wrapper pattern: AddressSelectionResult for explicit success/failure
- Builder pattern: GameSessionState copyWith methods for immutable updates
- Factory methods: CityBounds.fromCenter for readable instantiation

### API Contracts

Created reverse geocoding contract in [contracts/geocoding-api.md](./contracts/geocoding-api.md):

- **Endpoint**: `GET https://api-adresse.data.gouv.fr/reverse/`
- **Parameters**: lat, lon, type=housenumber (mandatory)
- **Response**: GeoJSON FeatureCollection with properties mapping to RandomAddress
- **Validation**: type must be 'housenumber', cityName must match selected city
- **Error Handling**: 400 (validation), 429 (rate limit), 500/503 (server errors)
- **Retry Strategy**: Exponential backoff for 429 (1s, 2s, 4s intervals) per FR-007
- **Performance**: p50=150ms, p95=500ms, p99=800ms (based on API benchmarks)
- **Implementation**: Dart code samples with http.Client, JSON parsing, error mapping
- **Testing**: Mock responses for unit tests, validation scenarios, edge cases

### Technology Decisions

From [research.md](./research.md), key technical choices:

1. **Location Services**: geolocator ^11.0.0
   - Rationale: Cross-platform (iOS/Android), permission handling, accuracy control
   - Alternatives: location package (lower maintenance), manual channels (high complexity)
   - Decision: geolocator for feature parity and community support

2. **Reverse Geocoding**: API Adresse with retry
   - Rationale: Free, reliable, French addresses, no API key
   - Strategy: 3 retries with exponential backoff for rate limits (429)
   - Fallback: User-facing error message per FR-010 (no silent failures)

3. **City Bounding Box**: Fixed delta (0.05°) with validation
   - Rationale: Simplicity for Phase 1, deterministic bounds
   - Validation: Address must match city name via `isInCity()` check
   - Future: Consider dynamic bounds based on city size

4. **Address Uniqueness**: In-memory Set<String>
   - Rationale: Session-scoped deduplication, no persistence needed
   - Key format: "CityName|StreetName|StreetNumber"
   - Limitation: Resets on app restart (acceptable for game sessions)

5. **Button State Management**: StatefulWidget
   - Rationale: Local UI state (disabled after press), no global state needed
   - Pattern: Boolean flag `_hasStarted` in widget state
   - Alternative: Provider/Bloc (over-engineering for simple toggle)

### Development Environment

Created [quickstart.md](./quickstart.md) with 7-phase workflow:

1. **Setup & Dependencies**: pubspec.yaml updates, permission config (iOS/Android)
2. **Data Models**: Test-first creation of 4 entities with comprehensive test suites
3. **Services**: Extend GeocodingService, create RandomAddressService and LocationService
4. **UI Widgets**: AddressDisplay and StartSearchButton with widget tests
5. **Integration**: HomeScreen modifications to orchestrate game flow
6. **Integration Tests**: Complete game flow scenarios
7. **Verification**: Test execution, static analysis, device testing, requirements checklist

**Estimated Time**: 6-8 hours (including TDD cycle)
**Test Coverage Target**: 80%+ business logic, 60%+ widgets

### Re-evaluation: Constitution Check

Post-Phase 1 design review of constitution compliance:

**I. Code Quality & Maintainability**: ✅ PASS (unchanged)
- Data model follows immutability patterns
- Service layer has clear separation of concerns
- Public APIs documented in contracts

**II. Test-First Development**: ✅ PASS (unchanged)
- Quickstart enforces TDD workflow
- Mock responses provided in contracts for testing
- Integration test scenarios defined

**III. User Experience Consistency**: ✅ PASS (unchanged)
- Material Design widgets specified (Card for address, ElevatedButton for start)
- Error messages defined in contracts (user-facing language)
- Loading states documented

**IV. Performance & Efficiency**: ✅ PASS (unchanged)
- Performance targets maintained: <2s address gen, <1s zoom
- In-memory Set for O(1) uniqueness checks
- Transient location data (no I/O overhead)

**Complex Feature Gate**: ✅ PASS (justified)
- New dependencies documented with ADRs in research.md
- geolocator selection rationale provided
- No simpler alternative identified

**FINAL GATE STATUS**: ✅ PASS - Proceed to Phase 2 task breakdown (separate `/speckit.tasks` command)

## Next Steps

The planning phase is complete. To proceed with implementation:

1. **Task Breakdown**: Run `/speckit.tasks` command to generate tasks.md
   - Will create sequenced implementation tasks from this plan
   - Tasks organized by user story (P1, P2, P3, P4)
   - Includes dependencies and parallel execution opportunities

2. **Implementation**: Follow [quickstart.md](./quickstart.md) development workflow
   - Start with Phase 1: Setup & Dependencies
   - Follow TDD cycle for each component
   - Verify requirements checklist after each phase

3. **Verification**: Before merging to main
   - Run full test suite: `flutter test && flutter test integration_test`
   - Static analysis: `flutter analyze`
   - Performance profiling: DevTools memory/frame rate check
   - Manual testing on iOS/Android devices

**Agent Handoff**: This plan document provides complete context for implementation. All technical decisions, data models, API contracts, and development workflows are documented and ready for coding phase.
