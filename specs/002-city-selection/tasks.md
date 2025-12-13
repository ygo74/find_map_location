# Tasks: City Selection for Duplicate Postal Codes

**Input**: Design documents from `/specs/002-city-selection/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/geocoding-api.md

**Feature**: 002-city-selection
**Branch**: `002-city-selection`
**Tech Stack**: Flutter 3.x / Dart 3.10.4+

## Clarifications Applied

**Session 2025-12-13** - The following clarifications from spec.md and plan.md are integrated into tasks:

1. **Navigation Pattern (FR-002)**: Full-screen route using Navigator.push (not modal/dialog)
2. **Department Display (FR-007)**: Two-line ListTile with city name in title, department in subtitle
3. **Request Cancellation (FR-010)**: Request ID tracking approach (no new dependencies)
4. **Long Name Threshold**: 40 characters for text wrapping test cases
5. **Retry Policy**: No automatic retry; single attempt with clear error message

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project structure already exists from feature 001-postal-code-map. No additional setup needed.

- [x] T001 Project structure already established in src/app/find_map_location/
- [x] T002 Flutter dependencies already configured (flutter_map, latlong2, http)
- [x] T003 Linting and testing already configured (flutter_lints, flutter_test)

**Status**: ✅ Complete (inherited from feature 001)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and service updates that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Models

- [X] T004 [P] Create City model with fromJson factory in src/app/find_map_location/lib/models/city.dart
- [X] T005 [P] Create PostalCodeResult wrapper in src/app/find_map_location/lib/models/postal_code_result.dart

### Service Layer

- [X] T006 Update GeocodingService interface signature in src/app/find_map_location/lib/services/geocoding_service.dart
- [X] T007 Update ApiAdresseGeocodingService to change limit=1 to limit=50 in src/app/find_map_location/lib/services/geocoding_service.dart
- [X] T008 Update ApiAdresseGeocodingService to parse all features (not just first) in src/app/find_map_location/lib/services/geocoding_service.dart
- [X] T009 Update ApiAdresseGeocodingService to return PostalCodeResult in src/app/find_map_location/lib/services/geocoding_service.dart

### Tests for Foundational (TDD - Write and fail before implementation)

- [X] T010 [P] Unit test for City.fromJson parsing in src/app/find_map_location/test/models/city_test.dart
- [X] T011 [P] Unit test for City.displayLabel logic in src/app/find_map_location/test/models/city_test.dart
- [X] T012 [P] Unit test for PostalCodeResult.isSingleCity in src/app/find_map_location/test/models/postal_code_result_test.dart
- [X] T013 [P] Unit test for PostalCodeResult.requiresSelection in src/app/find_map_location/test/models/postal_code_result_test.dart
- [X] T014 [P] Unit test for PostalCodeResult.sortedCities in src/app/find_map_location/test/models/postal_code_result_test.dart
- [X] T015 Update GeocodingService tests for multiple cities in src/app/find_map_location/test/services/geocoding_service_test.dart
- [X] T016 Add test case for single city result in src/app/find_map_location/test/services/geocoding_service_test.dart
- [X] T017 Add test case for multiple cities result in src/app/find_map_location/test/services/geocoding_service_test.dart

**Checkpoint**: ✅ Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - City Selection for Postal Codes with Multiple Locations (Priority: P1) 🎯 MVP

**Goal**: When a postal code returns multiple cities, display a selection list and center map on selected city

**Independent Test**: Enter postal code "01630", verify 3 cities appear in selection list, select "Péron", verify map centers on Péron

### Tests for User Story 1 (TDD - Write and fail before implementation)

- [X] T018 [P] [US1] Widget test for CitySelectionScreen displays all cities in src/app/find_map_location/test/screens/city_selection_screen_test.dart
- [X] T019 [P] [US1] Widget test for city tap returns selected city in src/app/find_map_location/test/screens/city_selection_screen_test.dart
- [X] T020 [P] [US1] Widget test for cities displayed with two-line ListTile (city in title, department in subtitle) in src/app/find_map_location/test/screens/city_selection_screen_test.dart
- [X] T021 [P] [US1] Widget test for cities sorted alphabetically in src/app/find_map_location/test/screens/city_selection_screen_test.dart

### Implementation for User Story 1

- [X] T022 [US1] Create CitySelectionScreen widget with ListView.builder in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T023 [US1] Add AppBar with "Select City" title in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T024 [US1] Implement two-line ListTile for each city (name in title, department in subtitle) in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T025 [US1] Add onTap handler to pop with selected city in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T026 [US1] Sort cities alphabetically before display in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T027 [US1] Update HomeScreen to check result.requiresSelection in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T028 [US1] Add full-screen Navigator.push to CitySelectionScreen for multi-city results in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T029 [US1] Handle selected city return and update map in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T030 [US1] Add semantic labels for accessibility to city list items in src/app/find_map_location/lib/screens/city_selection_screen.dart

### Integration Test for User Story 1

- [X] T031 [US1] Integration test: Enter "01630" → see selection → select city → map displays in src/app/find_map_location/integration_test/multi_city_flow_test.dart

**Checkpoint**: ✅ User Story 1 complete and independently testable. Users can select from multiple cities.

---

## Phase 4: User Story 2 - Single City Result Bypasses Selection (Priority: P2)

**Goal**: Maintain backward compatibility - single city results display map immediately without selection screen

**Independent Test**: Enter postal code "75001", verify no selection list appears, verify map displays immediately

### Tests for User Story 2 (TDD - Write and fail before implementation)

- [X] T032 [P] [US2] Unit test verifying result.isSingleCity logic in src/app/find_map_location/test/models/postal_code_result_test.dart
- [X] T033 [P] [US2] Integration test for single-city bypass flow in src/app/find_map_location/integration_test/single_city_bypass_test.dart

### Implementation for User Story 2

- [X] T034 [US2] Add conditional check for result.isSingleCity in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T035 [US2] Display map immediately when isSingleCity is true in src/app/find_map_location/lib/screens/home_screen.dart
- [ ] T036 [US2] Verify single-city flow matches feature 001 behavior in src/app/find_map_location/lib/screens/postal_code_screen.dart

**Checkpoint**: ✅ User Stories 1 AND 2 both work independently. Single-city UX unchanged from feature 001.

---

## Phase 5: User Story 3 - Cancel City Selection (Priority: P3)

**Goal**: Users can dismiss selection list and return to postal code entry

**Independent Test**: Enter multi-city postal code, see selection, press back button, verify returns to postal code entry

### Tests for User Story 3 (TDD - Write and fail before implementation)

- [X] T037 [P] [US3] Widget test for back button dismisses selection in src/app/find_map_location/integration_test/cancel_selection_test.dart
- [X] T038 [P] [US3] Integration test for cancel flow in src/app/find_map_location/integration_test/cancel_selection_test.dart

### Implementation for User Story 3

- [X] T039 [US3] Verify AppBar back button pops with null in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T040 [US3] Handle null return from Navigator.pop in HomeScreen in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T041 [US3] Reset to idle state when user cancels selection in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T042 [US3] Test rapid postal code changes cancels previous request in src/app/find_map_location/lib/screens/home_screen.dart

**Checkpoint**: ✅ All user stories complete. Users can cancel selection and retry.

---

## Phase 6: Edge Cases & Error Handling

**Purpose**: Handle edge cases identified in spec.md

- [X] T043 [P] Handle cities with identical names by showing department in src/app/find_map_location/lib/models/city.dart
- [X] T044 [P] Handle very long city names (>40 chars) with text wrapping in ListTile in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T045 [P] Handle empty city list with error message in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T046 [P] Handle network failure with error message (no automatic retry) in src/app/find_map_location/lib/screens/home_screen.dart
- [X] T047 Add request ID tracking for cancellation on rapid postal code changes in src/app/find_map_location/lib/screens/home_screen.dart

### Edge Case Tests

- [X] T048 [P] Test handling of cities with identical names in src/app/find_map_location/test/models/city_test.dart
- [X] T049 [P] Test empty city list error handling in src/app/find_map_location/test/services/geocoding_service_test.dart
- [X] T050 [P] Test network failure error handling in src/app/find_map_location/test/services/geocoding_service_test.dart

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and validation

- [X] T051 [P] Add dartdoc comments to City model in src/app/find_map_location/lib/models/city.dart
- [X] T052 [P] Add dartdoc comments to PostalCodeResult in src/app/find_map_location/lib/models/postal_code_result.dart
- [X] T053 [P] Add dartdoc comments to CitySelectionScreen in src/app/find_map_location/lib/screens/city_selection_screen.dart
- [X] T054 Run `flutter analyze` and fix any warnings
- [X] T055 Run all unit tests and verify 80%+ coverage for logic
- [ ] T056 Run all widget tests and verify 60%+ coverage for UI
- [ ] T057 Run all integration tests on iOS device/simulator
- [ ] T058 Run all integration tests on Android device/emulator
- [ ] T059 Manual testing with postal codes: 75001, 01630, 35530, 00000
- [ ] T060 Verify performance: city selection < 500ms, map position < 2s
- [ ] T061 [P] Update README.md with feature 002 description
- [ ] T062 Validate against quickstart.md implementation guide

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Setup (Phase 1)**: ✅ Complete (inherited from feature 001)
2. **Foundational (Phase 2)**: Must complete T004-T017 before any user story
3. **User Story 1 (Phase 3)**: Depends on Phase 2 completion - Can start immediately after
4. **User Story 2 (Phase 4)**: Depends on Phase 2 completion - Can run in parallel with US1
5. **User Story 3 (Phase 5)**: Depends on Phase 2 and US1 completion
6. **Edge Cases (Phase 6)**: Depends on US1 completion - Can run in parallel with US2/US3
7. **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: No dependencies on other stories (only on Foundational Phase 2)
- **US2 (P2)**: No dependencies on other stories (only on Foundational Phase 2) - Can implement in parallel with US1
- **US3 (P3)**: Depends on US1 (requires CitySelectionScreen to exist)

### Critical Path

```
Phase 1 (Setup) [Complete]
    ↓
