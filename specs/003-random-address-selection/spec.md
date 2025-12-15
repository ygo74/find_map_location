# Feature Specification: Random Address Selection for Location Game

**Feature Branch**: `003-random-address-selection`
**Created**: 2025-12-14
**Status**: Draft
**Input**: User description: "Une fois que la ville a été sélectionnée et affichée sur la carte, proposer à l'utilisateur une adresse au hasard dans la ville sélectionnée pour qu'il puisse la retrouver le plus vite. Dans cette spécification, mettre en place la sélection d'une adresse au hasard et l'afficher à l'écran"

## Clarifications

### Session 2025-12-14

- Q: Which approach should be used to generate random addresses within a city? → A: Generate random coordinates within the city's bounding box, then use reverse geocoding to find the nearest real address
- Q: What should happen to the "Start Search" button after the user presses it? → A: Button remains visible but becomes disabled (grayed out, non-interactive)
- Q: How should the user's location data be handled after the "Start Search" button is pressed? → A: Don't store location data - use it only transiently for the zoom operation, then discard immediately
- Q: What minimum number of addresses should a city have to be eligible for the random address game? → A: At least 5 valid addresses required for reasonable variety
- Q: What zoom level should be used when the map zooms to the user's location after pressing "Start Search"? → A: Street-level zoom (detailed view)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Random Address Display After City Selection (Priority: P1)

After a user has selected a city and the map is displayed, the application randomly selects an address within that city and prominently displays it on the screen as text only. The address is NOT marked or highlighted on the map itself - the user must find it manually, which is the core game mechanic. The user can see the address information clearly, which serves as the target for the location game.

**Why this priority**: This is the core functionality that transforms the application from a simple city locator into a game. Without a random address to find, there is no game objective. This is the essential first step for the gaming experience. Keeping the address hidden on the map creates the challenge.

**Independent Test**: Can be fully tested by completing city selection, confirming an address appears as text on screen, verifying no marker/highlight appears on the map for that address, confirming the address format is complete and readable, and checking that the address changes when repeating the flow with the same city.

**Acceptance Scenarios**:

1. **Given** the user has successfully selected a city and the map is displayed, **When** the system loads the map view, **Then** a random address within that city is displayed prominently on the screen as text
2. **Given** a random address is displayed as text, **When** the user views the map, **Then** the address location is NOT marked, highlighted, or indicated on the map in any way
3. **Given** an address is displayed on the screen, **When** the user views the address information, **Then** the address includes street name, street number, and city name in a readable format
4. **Given** the user completes the city selection process twice for the same city, **When** the system displays addresses for both attempts, **Then** the two addresses are different (demonstrating randomness)
5. **Given** the map is showing a city with a random address displayed, **When** the user selects a different city, **Then** a new random address from the new city replaces the previous address

---

### User Story 2 - Address Selection from Valid Locations (Priority: P2)

When the system selects a random address within a city, it ensures the address is a real, valid location that exists within the city boundaries. The system generates random coordinates within the city's bounding box and uses reverse geocoding to find the nearest real address at those coordinates.

**Why this priority**: Ensures game quality by preventing impossible-to-find or nonsensical addresses. While the display (P1) works independently, this ensures the addresses shown are meaningful and achievable game targets. This enhances user trust and game fairness.

**Independent Test**: Can be fully tested by reviewing multiple randomly generated addresses for a city, verifying each one through reverse geocoding or address validation, and confirming they exist within the city bounds.

**Acceptance Scenarios**:

1. **Given** the system is selecting a random address for Paris, **When** the address is generated, **Then** the address corresponds to a real location within Paris city boundaries
2. **Given** multiple random addresses are generated for the same city, **When** reviewing the addresses, **Then** all addresses represent actual locations that could be navigated to on the map
3. **Given** the system generates an address for a small village, **When** the address is displayed, **Then** the address exists within that village's geographic area

---

### User Story 3 - Start Search Button to Begin Game (Priority: P3)

After the random address is displayed, a "Start Search" button allows the user to officially begin the game. When activated, the map zooms to the user's current location (if available), providing a starting point for their search. This gives users control over when they begin and establishes their reference point.

**Why this priority**: Enhances user experience by providing clear game initiation and helpful starting context (current location), but the core game (address display and finding) can function without it. Users could search immediately after seeing the address, but this improves the flow.

**Independent Test**: Can be fully tested by displaying a random address, verifying the "Start Search" button appears, tapping the button, and confirming the map zooms to the user's current location.

**Acceptance Scenarios**:

1. **Given** a random address is displayed after city selection, **When** the user views the screen, **Then** a "Start Search" button is prominently displayed
2. **Given** the "Start Search" button is visible, **When** the user taps the button and location permissions are granted, **Then** the map zooms to the user's current geographic location at street-level detail and the button becomes disabled (grayed out)
3. **Given** the user's current location is not available (permissions denied or location unavailable), **When** the user taps "Start Search", **Then** the map remains at the city-level view without zooming and the button becomes disabled
4. **Given** the map has zoomed to the user's location, **When** the zoom completes, **Then** the random address text remains visible on screen for reference
5. **Given** the "Start Search" button has been pressed and is now disabled, **When** the user views the button, **Then** it appears grayed out and is non-interactive

---

### User Story 4 - Visual Prominence of Target Address (Priority: P4)

The random address is displayed in a visually distinct area of the screen, making it easy for users to reference while searching the map. The display remains visible and accessible throughout the game session without obstructing map interaction.

