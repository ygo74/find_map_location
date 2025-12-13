``markdown
# Implementation Plan: City Selection for Duplicate Postal Codes

**Branch**: `002-city-selection` | **Date**: 2025-12-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-city-selection/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Extend the postal code map viewer to handle postal codes with multiple cities. When a postal code returns multiple cities, display a full-screen selection interface (using Navigator.push) for users to choose the correct city. Single-city results bypass selection and display the map immediately. Technical approach builds on existing geocoding service to parse all cities from API response, adds new City model and selection screen, and updates map positioning logic. Request cancellation uses Future tracking with request IDs (no new dependencies).

## Clarifications Applied

### Session 2025-12-13

The following clarifications from the spec have been integrated into this plan:

1. **Request Cancellation (FR-010)**: Use existing http package with Future tracking and request ID validation to discard outdated responses
2. **Navigation Pattern (FR-002)**: Full-screen route using Navigator.push for city selection
3. **Department Display (FR-007)**: Two-line ListTile with city name in title, department in subtitle
4. **Long Name Threshold**: 40 characters for text wrapping test cases
5. **Retry Policy**: No automatic retry; single attempt with clear error message

## Technical Context

**Language/Version**: Dart 3.10.4+ / Flutter 3.x (Flutter SDK from pubspec.yaml: ^3.10.4)

**Primary Dependencies**:
- `flutter_map` (^8.2.2) - OpenStreetMap integration for interactive maps (existing)
- `latlong2` (^0.9.0) - Geographic coordinate handling (existing)
- `http` (^1.2.0) - HTTP client for geocoding API calls (existing)
- `flutter_lints` (^6.0.0) - Linting rules (dev dependency, existing)
- State Management: Built-in `StatefulWidget` (consistent with feature 001)

**Storage**: N/A (no persistent storage required; all data fetched on-demand)

**Testing**:
- `flutter_test` (SDK) - Unit and widget testing
- `integration_test` (SDK) - End-to-end testing
- HTTP mocking for geocoding service tests (verify multiple city parsing)

**Target Platform**: iOS 12+ and Android API 21+ (mobile-first, cross-platform)

**Project Type**: Mobile (single Flutter application)

**Performance Goals**:
- 60fps UI rendering during city selection list scroll
- <2 seconds from city selection tap to map positioned
- <500ms to display city selection list after geocoding response

**Constraints**:
- Depends on feature 001-postal-code-map being complete
- Geocoding API must return all cities in response (not just first match)
- Internet connectivity required (no offline mode)
- Request cancellation for rapid postal code changes (latest-wins pattern via request ID tracking)
- No automatic retry for API failures (single attempt with clear error message)

**Scale/Scope**:
- Adds 1 screen/widget (city selection screen using Navigator.push)
- ~3-5 new source files (city model update, selection screen, service enhancement)
- Handles 1-20+ cities per postal code
- Typical case: 1-3 cities per postal code

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Code Quality & Maintainability  PASS
- **Static Analysis**: Will use existing `flutter analyze` from feature 001
- **Linting**: `flutter_lints` ^6.0.0 already configured
- **Architecture**: Extends existing feature-first structure (models/, services/, widgets/)
- **Immutability**: City model will use immutable fields with const constructors
- **Null Safety**: Dart 3.10.4+ enforces null safety
- **Documentation**: Dartdoc comments required for new public APIs

**Status**:  No violations. Extends existing architecture consistently.

### Principle II: Test-First Development  PASS
- **TDD Cycle**: Will follow same test-first approach as feature 001
- **Coverage Gates**: 80% logic / 60% UI targets apply to new code
- **Test Pyramid**: Unit (city parsing, selection logic), Widget (city list display), Integration (multi-city flow)
- **Widget Testing**: City selection screen requires widget tests
- **Golden Tests**: Optional for selection list but recommended for visual regression
- **Integration Tests**: Multi-city postal code flow requires integration test

**Status**:  No violations. Testing requirements clear and achievable.