Phase 2 (Foundational) [T004-T017]
    ↓
    ┌─────────────┬─────────────┐
    ↓             ↓             ↓
  US1 (P1)     US2 (P2)   Edge Cases
  [T018-T031]  [T032-T036] [T043-T050]
    ↓             ↓
    └─────────────┤
                  ↓
              US3 (P3)
              [T037-T042]
                  ↓
             Phase 7 (Polish)
             [T051-T062]
```

### Parallel Opportunities Per Phase

**Phase 2 (Foundational)**:
- Models T004-T005 can run in parallel
- Tests T010-T014 can run in parallel (after models)
- Service updates T006-T009 are sequential (same file)
- Service tests T015-T017 can run in parallel (after service updates)

**Phase 3 (US1)**:
- All tests T018-T021 can run in parallel (different test aspects)
- Screen creation T022 must complete before T023-T026
- PostalCodeScreen updates T027-T029 are sequential (same file)
- Integration test T031 runs after all implementation

**Phase 4 (US2)**:
- Tests T032-T033 can run in parallel
- Implementation T034-T036 are sequential (same file)

**Phase 5 (US3)**:
- Tests T037-T038 can run in parallel
- Implementation T039-T042 are sequential (same file)

**Phase 6 (Edge Cases)**:
- All edge case implementations T043-T047 can run in parallel (different files)
- All edge case tests T048-T050 can run in parallel

**Phase 7 (Polish)**:
- Documentation T051-T053 can run in parallel
- Analysis T054 must complete before other validations
- All testing T055-T060 can run in parallel (different test types)
- Documentation T061-T062 can run in parallel

### Parallel Example: Foundational Phase

If working with a team, these tasks can execute simultaneously:

```bash
# Terminal 1 - Developer A
cd src/app/find_map_location
# T004: Create City model
code lib/models/city.dart

