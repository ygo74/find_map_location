<!--
SYNC IMPACT REPORT
==================
Version Change: 0.0.0 → 1.0.0
Modified Principles: N/A (Initial ratification)
Added Sections:
  - Core Principles (I-IV): Code Quality, Testing Standards, User Experience, Performance
  - Flutter Standards
  - Quality Gates
  - Governance
Templates Status:
  ✅ plan-template.md - Constitution Check section confirmed compatible
  ✅ spec-template.md - User scenarios and requirements align with principles
  ✅ tasks-template.md - Task categorization supports test-first and incremental delivery
Follow-up TODOs: None
==================
-->

# Find Map Location Constitution

## Core Principles

### I. Code Quality & Maintainability (NON-NEGOTIABLE)

All code MUST adhere to strict quality standards to ensure long-term maintainability:

- **Static Analysis**: Code MUST pass `flutter analyze` with zero warnings or errors before commit
- **Linting**: All code MUST comply with `flutter_lints` rules; violations require explicit justification
- **Architecture**: Follow feature-first organization with clear separation of concerns (UI, business logic, data)
- **Immutability**: Prefer immutable data structures; use `const` constructors wherever possible
- **Null Safety**: Full null safety compliance required; no `!` operator without documented justification
- **Documentation**: All public APIs MUST have dartdoc comments explaining purpose, parameters, and return values

**Rationale**: Flutter projects deteriorate rapidly without disciplined quality practices. Static analysis catches issues early, reducing technical debt and preventing production defects.

### II. Test-First Development (NON-NEGOTIABLE)

Testing is mandatory and MUST follow test-driven development principles:

- **TDD Cycle**: Write tests → Review with user → Ensure tests fail → Implement → Verify tests pass
- **Coverage Gates**: Minimum 80% code coverage for business logic; 60% for UI widgets
- **Test Pyramid**: Emphasize unit tests (70%), integration/widget tests (20%), end-to-end tests (10%)
- **Widget Testing**: Every custom widget MUST have widget tests verifying rendering and user interactions
- **Golden Tests**: Critical UI screens MUST have golden/screenshot tests for visual regression detection
- **Integration Tests**: User workflows spanning multiple screens require integration tests using `integration_test` package

**Rationale**: Mobile apps have limited debugging in production. Comprehensive testing catches issues before users encounter them, and test-first design produces cleaner, more modular code.

### III. User Experience Consistency

UI/UX MUST be consistent, predictable, and platform-appropriate:

- **Material Design**: Follow Material Design 3 guidelines for component usage, spacing, and interaction patterns
- **Responsive Design**: UI MUST adapt gracefully to different screen sizes (phones, tablets, foldables)
- **Platform Conventions**: Respect iOS and Android platform conventions (navigation patterns, gestures, system integration)
- **Accessibility**: All interactive elements MUST have semantic labels; minimum touch target 48x48dp; support screen readers
- **Theme System**: Use centralized theme configuration; no hardcoded colors or typography outside theme definitions
- **Loading States**: All async operations MUST provide visual feedback (progress indicators, skeleton screens)
- **Error Handling**: User-facing errors MUST be actionable with clear next steps; no technical jargon

**Rationale**: Inconsistent UX erodes user trust and increases support burden. Platform-appropriate design ensures users feel familiar and confident using the application.

### IV. Performance & Efficiency

Application MUST be performant and resource-efficient across devices:

- **Build Performance**: ListView/GridView MUST use lazy loading; avoid rebuilding widgets unnecessarily
- **Frame Rate**: Maintain 60fps on target devices; use Flutter DevTools to identify jank
- **Memory Management**: Dispose controllers, streams, and listeners properly; monitor memory usage in DevTools
- **Image Optimization**: Use appropriate image formats and sizes; implement caching for network images
- **Bundle Size**: Monitor app size; lazy-load features when possible; remove unused dependencies
- **Startup Time**: Cold start MUST complete within 3 seconds on mid-range devices
- **Network Efficiency**: Implement request caching, retry logic, and offline-first patterns where appropriate

**Rationale**: Poor performance directly impacts user retention. Mobile users expect fast, fluid experiences and will abandon apps that feel sluggish or drain battery.

## Flutter Standards

### Dependency Management

- Keep dependencies up-to-date; review breaking changes before upgrading
- Pin major versions; use caret syntax for minor/patch updates
- Document reason for each dependency in pubspec.yaml comments
- Prefer official/well-maintained packages over abandoned alternatives

### State Management

- Choose state management approach based on complexity (Provider, Riverpod, Bloc, etc.)
- State management choice MUST be documented in technical context and consistently applied
- Avoid mixing state management approaches without architectural justification

### Platform Integration

- Abstract platform-specific code using platform channels or federated plugins
- Test platform integrations on both iOS and Android
- Document platform-specific behavior and limitations

## Quality Gates

All features MUST pass these gates before merge:

1. **Static Analysis**: `flutter analyze` returns zero issues
2. **Test Execution**: All tests pass; coverage meets minimums (80% logic, 60% UI)
3. **Code Review**: At least one reviewer approval; architecture alignment verified
4. **Performance Check**: No frame drops during testing; memory leaks verified absent
5. **Constitution Compliance**: Principles I-IV verified during review

**Complex Feature Gate**: Features adding significant complexity (new dependencies, architectural changes, breaking changes) require:
- Architectural Decision Record (ADR) documenting rationale
- Migration plan for breaking changes
- Performance benchmarks demonstrating no regression

## Governance

This constitution supersedes all other development practices and style guides. All code reviews, pull requests, and architectural decisions MUST verify compliance with these principles.

**Amendment Process**:
- Proposed amendments require documented rationale and impact analysis
- Amendments MUST update version following semantic versioning rules
- Breaking principle changes require migration plan for existing code
- All templates and documentation MUST be updated to reflect amendments

**Version Control**:
- MAJOR: Removal or backward-incompatible redefinition of core principles
- MINOR: Addition of new principles or significant expansion of existing guidance
- PATCH: Clarifications, wording improvements, or non-semantic refinements

**Enforcement**: The `/speckit.plan` command performs constitution checks before research begins. Violations MUST be justified in the complexity tracking section of implementation plans.

**Version**: 1.0.0 | **Ratified**: 2025-12-13 | **Last Amended**: 2025-12-13