### Principle III: User Experience Consistency  PASS
- **Material Design**: Will use Material ListView/ListTile for city selection with two-line format (city in title, department in subtitle)
- **Responsive Design**: Selection list adapts to screen size; scrollable for long lists
- **Platform Conventions**: Native scroll behavior and navigation patterns (Navigator.push full screen)
- **Accessibility**: City list items require semantic labels for screen readers
- **Theme System**: Will use existing ThemeData configuration
- **Loading States**: Reuse existing loading indicator during geocoding
- **Error Handling**: Clear error messages for empty lists, network failures (spec FR-009); no automatic retry

**Status**:  No violations. UX extends existing patterns consistently.

### Principle IV: Performance & Efficiency  PASS
- **Build Performance**: ListView.builder for city list (lazy loading if >20 cities)
- **Frame Rate**: 60fps target maintained; simple list scrolling well-optimized in Flutter
- **Memory Management**: Dispose controllers properly; selection state cleared on new lookup; request ID tracking for cancellation
- **Image Optimization**: No new images; map tiles handled by existing flutter_map
- **Bundle Size**: No new dependencies; minimal size impact
- **Startup Time**: No impact; feature activates only on multi-city results
- **Network Efficiency**: Reuses existing geocoding call; no additional API requests; no automatic retry (single attempt)

**Status**:  No violations. Performance goals achievable with standard Flutter widgets.

### Flutter Standards  PASS
- **Dependency Management**: No new dependencies required; uses existing stack
- **State Management**: Consistent with feature 001 (StatefulWidget approach)
- **Platform Integration**: No platform-specific code required

**Status**:  No violations. Maintains consistency with existing codebase.

## Project Structure

### Documentation (this feature)

``text
specs/002-city-selection/
 plan.md              # This file (/speckit.plan command output)
 research.md          # Phase 0 output (/speckit.plan command)
 data-model.md        # Phase 1 output (/speckit.plan command)
 quickstart.md        # Phase 1 output (/speckit.plan command)
 contracts/           # Phase 1 output (/speckit.plan command)
    geocoding-api.md # Updated API contract showing multiple cities
 tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
``

### Source Code (repository root)

``text
src/app/find_map_location/
 lib/
    main.dart                          # [EXTEND] Add city selection navigation
    models/
       city.dart                      # [NEW] City entity with name, coordinates, department
       postal_code_result.dart        # [NEW] Wraps list of cities for a postal code
    services/
       geocoding_service.dart         # [EXTEND] Parse multiple cities from API response, add request ID tracking
    screens/
       postal_code_screen.dart        # [EXTEND] Handle multi-city flow, show selection, implement request ID tracking
       city_selection_screen.dart     # [NEW] Display city list with Navigator.push, two-line ListTile format
    widgets/
        city_list_item.dart            # [NEW] Individual city display with department in subtitle
        map_display.dart               # [EXIST] Reused from feature 001
 test/
    models/
       city_test.dart                 # [NEW] Unit tests for City model
       postal_code_result_test.dart   # [NEW] Unit tests for result wrapper
    services/
       geocoding_service_test.dart    # [EXTEND] Test multi-city parsing, request ID tracking
    screens/
       city_selection_screen_test.dart # [NEW] Widget tests for selection UI (two-line ListTile, 40-char names)
    widgets/
        city_list_item_test.dart       # [NEW] Widget tests for list item
 integration_test/
     multi_city_flow_test.dart          # [NEW] End-to-end test: enter code  select city  map

android/, ios/, web/, windows/, linux/, macos/
 [No changes - platform scaffolding unchanged]
``

**Structure Decision**: Mobile application (Option 3 pattern). Extends existing Flutter project structure from feature 001. New code follows established feature-first organization with models, services, screens, and widgets. All platform directories remain unchanged as this is pure Flutter/Dart code with no platform-specific integrations.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**:  No violations detected. All Constitution Check gates passed. This section intentionally left empty.

---

## Implementation Notes

### Request Cancellation Strategy (FR-010 Clarification)

**Approach**: Request ID tracking without new dependencies

Instead of adding the `dio` package for native cancellation tokens, implement request tracking using:

1. **Request ID Generation**: Generate unique ID (UUID or timestamp) for each postal code lookup
2. **State Tracking**: Store current request ID in PostalCodeScreen state
3. **Response Validation**: When response arrives, check if request ID matches current state
4. **Discard Pattern**: If IDs don't match, discard response (newer request superseded it)

**Implementation Location**: `src/app/find_map_location/lib/screens/postal_code_screen.dart`

**Benefits**:
- No new dependencies (aligns with constitution)
- Simple implementation (~10 lines of code)
- Sufficient for user-initiated actions (not continuous polling)

### UI Layout (FR-002 & FR-007 Clarifications)

**Navigation Pattern**: Full-screen with Navigator.push
- Provides natural back button behavior on Android
- Best for lists with 5+ cities
- Allows future enhancements (search, filtering)

**List Item Format**: Two-line ListTile
``dart
ListTile(
  title: Text(city.name),        // Primary: City name
  subtitle: Text(city.department), // Secondary: Department for disambiguation
  onTap: () => Navigator.pop(context, city),
)
``

**Benefits**:
- Better visual hierarchy (scan city names first)
- More scannable than inline parentheses
- Follows Material Design list patterns

### Test Coverage for Edge Cases

**Long Name Testing** (40-character threshold):
- Test city: "Saint-Rémy-en-Bouzemont-Saint-Genest-et-Isson" (48 chars)
- Verify text wrapping without overflow
- Verify ListTile height adjusts appropriately

**No Retry Policy**:
- Single API attempt per postal code submission
- Network/timeout errors show clear message
- User must manually retry by resubmitting

---

## Post-Phase 1 Constitution Re-evaluation

**Date**: 2025-12-13
**Status**:  PASS - All principles remain satisfied after design phase

### Re-evaluation Summary

After completing Phase 0 (research) and Phase 1 (design), the implementation plan was re-evaluated against the constitution:

1. **Code Quality & Maintainability**:  Confirmed
   - Data model uses immutable classes with const constructors
   - Clear separation: models (City, PostalCodeResult), services (GeocodingService with request ID tracking), UI (CitySelectionScreen with Navigator.push)
   - No implementation complexity added beyond necessary domain logic

2. **Test-First Development**:  Confirmed
   - Quickstart.md demonstrates TDD approach for all new components
   - Unit tests for models (City, PostalCodeResult)
   - Service tests for multi-city parsing and request ID tracking
   - Widget tests for selection screen (two-line ListTile format, 40-char names)
   - Integration test for end-to-end flow

3. **User Experience Consistency**:  Confirmed
   - Material Design ListView.builder with two-line ListTile (city in title, department in subtitle)
   - Full-screen navigation with Navigator.push/pop (natural back button)
   - Maintains feature 001 UX for single-city results
   - Clear error messages aligned with spec requirements; no automatic retry

4. **Performance & Efficiency**:  Confirmed
   - ListView.builder provides lazy loading for city lists
   - No additional API calls (single request returns all cities)
   - Request ID tracking adds minimal overhead (<1ms)
   - Performance goals (<2s selection, <500ms display) achievable
   - No new dependencies; minimal bundle size impact

**Clarifications Impact**: All 5 clarifications maintain constitution compliance:
- Request ID tracking: No new dependencies 
- Navigator.push: Standard Material pattern 
- Two-line ListTile: Material Design compliant 
- 40-char threshold: Testable edge case 
- No retry: Simpler implementation, clearer UX 

**Conclusion**: Design phase introduced no constitution violations. Implementation can proceed to Phase 2 (tasks breakdown via `/speckit.tasks` command).

---

## Next Steps

1. **Review**: Team reviews plan.md, research.md, data-model.md, contracts/, and quickstart.md
2. **Tasks Breakdown**: Run `/speckit.tasks` to generate granular implementation tasks (if not already generated)
3. **Implementation**: Follow TDD approach outlined in quickstart.md
4. **Testing**: Maintain 80% logic / 60% UI coverage targets
5. **Code Review**: Verify constitution compliance and clarifications implementation during PR review

``
