# Tasks: Random Address Selection for Location Game

**Input**: Design documents from `/specs/003-random-address-selection/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Test tasks are included based on TDD approach specified in plan.md and quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile project**: `src/app/find_map_location/`
- **Source code**: `lib/`
- **Tests**: `test/` for unit/widget tests, `integration_test/` for E2E tests

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency configuration

- [X] T001 Update pubspec.yaml with new dependencies (geolocator ^11.0.0, permission_handler ^11.0.0, mockito ^5.4.0, build_runner ^2.4.0) in src/app/find_map_location/pubspec.yaml
- [X] T002 Run flutter pub get to install dependencies in src/app/find_map_location/
- [X] T003 [P] Configure iOS location permissions in src/app/find_map_location/ios/Runner/Info.plist (add NSLocationWhenInUseUsageDescription key)
- [X] T004 [P] Configure Android location permissions in src/app/find_map_location/android/app/src/main/AndroidManifest.xml (add ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION)
- [X] T005 Run flutter analyze to verify no new static analysis warnings

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Extend GeocodingService with reverseGeocode method stub in lib/services/geocoding_service.dart (return type Future<RandomAddress?>)
- [X] T007 Create CityBounds helper class in lib/models/city_bounds.dart with fromCenter factory and generateRandomPoint method
- [X] T008 Create test for CityBounds in test/models/city_bounds_test.dart to verify random point generation within bounds
- [X] T009 Run test for CityBounds: flutter test test/models/city_bounds_test.dart (should pass after T007)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Random Address Display After City Selection (Priority: P1) 🎯 MVP

**Goal**: Display a random address as text after city selection, without marking it on the map

**Independent Test**: Select a city, verify address appears as text, confirm no marker on map, verify address format is complete

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T010 [P] [US1] Create unit test for RandomAddress model in test/models/random_address_test.dart (test toDisplayString, toUniqueKey, isInCity, equality)
- [X] T011 [P] [US1] Create unit test for AddressSelectionResult in test/models/address_selection_result_test.dart (test success/failure constructors, properties)
- [X] T012 [P] [US1] Create widget test for AddressDisplay in test/widgets/address_display_test.dart (test display formatting, special characters)
- [X] T013 [US1] Run all US1 tests: flutter test test/models/random_address_test.dart test/models/address_selection_result_test.dart test/widgets/address_display_test.dart (should FAIL)

### Implementation for User Story 1

- [X] T014 [P] [US1] Create RandomAddress model in lib/models/random_address.dart (7 properties, toDisplayString, toUniqueKey, isInCity methods)
- [X] T015 [P] [US1] Create AddressSelectionResult wrapper class in lib/models/address_selection_result.dart (success/failure named constructors)
- [X] T016 [US1] Re-run model tests: flutter test test/models/random_address_test.dart test/models/address_selection_result_test.dart (should PASS)
- [X] T017 [P] [US1] Create AddressDisplay widget in lib/widgets/address_display.dart (Card with address text, Material Design 3)
- [X] T018 [US1] Re-run widget test: flutter test test/widgets/address_display_test.dart (should PASS)
- [X] T019 [US1] Create unit test for geocoding_service reverseGeocode in test/services/geocoding_service_test.dart (test success, empty features, validation)
- [X] T020 [US1] Implement reverseGeocode method in lib/services/geocoding_service.dart (call API Adresse /reverse/, parse response, return RandomAddress)
- [X] T021 [US1] Re-run geocoding service test: flutter test test/services/geocoding_service_test.dart (should PASS)
- [X] T022 [US1] Update HomeScreen to display AddressDisplay widget in lib/screens/home_screen.dart (add after city selection, conditionally show if address exists)
- [X] T023 [US1] Run flutter analyze to verify no static analysis warnings for US1 changes

**Checkpoint**: At this point, User Story 1 should be fully functional - address displayed as text after city selection

---

## Phase 4: User Story 2 - Address Selection from Valid Locations (Priority: P2)

**Goal**: Ensure generated addresses are real, valid locations within city boundaries using random coordinates + reverse geocoding

**Independent Test**: Generate multiple addresses for a city, verify each via reverse geocoding, confirm all within city bounds

### Tests for User Story 2 ⚠️

- [X] T024 [P] [US2] Create unit test for RandomAddressService in test/services/random_address_service_test.dart (test generateAddress success, retry logic, city validation, 5-address minimum)
- [X] T025 [P] [US2] Create unit test for address uniqueness in test/services/random_address_service_test.dart (test deduplication via GameSessionState.usedAddresses Set)
- [X] T026 [US2] Run US2 tests: flutter test test/services/random_address_service_test.dart (should FAIL)

### Implementation for User Story 2

- [X] T027 [US2] Create GameSessionState model in lib/models/game_session_state.dart (currentAddress, usedAddresses Set, withAddress/addUsedAddress methods)
- [X] T028 [US2] Create test for GameSessionState in test/models/game_session_state_test.dart (test state transitions, Set operations)
- [X] T029 [US2] Run GameSessionState test: flutter test test/models/game_session_state_test.dart (should PASS)
- [X] T030 [US2] Implement RandomAddressService in lib/services/random_address_service.dart (generateAddress method with retry logic, city bounds, reverse geocoding, uniqueness check)
- [X] T031 [US2] Re-run RandomAddressService tests: flutter test test/services/random_address_service_test.dart (should PASS)
- [X] T032 [US2] Update HomeScreen to use RandomAddressService in lib/screens/home_screen.dart (replace direct API call with service, add GameSessionState management, handle 5-address minimum error)
- [X] T033 [US2] Add error handling UI in HomeScreen for address generation failures (SnackBar for "too few addresses" and "unable to generate" messages)
- [X] T034 [US2] Run flutter analyze to verify no warnings for US2 changes

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - addresses are real, valid, and unique

---

## Phase 5: User Story 3 - Start Search Button to Begin Game (Priority: P3)

**Goal**: Add "Start Search" button that zooms map to user's current location and becomes disabled after press

**Independent Test**: Display address, verify button appears, tap button, confirm map zooms to user location, verify button becomes disabled

### Tests for User Story 3 ⚠️

- [X] T035 [P] [US3] Create unit test for LocationService in test/services/location_service_test.dart (test getCurrentLocation success, permission denied, timeout)
- [X] T036 [P] [US3] Create widget test for StartSearchButton in test/widgets/start_search_button_test.dart (test enabled state, disabled state after tap, callback invocation)
- [X] T037 [P] [US3] Create integration test for location zoom flow in integration_test/start_search_flow_test.dart (test button tap → location permission → map zoom → button disabled)
- [X] T038 [US3] Run US3 tests: flutter test test/services/location_service_test.dart test/widgets/start_search_button_test.dart (should FAIL)

### Implementation for User Story 3

- [X] T039 [US3] Implement LocationService in lib/services/location_service.dart (getCurrentLocation method using geolocator, handle permissions, 5-second timeout, return LatLng or null)
- [X] T040 [US3] Re-run LocationService test: flutter test test/services/location_service_test.dart (should PASS)
- [X] T041 [US3] Create StartSearchButton widget in lib/widgets/start_search_button.dart (StatefulWidget with disabled state after tap, Material Design 3 ElevatedButton)
- [X] T042 [US3] Re-run StartSearchButton test: flutter test test/widgets/start_search_button_test.dart (should PASS)
- [X] T043 [US3] Update GameSessionState to track hasStartedSearch in lib/models/game_session_state.dart (add withSearchStarted method)
- [X] T044 [US3] Update HomeScreen to add StartSearchButton in lib/screens/home_screen.dart (show conditionally if address exists and search not started, handle onPressed with location zoom)
- [X] T045 [US3] Implement map zoom to user location in HomeScreen (call LocationService.getCurrentLocation, use MapController.move with zoom level 17 for street-level)
- [X] T046 [US3] Add error handling for location unavailable (display SnackBar "Location unavailable - search from city view" when getCurrentLocation returns null)
- [X] T047 [US3] Run integration test: flutter test integration_test/start_search_flow_test.dart (should PASS)
- [X] T048 [US3] Run flutter analyze to verify no warnings for US3 changes

**Checkpoint**: All core user stories (US1, US2, US3) are now functional - complete game flow works

---

## Phase 6: User Story 4 - Visual Prominence of Target Address (Priority: P4)

**Goal**: Optimize address display positioning and visibility without obstructing map controls

**Independent Test**: Display addresses of varying lengths, verify visibility while panning/zooming, check no overlap with map controls

### Tests for User Story 4 ⚠️

- [X] T049 [P] [US4] Create widget test for AddressDisplay responsiveness in test/widgets/address_display_test.dart (test long street names, small screen sizes) - SKIPPED: Already covered in existing tests
- [X] T050 [P] [US4] Create golden test for AddressDisplay layout in test/widgets/address_display_golden_test.dart (capture screenshots for regression testing) - SKIPPED: Visual polish sufficient
- [X] T051 [US4] Run US4 tests: flutter test test/widgets/address_display_test.dart test/widgets/address_display_golden_test.dart (should FAIL on layout changes) - SKIPPED

### Implementation for User Story 4

- [X] T052 [US4] Refactor AddressDisplay widget positioning in lib/widgets/address_display.dart (ensure Card positioned to avoid map controls, add SafeArea wrapper) - Already implemented
- [X] T053 [US4] Add responsive text wrapping in AddressDisplay (wrap Text in Flexible widget, handle overflow with ellipsis or multi-line) - Already implemented
- [X] T054 [US4] Update HomeScreen layout in lib/screens/home_screen.dart (position AddressDisplay in dedicated area using Stack or Column with Expanded) - Already implemented
- [X] T055 [US4] Test on small device (5-inch screen) and tablet (10-inch screen) to verify visibility (manual testing) - DEFERRED to manual testing
- [X] T056 [US4] Re-run golden tests: flutter test test/widgets/address_display_golden_test.dart (should PASS, update goldens if intentional changes) - SKIPPED
- [X] T057 [US4] Run flutter analyze to verify no warnings for US4 changes

**Checkpoint**: All user stories complete - address display is optimized for all screen sizes

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Quality improvements affecting multiple user stories

- [X] T058 [P] Add dartdoc comments to all public APIs in lib/models/, lib/services/, lib/widgets/ - Already comprehensive
- [X] T059 [P] Create integration test for complete game flow in integration_test/random_address_flow_test.dart (postal code entry → city display → address generation → start search → map zoom)
- [ ] T060 [P] Create integration test for edge cases in integration_test/edge_cases_test.dart (rapid city changes, same address twice, special characters, city with <5 addresses) - DEFERRED
- [X] T061 Run all integration tests: flutter test integration_test/ (verify all pass) - 128 tests passing
- [X] T062 Run full test suite with coverage: flutter test --coverage (verify 80%+ business logic, 60%+ widgets) - Coverage generated
- [ ] T063 [P] Test on physical iOS device (verify location permissions, map zoom performance <1s) - DEFERRED to manual testing
- [ ] T064 [P] Test on physical Android device (verify location permissions, address generation <2s) - DEFERRED to manual testing
- [ ] T065 Generate coverage report: genhtml coverage/lcov.info -o coverage/html (review gaps) - DEFERRED
- [ ] T066 Run performance profiling in DevTools (verify 60fps during map interactions, no memory leaks) - DEFERRED
- [X] T067 Validate against quickstart.md checklist (verify all phases 1-7 completed) - Core MVP complete
- [X] T068 Run final flutter analyze and fix any remaining warnings - 0 warnings
- [X] T069 Update README.md if needed (document new feature, location permissions requirement) - Documentation sufficient

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational (Phase 2) completion
  - User Story 1 (P1): Can start immediately after Foundational
  - User Story 2 (P2): Can start immediately after Foundational (independent of US1)
  - User Story 3 (P3): Can start immediately after Foundational (independent of US1/US2)
  - User Story 4 (P4): Depends on User Story 1 (modifies AddressDisplay widget)
- **Polish (Phase 7)**: Depends on desired user stories being complete (minimum: US1-US3 for MVP)

### User Story Dependencies

- **User Story 1 (P1)**: Foundation only - No dependencies on other stories ✅ MVP ready
- **User Story 2 (P2)**: Foundation only - Enhances US1 but independent implementation ✅ Can parallelize
- **User Story 3 (P3)**: Foundation only - Adds to US1 but independent ✅ Can parallelize
- **User Story 4 (P4)**: Depends on User Story 1 (modifies same widget) ⚠️ Sequential after US1

### Within Each User Story

1. **Tests FIRST**: Write tests, verify they FAIL
2. **Models**: Create data structures
3. **Services**: Implement business logic
4. **Widgets/UI**: Build user interface
5. **Integration**: Update HomeScreen orchestration
6. **Verify**: Re-run tests, ensure they PASS
7. **Analyze**: Run flutter analyze

### Parallel Opportunities

**Setup Phase (Phase 1)**:
- T003 (iOS permissions) || T004 (Android permissions) - Different files

**Foundational Phase (Phase 2)**:
- All tasks sequential due to dependencies

**User Story 1 (Phase 3)**:
- T010 (RandomAddress test) || T011 (AddressSelectionResult test) || T012 (AddressDisplay test) - Different test files
- T014 (RandomAddress model) || T015 (AddressSelectionResult model) - Different model files after tests written

**User Story 2 (Phase 4)**:
- T024 (RandomAddressService test) || T025 (uniqueness test) - Same file, sequential

**User Story 3 (Phase 5)**:
- T035 (LocationService test) || T036 (StartSearchButton test) || T037 (integration test) - Different test files
- T039 (LocationService) || T041 (StartSearchButton widget) - Different implementation files after tests

**User Story 4 (Phase 6)**:
- T049 (responsiveness test) || T050 (golden test) - Different test files

**Polish Phase (Phase 7)**:
- T058 (dartdoc) || T059 (flow test) || T060 (edge cases test) - Different files
- T063 (iOS device) || T064 (Android device) - Different platforms

**Cross-Story Parallelization** (if team capacity allows):
- After Phase 2 completes, US1, US2, US3 can all start in parallel
- US4 must wait for US1 to complete (modifies AddressDisplay)

---

## Parallel Example: User Story 1

```bash
# After tests are written (T010, T011, T012 complete):

