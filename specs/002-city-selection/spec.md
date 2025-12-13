# Feature Specification: City Selection for Duplicate Postal Codes

**Feature Branch**: `002-city-selection`
**Created**: 2025-12-13
**Status**: Draft
**Input**: User description: "Il peut exister plusieurs villes / villages pour un même code postal. Si c'est le cas je souhaite ajouter une sélection de la ville à afficher à l'utilisateur. Après sélection de la ville, la carte se positionne sur la ville"

## Clarifications

### Session 2025-12-13

- Q: How should request cancellation be implemented when users rapidly change postal codes (FR-010)? → A: Use existing http package with Future tracking and ignore outdated responses (check request ID on response, discard if superseded)
- Q: Should the city selection interface be presented as a modal bottom sheet, full screen, or dialog? → A: Full screen with Navigator.push (new route on navigation stack, natural back button, best for 5+ cities)
- Q: What format should be used for displaying department names for disambiguation (FR-007)? → A: Subtitle format: City name in title, department in subtitle (two-line ListTile with subtitle property)
- Q: What character length threshold defines "very long city names" for testing purposes? → A: 40 characters
- Q: Should the system implement automatic retry logic for transient API failures? → A: No automatic retry - single attempt with clear error message

## User Scenarios & Testing *(mandatory)*

### User Story 1 - City Selection for Postal Codes with Multiple Locations (Priority: P1)

A user enters a postal code that corresponds to multiple cities or villages (e.g., "01630" corresponds to Saint-Genis-Pouilly, Péron, and Sergy). The application displays a list of all matching cities, and the user selects the desired city from the list. After selection, the map centers on the chosen city's location.

**Why this priority**: This is the core functionality of the feature. Without the ability to select from multiple cities when a postal code has several matches, users cannot access the correct location for their intended destination. This directly addresses the ambiguity problem.

**Independent Test**: Can be fully tested by entering a postal code with multiple cities (e.g., "01630"), verifying a selection list appears with all city names, selecting one city, and confirming the map centers on that specific city's location.

**Acceptance Scenarios**:

1. **Given** the user enters postal code "01630" (which has 3 cities), **When** they tap submit, **Then** a selection list displays all 3 city names (Saint-Genis-Pouilly, Péron, Sergy)
2. **Given** a selection list is displayed with multiple cities, **When** the user selects "Saint-Genis-Pouilly", **Then** the map centers on Saint-Genis-Pouilly's coordinates
3. **Given** a selection list is displayed with multiple cities, **When** the user selects "Péron", **Then** the map centers on Péron's coordinates
4. **Given** the map is showing a previously selected city, **When** the user enters another multi-city postal code and selects a different city, **Then** the map updates to the newly selected city's location

---

### User Story 2 - Single City Result Bypasses Selection (Priority: P2)

A user enters a postal code that corresponds to only one city. The application automatically displays the map for that single city without showing a selection interface, maintaining the streamlined experience from the original feature.

**Why this priority**: This ensures backward compatibility and optimal user experience when no ambiguity exists. Users shouldn't be forced through an extra step when there's only one possible result. However, the core value (handling multiple cities) works independently of this optimization.

**Independent Test**: Can be fully tested by entering a postal code with a single city (e.g., "75001"), verifying no selection list appears, and confirming the map displays immediately.

**Acceptance Scenarios**:

1. **Given** the user enters postal code "75001" (which has 1 city), **When** they tap submit, **Then** the map displays Paris 1st arrondissement immediately without showing a selection list
2. **Given** the user has just selected a city from a multi-city postal code, **When** they enter a single-city postal code, **Then** the map updates directly without showing a selection list

---

### User Story 3 - Cancel City Selection (Priority: P3)

A user is viewing the city selection list after entering a postal code with multiple matches. The user realizes they entered the wrong postal code or changes their mind. They can dismiss the selection list and return to the postal code entry to enter a different code.

**Why this priority**: Provides escape mechanism for user errors but is not essential for core functionality. Users can work around this by simply entering a new postal code, which could automatically dismiss the selection list.

**Independent Test**: Can be fully tested by entering a multi-city postal code, verifying the selection list appears, dismissing/canceling the list, and confirming the user can enter a new postal code.

**Acceptance Scenarios**:

1. **Given** a city selection list is displayed, **When** the user taps a "Cancel" or "Back" button, **Then** the selection list closes and the postal code entry field remains accessible
2. **Given** a city selection list is displayed, **When** the user enters a new postal code in the input field, **Then** the current selection list is replaced with results for the new postal code

---

### Edge Cases

- **Two cities with identical names**: When a postal code returns multiple results including cities with the same name (e.g., two villages named "Saint-Martin"), the selection list displays city name in title with department name in subtitle (e.g., title: "Saint-Martin", subtitle: "Ain" vs title: "Saint-Martin", subtitle: "Savoie")
- **Very long city names**: When city names exceed 40 characters, the selection list wraps text appropriately to maintain readable formatting without horizontal scrolling
- **Network failure during city list retrieval**: When the geocoding API fails while fetching city list for a postal code, an error message displays: "Unable to retrieve city list. Please check your connection and try again." (no automatic retry; user must manually retry by resubmitting)
- **Empty city list returned**: When the API returns an empty list for a valid postal code format (unexpected API behavior), display error message: "No cities found for this postal code. Please verify and try again."
- **User rapidly changes postal codes**: When the user enters a new postal code while a city selection list is still being retrieved, cancel the previous request and fetch results for the new postal code (latest-wins pattern)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect when a postal code lookup returns multiple cities/villages
- **FR-002**: System MUST display a selection interface showing all city names when multiple matches exist (implemented as full-screen route using Navigator.push)
- **FR-003**: System MUST allow user to select one city from the list of multiple matches
- **FR-004**: System MUST center the map on the selected city's coordinates after user selection
- **FR-005**: System MUST bypass the selection interface and display the map immediately when a postal code returns only one city
- **FR-006**: System MUST provide city names in a readable, scannable list format
- **FR-007**: System MUST include disambiguating information (department name) when multiple cities have identical names, displayed as city name in ListTile title with department in subtitle
- **FR-008**: System MUST allow user to dismiss/cancel the city selection and return to postal code entry
- **FR-009**: System MUST handle empty or malformed city list responses from the geocoding API with appropriate error messages
- **FR-010**: System MUST cancel pending city list requests when user enters a new postal code (latest-wins pattern), implemented via request ID tracking to discard outdated responses without additional dependencies

### Key Entities

- **City/Village**: Represents a municipality with attributes including name, geographic coordinates (latitude/longitude), and optionally department or region for disambiguation. Multiple cities may share the same postal code.
- **Postal Code Lookup Result**: Contains the postal code queried and a collection of one or more City entities. Used to determine whether selection interface is needed.
- **City Selection**: Represents the user's choice of a specific city from multiple options, containing the selected city entity and triggering map positioning.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully identify and select their intended city from a list when entering a postal code with multiple matches (95% task completion rate)
- **SC-002**: Users viewing postal codes with single city results experience no additional steps compared to the original feature (0 extra taps/clicks for single-city lookups)
- **SC-003**: City selection and map positioning completes within 2 seconds of user selecting a city from the list
- **SC-004**: Users can distinguish between cities with similar or identical names through provided disambiguating information (90% users select correct city on first attempt)
- **SC-005**: System correctly handles all postal codes regardless of whether they map to 1, 2, 5, or more cities without errors

## Assumptions *(include if feature has implicit assumptions)*

- **Assumption 1**: The geocoding API used for postal code lookups returns all cities associated with a postal code in a single response
- **Assumption 2**: The geocoding API provides sufficient metadata (e.g., city name, coordinates, department) to enable disambiguation
- **Assumption 3**: Users are familiar with their intended city/village name and can recognize it in a list
- **Assumption 4**: The number of cities per postal code typically ranges from 1-10; extremely long lists (>20 cities) are rare
- **Assumption 5**: Users entering postal codes expect to see familiar city names in French language

## Dependencies *(include if feature depends on external factors)*

- **Dependency 1**: Requires feature 001-postal-code-map to be implemented and functional (provides base postal code lookup and map display functionality)
- **Dependency 2**: Requires geocoding API to return structured data including all cities for a postal code, not just the first match
- **Dependency 3**: Requires geocoding API to provide city-level coordinates for accurate map positioning

## Open Questions

No open questions at this time. All requirements are clear and testable based on the user's description.