# Terminal 2 - Developer B
cd src/app/find_map_location
# T005: Create PostalCodeResult
code lib/models/postal_code_result.dart

# After models complete:

# Terminal 1 - Developer A
# T010-T011: City tests
code test/models/city_test.dart

# Terminal 2 - Developer B
# T012-T014: PostalCodeResult tests
code test/models/postal_code_result_test.dart
```

### Parallel Example: User Story Phase

Once Foundational (Phase 2) completes, these can run in parallel:

```bash
# Terminal 1 - Developer A
# US1: Multi-city selection
code lib/screens/city_selection_screen.dart
code test/screens/city_selection_screen_test.dart

# Terminal 2 - Developer B
# US2: Single-city bypass
code lib/screens/postal_code_screen.dart
code integration_test/single_city_bypass_test.dart

# Terminal 3 - Developer C
# Edge Cases
code lib/models/city.dart  # Identical name handling
code test/models/city_test.dart
```

---

## Implementation Strategy

### MVP-First Approach

**Minimum Viable Product = User Story 1 (P1) only**

To deliver value quickly:
1. Complete Phase 1 (Setup) - Already done ✅
2. Complete Phase 2 (Foundational) - Models and service updates
3. Complete Phase 3 (User Story 1) - Multi-city selection
4. Deploy and gather feedback

User Stories 2 and 3 can be added incrementally in subsequent releases.

### Recommended Sequence

For a single developer working sequentially:

1. **Week 1**: Foundational (T004-T017)
   - Focus: Models, service updates, unit tests
   - Deliverable: PostalCodeResult with multiple cities

2. **Week 2**: User Story 1 (T018-T031)
   - Focus: City selection UI, integration
   - Deliverable: MVP - working multi-city selection

3. **Week 3**: User Stories 2 & 3 (T032-T042)
   - Focus: Single-city bypass, cancel flow
   - Deliverable: Full feature with all stories

4. **Week 4**: Polish (T043-T062)
   - Focus: Edge cases, documentation, testing
   - Deliverable: Production-ready feature

### Task Validation

Each task is considered complete when:
- ✅ Code written and follows Flutter/Dart style guide
- ✅ `flutter analyze` passes with no warnings
- ✅ Unit/widget tests pass (if TDD task included)
- ✅ Code reviewed by peer
- ✅ File path in task description matches actual location
- ✅ Task marked with checkbox checked: `[x]`

---

## Summary Statistics

- **Total Tasks**: 62
- **Foundational Tasks**: 14 (T004-T017)
- **User Story 1 Tasks**: 14 (T018-T031)
- **User Story 2 Tasks**: 5 (T032-T036)
- **User Story 3 Tasks**: 6 (T037-T042)
- **Edge Case Tasks**: 8 (T043-T050)
- **Polish Tasks**: 12 (T051-T062)
- **Parallelizable Tasks**: 35 marked with [P]
- **Test Tasks**: 22 (following TDD approach)
- **Implementation Tasks**: 40

**Suggested MVP Scope**: Foundational + User Story 1 = 28 tasks

**Test Coverage Strategy**:
- Unit tests for all models (City, PostalCodeResult)
- Service tests for geocoding multi-city parsing
- Widget tests for CitySelectionScreen (two-line ListTile format, 40-char names)
- Integration tests for each user story flow
- Target: 80% coverage for logic, 60% for UI

---

## Implementation Notes (From Clarifications)

### Request Cancellation Strategy (T047)

**Approach**: Request ID tracking without new dependencies

Implementation details for T047:
1. Generate unique request ID (timestamp or UUID) when postal code submitted
2. Store current request ID in PostalCodeScreen state
3. When response arrives, check if request ID matches current state
4. If IDs don't match, discard response (superseded by newer request)

**Example Pattern**:
```dart
int _currentRequestId = 0;