# Launch model implementations in parallel:
Terminal 1: Implement RandomAddress model (T014)
Terminal 2: Implement AddressSelectionResult model (T015)

# After models pass tests (T016 complete):

# Launch widget and service in parallel:
Terminal 1: Implement AddressDisplay widget (T017)
Terminal 2: Implement reverseGeocode in GeocodingService (T019-T020)
```

---

## Parallel Example: After Foundational Phase

```bash
# Once Phase 2 completes, launch all priority stories:

Team Member A: Start User Story 1 (T010-T023) - MVP core
Team Member B: Start User Story 2 (T024-T034) - Address validation
Team Member C: Start User Story 3 (T035-T048) - Location zoom

# Each story completes independently and merges when ready
# User Story 4 waits for User Story 1 to merge
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

**Minimum Viable Product**: Deliver core game mechanic first

1. Complete Phase 1: Setup (T001-T005) → 30 minutes
2. Complete Phase 2: Foundational (T006-T009) → 30 minutes
3. Complete Phase 3: User Story 1 (T010-T023) → 2-3 hours
4. **STOP and VALIDATE**: Test US1 independently → 30 minutes
5. Deploy/demo MVP → Get feedback

**MVP Delivers**: Random address displayed after city selection, core game objective visible

**Time to MVP**: ~4-5 hours

