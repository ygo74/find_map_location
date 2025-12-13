# Tasks: Postal Code Map Viewer

**Feature**: 001-postal-code-map
**Input**: Design documents from `/specs/001-postal-code-map/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/geocoding-api.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**Tests**: Tests are included per the quickstart.md TDD approach.

---

## Format: `- [ ] [ID] [P?] [Story?] Description`

- **Checkbox**: Always starts with `- [ ]`
- **[ID]**: Task ID (T001, T002, etc.)
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3) - only for user story phases
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create directory structure lib/models/, lib/services/, lib/widgets/, lib/screens/, test/models/, test/services/, test/widgets/, test/integration_test/
- [X] T002 Update pubspec.yaml with dependencies: flutter_map ^7.0.0, latlong2 ^0.9.0, http ^1.2.0
- [X] T003 [P] Verify analysis_options.yaml includes flutter_lints rules
- [X] T004 Run flutter pub get to install dependencies
- [X] T005 Run flutter analyze to verify no initial issues

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 [P] Define exception classes inline in lib/services/geocoding_service.dart: PostalCodeNotFoundException, NetworkException, ServerException
- [X] T007 [P] Create MapState enum (idle, loading, success, error) in lib/models/map_state.dart (optional - not required for implementation)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Valid Postal Code Entry and Map Display (Priority: P1) 🎯 MVP

**Goal**: Core value proposition - users can enter valid postal codes and see the corresponding city map

**Independent Test**: Enter "75001" → Paris 1st arrondissement map displays at zoom level 13

### Tests for User Story 1 - Write FIRST (ensure they FAIL)

- [X] T009 [P] [US1] Write test for PostalCode validation in test/models/postal_code_test.dart (valid 5-digit, invalid format, empty)
- [X] T010 [P] [US1] Write test for CityLocation.fromJson parsing in test/models/city_location_test.dart (verify coordinate order [lon,lat]→[lat,lon])
- [X] T011 [P] [US1] Write test for GeocodingService success case in test/services/geocoding_service_test.dart using MockClient

### Implementation for User Story 1

- [X] T012 [P] [US1] Implement PostalCode value object in lib/models/postal_code.dart with RegExp validation `^[0-9]{5}$`
- [X] T013 [P] [US1] Implement CityLocation entity in lib/models/city_location.dart with fromJson factory (swap coordinates)
- [X] T014 [US1] Implement GeocodingService abstract class in lib/services/geocoding_service.dart
- [X] T015 [US1] Implement ApiAdresseGeocodingService in lib/services/geocoding_service.dart with timeout 10s
- [X] T016 [P] [US1] Create MapDisplay widget in lib/widgets/map_display.dart using FlutterMap with zoom 13
- [X] T017 [P] [US1] Create PostalCodeInput widget in lib/widgets/postal_code_input.dart with TextField (5-digit limit, digits only)
- [X] T018 [US1] Create HomeScreen in lib/screens/home_screen.dart with StatefulWidget and _handleSubmit method
- [X] T019 [US1] Update lib/main.dart to use HomeScreen and Material Design 3 theme
- [X] T020 [US1] Add loading state logic with CircularProgressIndicator in HomeScreen
- [X] T021 [US1] Run tests for User Story 1 (T009-T011) - all should PASS

**Checkpoint**: At this point, User Story 1 should be fully functional - enter "75001" and see Paris map

---

## Phase 4: User Story 2 - Invalid Postal Code Format Handling (Priority: P2)

**Goal**: Prevent malformed input processing and provide immediate user feedback

**Independent Test**: Enter "123" or "abcde" → error message displays without attempting map lookup

### Tests for User Story 2 - Write FIRST (ensure they FAIL)

- [X] T022 [P] [US2] Write test for format validation errors in test/widgets/postal_code_input_test.dart (too short, too long, letters)
- [X] T023 [P] [US2] Write widget test for error message display in test/screens/home_screen_test.dart

### Implementation for User Story 2

- [X] T024 [US2] Add empty field validation to _handleSubmit in lib/screens/home_screen.dart (FR-010)
- [X] T025 [US2] Add format validation to _handleSubmit before geocoding call in lib/screens/home_screen.dart (FR-002)
- [X] T026 [US2] Add errorMessage display to PostalCodeInput widget in lib/widgets/postal_code_input.dart
- [X] T027 [US2] Test validation flow: empty → "Please enter a postal code", invalid format → "Please enter a valid 5-digit French postal code"
- [X] T028 [US2] Run tests for User Story 2 (T022-T023) - all should PASS

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - format validation prevents bad requests

---

## Phase 5: User Story 3 - Non-Existent Postal Code Handling (Priority: P3)

**Goal**: Handle edge cases where properly formatted codes don't match French cities

**Independent Test**: Enter "00000" → "No city found for postal code 00000. Please verify and try again." displays

### Tests for User Story 3 - Write FIRST (ensure they FAIL)

- [X] T029 [P] [US3] Write test for PostalCodeNotFoundException handling in test/services/geocoding_service_test.dart
- [X] T030 [P] [US3] Write integration test for non-existent postal code flow in integration_test/app_test.dart

### Implementation for User Story 3

- [X] T031 [US3] Add PostalCodeNotFoundException catch block in _handleSubmit in lib/screens/home_screen.dart
- [X] T032 [US3] Implement error message "No city found for postal code {code}. Please verify and try again." (FR-006)
- [X] T033 [US3] Test with "00000" and "99999" → verify error messages display correctly
- [X] T034 [US3] Run tests for User Story 3 (T029-T030) - all should PASS

**Checkpoint**: All user stories should now be independently functional - complete error handling

---

## Phase 6: Edge Cases & Cross-Cutting Concerns (Priority: P4)

**Purpose**: Handle remaining edge cases and improve robustness

### Tests - Write FIRST (ensure they FAIL)

- [X] T035 [P] Write test for NetworkException handling in test/services/geocoding_service_test.dart
- [X] T036 [P] Write test for ServerException handling in test/services/geocoding_service_test.dart
- [X] T037 [P] Write test for request cancellation in test/screens/home_screen_test.dart (latest-wins)

### Implementation

- [X] T038 Add NetworkException catch block in _handleSubmit in lib/screens/home_screen.dart (FR-011)
- [X] T039 Add ServerException catch block in _handleSubmit in lib/screens/home_screen.dart
- [X] T040 Implement request cancellation in lib/screens/home_screen.dart: store current Future in _pendingRequest field, null it when starting new request to ignore old completion handlers (FR-013)
- [X] T041 Add timeout handling (10 seconds) to geocoding service in lib/services/geocoding_service.dart
- [X] T042 Test network error scenario → verify "No internet connection. Please check your network and try again."
- [X] T043 Test rapid successive submissions → verify latest-wins behavior
- [X] T044 Run all edge case tests (T035-T037) - all should PASS

---

## Phase 7: Polish & Validation

**Purpose**: Final quality checks and performance validation

- [X] T045 [P] Run flutter analyze and fix any remaining issues
- [X] T046 [P] Run flutter test --coverage and verify ≥80% logic coverage, ≥60% UI coverage
- [X] T047 Add dartdoc comments to all public APIs in lib/models/, lib/services/, lib/widgets/
- [X] T048 Test on iOS device/simulator - verify Material Design adapts to iOS conventions
- [X] T049 Test on Android device/emulator - verify Material Design follows Android guidelines
- [X] T050 Performance test: Cold start <3 seconds, validation <500ms, lookup <5 seconds, 60fps map interaction
- [X] T051 Manual testing using quickstart.md verification checklist (all 13 functional requirements)
- [X] T052 Integration test for complete user flow: launch → enter "75001" → map displays → enter "13001" → map updates
- [X] T053 Code review against constitution quality gates (Principles I-IV)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational - Core MVP functionality
- **User Story 2 (Phase 4)**: Depends on Foundational - Can run parallel to US1 but logically builds on it
- **User Story 3 (Phase 5)**: Depends on Foundational and US1 (needs working geocoding service)
- **Edge Cases (Phase 6)**: Depends on US1 completion (needs core flow to add robustness)
- **Polish (Phase 7)**: Depends on all previous phases

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - independent MVP
- **User Story 2 (P2)**: Logically extends US1 but technically independent (just adds validation before API call)
- **User Story 3 (P3)**: Depends on US1 geocoding service existing, independent testing possible

### Within Each User Story (TDD Cycle)

1. Write tests FIRST (should FAIL)
2. Implement models (can be parallel)
3. Implement services (depends on models)
4. Implement widgets (can be parallel)
5. Implement screens (depends on widgets and services)
6. Run tests (should PASS)

### Parallel Opportunities

**Phase 1 (Setup)**: T003 can run parallel with T001-T002

**Phase 2 (Foundational)**: T006, T007 can run parallel (different files)

**Phase 3 (User Story 1)**:
- Tests: T009, T010, T011 all parallel (different test files)
- Models: T012, T013 parallel (different model files)
- Widgets: T016, T017 parallel (different widget files)

**Phase 4 (User Story 2)**:
- Tests: T022, T023 parallel

**Phase 5 (User Story 3)**:
- Tests: T029, T030 parallel

**Phase 6 (Edge Cases)**:
- Tests: T035, T036, T037 all parallel

**Phase 7 (Polish)**: T045, T046 parallel; T048, T049 parallel

---

## Parallel Execution Example: User Story 1

If you have 3 developers, you can parallelize User Story 1 like this:

```bash
# Time Block 1: Write tests in parallel (all should FAIL initially)
Developer A: T009 (postal_code_test.dart)
Developer B: T010 (city_location_test.dart)
Developer C: T011 (geocoding_service_test.dart)