**Why this priority**: Improves usability and user experience but doesn't affect core functionality. Users can play the game even with suboptimal address placement. This is about optimization rather than fundamental capability.

**Independent Test**: Can be fully tested by displaying addresses and evaluating visibility, readability at various screen sizes, and whether the address information remains accessible while panning/zooming the map.

**Acceptance Scenarios**:

1. **Given** a random address is displayed, **When** the user views the screen, **Then** the address is positioned in a dedicated area that doesn't overlap with map controls or city information
2. **Given** the user is actively panning and zooming the map, **When** interacting with the map, **Then** the target address remains visible and readable
3. **Given** addresses of varying lengths are displayed (short vs. long street names), **When** viewing different addresses, **Then** all addresses fit within the display area without truncation or overflow

---

### Edge Cases

- **City with very few addresses**: When a selected city has fewer than 5 valid addresses, the system displays a message: "This location has too few addresses for the game. Please select a different city." Cities must have at least 5 addresses to provide reasonable gameplay variety.
- **Address API returns no results**: When the address lookup service fails or returns no valid addresses for a city, display a fallback message: "Unable to generate address for this location. Please check your connection and try again."
- **Address with special characters**: When an address contains special characters (accents, hyphens, apostrophes like "Rue de l'Église"), the system displays them correctly without encoding errors
- **Rapid city changes**: When a user quickly switches between cities before the previous address generation completes, the system cancels the pending request and displays only the address for the most recent city
- **Same address generated consecutively**: When pure randomness selects the same address twice in a row for the same city, the system accepts this outcome (true randomness allows repetition, though rare)
- **Location permission denied**: When the user taps "Start Search" but has denied location permissions, the map remains at the current city-level view and the game can still be played without the location zoom feature
- **Location unavailable**: When the user's device cannot determine current location (GPS off, no signal), tapping "Start Search" keeps the map at city level and displays a brief message: "Location unavailable - search from city view"
- **Start button pressed multiple times**: When the user taps "Start Search" multiple times rapidly, the system processes only the first tap, disables the button immediately, and subsequent taps have no effect

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST automatically select a random address within the displayed city after the city map is loaded
- **FR-002**: System MUST display the randomly selected address on the screen as text only in a clear, readable format
- **FR-003**: System MUST NOT mark, highlight, or indicate the address location on the map (address remains hidden for the game)
- **FR-004**: System MUST include complete address information: street number, street name, and city name
- **FR-005**: System MUST generate different random addresses each time the user selects the same city (demonstrating true randomness)
- **FR-006**: System MUST ensure selected addresses correspond to real, valid locations within the city boundaries by generating random coordinates within the city's bounding box and using reverse geocoding to obtain the nearest address
- **FR-007**: System MUST update the displayed address when the user selects a different city
- **FR-008**: System MUST handle cities with limited address availability (small villages) without errors
- **FR-019**: System MUST require cities to have at least 5 valid addresses to be eligible for the game; cities with fewer addresses display an informative message directing users to select a different city
- **FR-009**: System MUST display special characters in addresses correctly (accents, apostrophes, hyphens)
- **FR-010**: System MUST show an appropriate error message when address generation fails
- **FR-011**: System MUST cancel pending address requests when the user selects a new city before the previous request completes
- **FR-012**: System MUST position the address display in a location that remains visible during map interaction without obstructing map controls
- **FR-013**: System MUST display a "Start Search" button after the random address is shown
- **FR-014**: System MUST zoom the map to the user's current location at street-level detail when the "Start Search" button is tapped (if location is available)
- **FR-015**: System MUST handle cases where user location is unavailable or permission is denied by keeping the map at city-level view
- **FR-016**: System MUST prevent multiple simultaneous zoom operations when "Start Search" is tapped repeatedly by disabling the button after first press
- **FR-017**: System MUST change the "Start Search" button to a disabled state (grayed out, non-interactive) immediately after it is pressed
- **FR-018**: System MUST NOT store or persist user location data; location is used only transiently for the zoom operation and immediately discarded

### Key Entities

- **Random Address**: Represents a specific address within the selected city, containing street number, street name, city name, and geographic coordinates. Serves as the game target that users must locate. The coordinates are used for validation but NOT displayed on the map.
- **Address Selection Result**: Contains the randomly selected address and indicates whether the selection was successful or encountered an error. Links to the current city context.
- **City Context**: Represents the currently selected city for which addresses are being generated, including the city's geographic boundaries used to validate address selection.
- **User Location**: Represents the player's current geographic position (latitude/longitude) obtained from device location services. Used transiently only for the map zoom operation when "Start Search" is activated, then immediately discarded without storage.
- **Game Session State**: Tracks the current game phase including whether an address has been generated and whether the search has been started.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users see a random address displayed on screen within 2 seconds of city selection completion in 95% of cases
- **SC-002**: 99% of generated addresses are unique when selecting the same city multiple times within a session
- **SC-003**: Address display remains readable and accessible on devices ranging from small phones (5 inches) to tablets (10+ inches)
- **SC-004**: System successfully generates valid addresses for 98% of city selections under normal network conditions
- **SC-005**: Users can clearly read and understand the displayed address without confusion in 95% of user testing sessions
- **SC-006**: The address target location is never visible on the map (100% hidden from visual indicators)
- **SC-007**: When location is available, map zooms to user's current position within 1 second of tapping "Start Search" in 90% of cases
- **SC-008**: Game remains playable (address findable) even when user location is unavailable in 100% of cases