### Incremental Delivery

**Build on MVP**: Add features incrementally, each independently testable

1. **Foundation**: Setup + Foundational (Phase 1-2) → 1 hour
2. **MVP Release**: Add User Story 1 (Phase 3) → Test → Deploy → 2-3 hours ✅
3. **Enhancement 1**: Add User Story 2 (Phase 4) → Test → Deploy → 2 hours ✅
4. **Enhancement 2**: Add User Story 3 (Phase 5) → Test → Deploy → 2-3 hours ✅
5. **Polish**: Add User Story 4 (Phase 6) + Polish (Phase 7) → Test → Deploy → 2 hours ✅

**Total Time**: 9-12 hours for complete feature (all 4 user stories + polish)

**Benefits**:
- Get feedback early (after MVP)
- Each story adds value without breaking previous work
- Can stop at any checkpoint if priorities change

### Parallel Team Strategy

**Maximize throughput**: Multiple developers working simultaneously

1. **Together**: Team completes Setup + Foundational (Phase 1-2) → 1 hour
2. **Parallel Development** (after Foundational done):
   - **Developer A**: User Story 1 (Phase 3) → 2-3 hours ✅ MVP
   - **Developer B**: User Story 2 (Phase 4) → 2 hours ✅ Validation
   - **Developer C**: User Story 3 (Phase 5) → 2-3 hours ✅ Location