# Time Block 2: Implement models in parallel
Developer A: T012 (postal_code.dart)
Developer B: T013 (city_location.dart)
Developer C: T014 + T015 (geocoding_service.dart - abstract and implementation)

# Time Block 3: Implement UI in parallel
Developer A: T016 (map_display.dart)
Developer B: T017 (postal_code_input.dart)
Developer C: T018 (home_screen.dart)

# Time Block 4: Sequential integration
Developer A: T019 (main.dart update)
Developer A: T020 (loading state)
All: T021 (run tests - should all PASS now)
```

**Estimated Time**:
- Single developer (sequential): 8-12 hours
- 3 developers (parallel): 4-6 hours

---

## MVP Scope Recommendation

**Minimum Viable Product**: Phase 3 (User Story 1) ONLY

This delivers immediate user value:
- ✅ Users can enter valid postal codes
- ✅ Map displays centered on city
- ✅ Interactive map (zoom, pan)
- ✅ Loading indicator

**What's missing from MVP** (can be added incrementally):
- ❌ Format validation (User Story 2)
- ❌ Non-existent postal code errors (User Story 3)
- ❌ Network error handling (Phase 6)

**Recommended First Release**: Phases 1-5 (all user stories)

This provides complete feature per specification:
- ✅ All 13 functional requirements
- ✅ All 3 user stories
- ✅ All edge cases from spec.md clarifications
- ✅ Constitution-compliant quality

---

## Implementation Strategy

### Step 1: Validate Setup (Phase 1-2)
```bash
cd src/app/find_map_location
flutter pub get
flutter analyze
# Should see: "No issues found!"
```

### Step 2: Implement MVP (Phase 3 - User Story 1)
Follow TDD cycle:
1. Write test → should FAIL
2. Implement code → test should PASS
3. Refactor if needed
4. Move to next task

### Step 3: Add Validation (Phase 4 - User Story 2)
Extends US1 with input validation - simple addition

### Step 4: Complete Edge Cases (Phase 5-6)
Add remaining error handling for robustness

### Step 5: Polish & Ship (Phase 7)
Final quality checks before release

---

## Task Summary

- **Total Tasks**: 52 (T008 removed - ErrorType enum not needed)
- **Setup & Foundational**: 7 tasks (blocking)
- **User Story 1 (MVP)**: 13 tasks (core value)
- **User Story 2**: 7 tasks (validation)
- **User Story 3**: 6 tasks (edge cases)
- **Edge Cases**: 7 tasks (robustness)
- **Polish**: 9 tasks (quality gates)
- **Parallel Opportunities**: 14 tasks marked [P] (27% parallelizable)

---

## Success Validation

After completing all tasks, verify against success criteria from spec.md:

- [ ] SC-001: Valid postal code → map display within 5 seconds
- [ ] SC-002: 95% success rate for valid submissions
- [ ] SC-003: Format validation within 500ms (instant)
- [ ] SC-004: 3 lookups in 2 minutes workflow test
- [ ] SC-005: Error messages clear enough for 1-retry correction
- [ ] SC-006: 60fps map interaction (Flutter DevTools profiling)

---

**Next Steps**:
1. Review this task breakdown with team
2. Begin Phase 1 (Setup) - takes ~30 minutes
3. Complete Phase 2 (Foundational) - prerequisite for all stories
4. Implement Phase 3 (User Story 1) for MVP demonstration
5. Continue with remaining phases for complete feature

**Reference**: See quickstart.md for detailed TDD implementation examples and code snippets