Future<void> _searchPostalCode(String code) async {
  final requestId = ++_currentRequestId;
  final result = await geocodingService.fetchLocations(code);
  if (requestId != _currentRequestId) return; // Discard outdated
  // Process result...
}
```

### UI Layout Details (T022-T024, T028)

**Navigation**: Full-screen with Navigator.push (T028)
- Use `Navigator.push(context, MaterialPageRoute(builder: (_) => CitySelectionScreen(...)))`
- Provides natural Android back button
- Returns selected city via `Navigator.pop(context, selectedCity)`

**List Item Format**: Two-line ListTile (T024)
```dart
ListTile(
  title: Text(city.name),           // Primary: City name
  subtitle: Text(city.department),  // Secondary: Department
  onTap: () => Navigator.pop(context, city),
)
```

### Edge Case Specifics

**Long Names** (T044): Test with 40+ character threshold
- Test city: "Saint-Rémy-en-Bouzemont-Saint-Genest-et-Isson" (48 chars)
- Verify ListTile wraps text without overflow
- No horizontal scrolling required

**Network Failures** (T046): No automatic retry
- Single API attempt per user submission
- Clear error message on failure
- User manually retries by resubmitting

**Department Display** (T043, T020): Two-line format
- Always show department in subtitle for consistency
- Enables scanning by city name (title) first
- Department provides secondary disambiguation