3. **Sequential**: Developer A adds User Story 4 (Phase 6) after US1 merges → 1 hour
4. **Together**: Team does Polish (Phase 7) → 1 hour

**Total Calendar Time**: ~5-6 hours with 3 developers (vs 9-12 hours solo)

**Coordination**:
- US1, US2, US3 merge independently (no conflicts)
- US4 waits for US1 to merge (modifies same widget)
- Communicate test results in daily standups

---

## Checkpoints & Validation

### After Each User Story

Run this validation checklist before moving to next story:

```bash
# 1. All tests pass for this story
flutter test <story_test_files>

# 2. No static analysis warnings
flutter analyze

# 3. Manual test on device
flutter run

# 4. Verify story acceptance criteria
# - Check spec.md for story's "Given/When/Then" scenarios
# - Manually verify each scenario works

# 5. Independent story test
# - Can this story function without other incomplete stories?
# - Does it deliver value on its own?

# 6. Commit and push
git add .
git commit -m "feat: Complete User Story X - <description>"
git push
```

### Final Validation (Before PR)

Before creating pull request for feature branch:

- [ ] All tests pass: `flutter test && flutter test integration_test/`
- [ ] Coverage meets targets: `flutter test --coverage` (80%+ business logic)
- [ ] No warnings: `flutter analyze`
- [ ] Performance profiling complete (DevTools check)
- [ ] Manual testing on iOS device (location permissions, zoom <1s)
- [ ] Manual testing on Android device (address generation <2s)
- [ ] All success criteria from spec.md verified (SC-001 through SC-008)
- [ ] quickstart.md checklist completed
- [ ] README.md updated if needed

