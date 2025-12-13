# Implementation Plan: Postal Code Map Viewer

**Branch**: `001-postal-code-map` | **Date**: 2025-12-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-postal-code-map/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a Flutter mobile application that allows users to enter French postal codes (5 digits) and view the corresponding city location on an interactive map. The feature includes format validation, geocoding lookup, map display with zoom level 13, and comprehensive error handling for network issues, invalid formats, and non-existent postal codes. Technical approach uses minimal Flutter dependencies with flutter_map for mapping and http for geocoding API calls.

## Technical Context

**Language/Version**: Dart 3.10.4+ / Flutter 3.x (Flutter SDK from pubspec.yaml: ^3.10.4)
**Primary Dependencies**:
- `flutter_map` (^7.0.0) - OpenStreetMap integration for interactive maps
- `latlong2` (^0.9.0) - Geographic coordinate handling
- `http` (^1.2.0) - HTTP client for geocoding API calls
- `flutter_lints` (^6.0.0) - Linting rules (dev dependency)
- State Management: Built-in `StatefulWidget` (no external state management library for MVP simplicity)

**Storage**: N/A (no persistent storage required; all data fetched on-demand)

**Testing**:
- `flutter_test` (SDK) - Unit and widget testing
- `integration_test` (SDK) - End-to-end testing
- `mocktail` or `mockito` - HTTP mocking for unit tests

**Target Platform**: iOS 12+ and Android API 21+ (mobile-first, cross-platform)

**Project Type**: Mobile (single Flutter application)

**Performance Goals**:
- 60fps UI rendering during map interactions
- <500ms format validation response
- <5 seconds postal code lookup to map display
- <3 seconds cold start time

**Constraints**:
- Internet connectivity required (no offline mode)
- Geocoding API rate limits (implementation must handle 429 responses)
- Map tiles cached by flutter_map (reduces bandwidth)
- Request cancellation for concurrent submissions (latest-wins pattern)

**Scale/Scope**:
- Single screen application (postal code input + map display)
- ~5-8 source files (main, models, services, widgets)
- Support thousands of daily postal code lookups per user
- Minimal app size (<10MB)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Code Quality & Maintainability ✅ PASS
- **Static Analysis**: Plan includes `flutter analyze` requirement
- **Linting**: `flutter_lints` ^6.0.0 specified in dependencies
- **Architecture**: Feature-first structure planned (models/, services/, widgets/)
- **Immutability**: Dart language supports const constructors naturally
- **Null Safety**: Dart 3.10.4+ enforces null safety
- **Documentation**: Dartdoc comments required for public APIs per constitution

**Status**: ✅ No violations. All requirements can be met with planned approach.

### Principle II: Test-First Development ✅ PASS
- **TDD Cycle**: Implementation plan will include test tasks before implementation
- **Coverage Gates**: 80% logic / 60% UI achievable with planned test structure
- **Test Pyramid**: Unit (postal code validation, geocoding logic), Widget (input/map display), Integration (full flow)
- **Widget Testing**: `flutter_test` SDK included; custom widgets will have tests
- **Golden Tests**: Not strictly required for single-screen MVP but can be added
- **Integration Tests**: `integration_test` SDK available for end-to-end flows

**Status**: ✅ No violations. Testing infrastructure planned and constitution-compliant.

### Principle III: User Experience Consistency ✅ PASS
- **Material Design**: Flutter's Material widgets follow MD3 guidelines by default
- **Responsive Design**: Single screen adapts naturally; map fills available space
- **Platform Conventions**: Flutter handles iOS/Android conventions automatically
- **Accessibility**: Semantic labels required per spec (FR-accessible interactions)
- **Theme System**: Flutter's ThemeData provides centralized theming
- **Loading States**: CircularProgressIndicator during lookup (FR-007)
- **Error Handling**: All error messages specified in spec (FR-003, FR-010, FR-011)

**Status**: ✅ No violations. UX requirements align with constitution principles.

### Principle IV: Performance & Efficiency ✅ PASS
- **Build Performance**: Single screen with StatefulWidget; no complex lists requiring optimization
- **Frame Rate**: 60fps target specified; map interactions use flutter_map's optimized rendering
- **Memory Management**: Controllers/streams disposal will be enforced in code reviews
- **Image Optimization**: Map tiles handled by flutter_map caching
- **Bundle Size**: Minimal dependencies (<10MB target); no heavy packages
- **Startup Time**: <3 seconds target specified and achievable for single-screen app
- **Network Efficiency**: Request cancellation (FR-013), error handling (FR-011)