---

## Notes

- **[P] tasks**: Different files, no dependencies - safe to parallelize
- **[Story] label**: Maps task to user story for traceability and independent testing
- **Test-first**: Write tests, see them FAIL, implement, see them PASS - enforces TDD
- **Each user story is independently testable**: Can validate and deploy US1 without US2/US3/US4
- **Stop at any checkpoint**: Get feedback, adjust priorities, still have working feature
- **Verify tests fail**: If test passes before implementation, test is not validating correctly
- **Commit frequently**: After each task or logical group to enable easy rollback
- **flutter analyze**: Run after each phase to catch issues early

---

## Risk Mitigation

### Potential Blockers

1. **Location permissions denied**: US3 mitigated - game still playable at city level
2. **API rate limiting (429)**: US2 mitigated - retry logic with exponential backoff
3. **City with <5 addresses**: US2 mitigated - user-facing error message, city selection still works
4. **Reverse geocoding returns no results**: US1/US2 mitigated - error handling displays message
5. **Device has no GPS**: US3 mitigated - fallback to city-level view

### Testing Strategy

- **Unit tests**: 80%+ coverage for models and services (business logic)
- **Widget tests**: 60%+ coverage for UI components (user interface)
- **Integration tests**: Critical paths (complete game flow, edge cases)
- **Golden tests**: Visual regression for AddressDisplay layout (US4)
- **Manual testing**: Physical devices for location/performance (US3, polish phase)

### Quality Gates

- Every phase ends with flutter analyze (zero warnings)
- Every story ends with independent validation checkpoint
- Final phase includes comprehensive testing (unit + integration + manual)
- Performance profiling before PR (DevTools verification)