**Status**: ✅ No violations. Performance goals align with constitution requirements.

### Flutter Standards ✅ PASS
- **Dependency Management**: All dependencies pinned with caret syntax; reasons documented
- **State Management**: StatefulWidget choice documented (simplicity for MVP)
- **Platform Integration**: No platform-specific code required for this feature

**Status**: ✅ No violations. Flutter-specific standards met.

### Summary
✅ **ALL GATES PASSED** - No constitution violations. Proceed to Phase 0 research.

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
│   ├── main.dart                    # Application entry point
│   ├── models/
│   │   ├── postal_code.dart         # PostalCode value object with validation
│   │   ├── city_location.dart       # CityLocation entity (coordinates, name)
│   │   └── map_state.dart           # MapState enum (loading, displayed, error)
│   ├── services/
│   │   └── geocoding_service.dart   # Geocoding API client (postal code → coordinates)
│   ├── widgets/
│   │   ├── postal_code_input.dart   # Input field + submit button widget
│   │   └── map_display.dart         # flutter_map integration widget
│   └── screens/
│       └── home_screen.dart         # Main screen combining input + map
├── test/
│   ├── models/
│   │   ├── postal_code_test.dart    # Unit tests for validation logic
│   │   └── city_location_test.dart  # Unit tests for location model
│   ├── services/
│   │   └── geocoding_service_test.dart  # Unit tests with mocked HTTP
│   ├── widgets/
│   │   ├── postal_code_input_test.dart  # Widget tests for input
│   │   └── map_display_test.dart        # Widget tests for map
│   └── integration_test/
│       └── app_test.dart            # End-to-end flow tests
├── pubspec.yaml                     # Dependencies and configuration
├── analysis_options.yaml            # Lint rules configuration
└── README.md                        # Project documentation

# Platform-specific directories (existing Flutter structure)
android/                             # Android configuration (existing)
ios/                                 # iOS configuration (existing)
```

**Structure Decision**: Using Flutter's standard mobile application structure. The `lib/` directory contains all Dart source code organized by feature (models, services, widgets, screens). Tests mirror the `lib/` structure in the `test/` directory following Flutter conventions. This is a single-screen application, so the screen hierarchy is flat. Platform-specific directories (android/, ios/) already exist from `flutter create` and require no modifications for this feature.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: ✅ No complexity violations. All constitution gates passed without requiring justifications.

---

## Post-Design Constitution Re-Check

*GATE: Re-evaluated after Phase 1 design completion (2025-12-13)*

### Design Artifacts Reviewed
- ✅ research.md: Technical decisions documented (flutter_map, API Adresse, StatefulWidget)
- ✅ data-model.md: 5 entities defined with immutability and null safety
- ✅ contracts/geocoding-api.md: API contract documented with error handling
- ✅ quickstart.md: TDD implementation guide with test-first examples

### Constitution Compliance After Design

**Principle I: Code Quality & Maintainability** ✅ CONFIRMED
- Data model uses immutable entities (`final` fields, `const` constructors)
- Clear separation: models/, services/, widgets/, screens/
- Null safety enforced (`String?`, `CityLocation?`)
- Documentation contracts defined in quickstart

**Principle II: Test-First Development** ✅ CONFIRMED
- Quickstart includes test-first examples for all components
- Test structure mirrors implementation (models/, services/, widgets/)
- Mock HTTP client pattern documented for service testing
- Integration test path defined

**Principle III: User Experience Consistency** ✅ CONFIRMED
- All error messages specified per FR requirements
- Loading states defined (CircularProgressIndicator)
- Material Design widgets used throughout
- Attribution requirements documented for map display

**Principle IV: Performance & Efficiency** ✅ CONFIRMED
- Request cancellation pattern documented (FR-013)
- Timeout configured (10 seconds)
- Map tile caching handled by flutter_map
- No memory leaks (controllers disposed in dispose() method)

**Flutter Standards** ✅ CONFIRMED
- Dependencies documented with versions and rationale
- StatefulWidget justification: simplicity for single-screen MVP
- No platform-specific code required

### Final Verdict
✅ **ALL GATES STILL PASSING** - Design maintains constitution compliance. Ready for implementation via `/speckit.tasks`.
