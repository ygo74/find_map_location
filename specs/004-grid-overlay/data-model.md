# Data Model: Carte avec Carroyage Alphanumérique

**Feature**: 004-grid-overlay | **Date**: 2025-12-16
**Purpose**: Phase 1 data model design for grid overlay entities

## Core Entities

### 1. GridCell

Represents a single cell in the grid overlay.

**Attributes**:
- `id` (String): Alphanumeric identifier (e.g., "A1", "C7", "AB25")
- `columnIndex` (int): Zero-based column index (0 = A, 1 = B, ...)
- `rowIndex` (int): Zero-based row index (0 = row 1, 1 = row 2, ...)
- `bounds` (LatLngBounds): Geographic boundaries of the cell (north, south, east, west coordinates)
- `centerPoint` (LatLng): Geographic center of the cell

**Relationships**:
- Belongs to a `GridConfiguration` (defines cell size)
- Contains zero or one `AddressPoint` (for game solution)

**Validation Rules**:
- `id` must match pattern: `^[A-Z]+[0-9]+$` (e.g., "A1", "AA10")
- `columnIndex` and `rowIndex` must be non-negative
- `bounds` must represent a valid rectangular area (north > south, east > west)

**State Transitions**:
- Created when grid is first initialized (origin calculated)
- Immutable once created (cells don't change during session)
- Discarded when grid is reinitialized (new session or size change)

**Derived Fields**:
- `id` is derived from `columnIndex` and `rowIndex`:
  - Column letter: Base-26 conversion of `columnIndex`
  - Row number: `rowIndex + 1` (1-based display)

---

### 2. GridConfiguration

Represents the configuration and state of the grid overlay.

**Attributes**:
- `cellSizeMeters` (int): Size of each cell in meters (one of: 250, 500, 1000, 2000)
- `origin` (LatLng?): Geographic origin point (top-left of cell A1); null if not yet initialized
- `isVisible` (bool): Whether grid overlay is currently displayed
- `visibleCells` (List<GridCell>): Cells currently visible in map viewport (computed)

**Relationships**:
- Has many `GridCell` instances (generated on-demand for visible area)
- References current `AddressPoint` (if address searched)

**Validation Rules**:
- `cellSizeMeters` must be one of: 250, 500, 1000, 2000 (predefined values from spec)
- `origin` can be null (before first address search) or valid LatLng
- `visibleCells` automatically computed based on map viewport bounds

**State Transitions**:
1. **Initial**: `cellSizeMeters = 500` (default), `origin = null`, `isVisible = false`
2. **Origin Set**: After first address search, `origin` set to calculated position, `isVisible = true`
3. **Size Changed**: User changes `cellSizeMeters` in settings → grid recalculates with new size, same origin
4. **Session Reset**: App restart → returns to Initial state (origin cleared)

**Persistence**:
- `cellSizeMeters` persisted via shared_preferences (FR-009)
- `origin` NOT persisted (calculated fresh each session)
- `isVisible` derived from presence of origin

---

### 3. AddressPoint

Represents the geographic location of a searched address (used for grid overlay game).

**Attributes**:
- `address` (String): Full text address (e.g., "10 Rue de Rivoli, Paris")
- `coordinates` (LatLng): Latitude and longitude of address
- `containingCellId` (String?): ID of grid cell containing this address (e.g., "C7"); null if grid not initialized
- `timestamp` (DateTime): When address was searched

**Relationships**:
- Belongs to at most one `GridCell` (calculated via north-west boundary rule)
- Associated with current `GridConfiguration`

**Validation Rules**:
- `coordinates` must be valid geographic coordinates (lat: -90 to 90, lon: -180 to 180)
- `containingCellId` format: `^[A-Z]+[0-9]+$` when not null
- `address` must be non-empty string

**State Transitions**:
1. **Searched**: Address geocoded, `coordinates` set, `containingCellId` calculated
2. **Solution Revealed**: User clicks "Show Solution" → `containingCellId` displayed to user
3. **Replaced**: New address searched → previous AddressPoint discarded

**Business Rules**:
- North-west boundary rule (FR-005a): Address exactly on cell boundary belongs to north or west cell
- Calculation uses origin from `GridConfiguration` and cell size

---

### 4. GridSettings

Represents user preferences for grid overlay (persisted data model).

**Attributes**:
- `selectedCellSize` (int): User's chosen cell size in meters (250, 500, 1000, or 2000)

**Relationships**:
- Used to initialize `GridConfiguration.cellSizeMeters` on app start

**Validation Rules**:
- `selectedCellSize` must be one of: 250, 500, 1000, 2000
- Default value: 500 (if not set)

**Persistence**:
- Stored in shared_preferences with key: `"grid_cell_size_meters"`
- Loaded on app start, saved immediately when changed

**State Transitions**:
1. **Default**: On first app launch, `selectedCellSize = 500`
2. **User Modified**: User changes setting in UI → value updated and persisted
3. **Applied**: On next grid initialization, `GridConfiguration` uses this value

---

## Entity Relationships Diagram

```
GridSettings
    |
    | (persisted preference)
    v
GridConfiguration
    |
    +-- origin (LatLng?)
    +-- cellSizeMeters (from GridSettings)
    +-- visibleCells (List<GridCell>)
    |
    +-- has many --> GridCell
    |                   |
    |                   +-- id (derived)
    |                   +-- bounds (calculated from origin + size)
    |                   +-- centerPoint (calculated)
    |
    +-- contains one --> AddressPoint?
                            |
                            +-- coordinates (LatLng)
                            +-- containingCellId (calculated from GridCell)
```

---

## Data Flow

### 1. Grid Initialization (First Address Search)

```
User searches address
    → AddressPoint created with coordinates
    → GridConfiguration.origin calculated (centered on address)
    → GridConfiguration.isVisible = true
    → Visible GridCells generated based on map viewport
    → Grid overlay rendered on map
```

### 2. Cell Identification (Game Solution)

```
AddressPoint exists with coordinates
    → Calculate cell indices: (columnIndex, rowIndex)
        - Distance from origin in meters (Haversine)
        - Divide by cellSizeMeters, floor to get indices
    → Convert indices to cell ID: columnLetter + (rowIndex + 1)
        - Column letter: Base-26 conversion
    → AddressPoint.containingCellId = calculated ID
    → User clicks "Show Solution" → Display containingCellId
```

### 3. Grid Size Change

```
User changes GridSettings.selectedCellSize (e.g., 500m → 1000m)
    → Persist new value to shared_preferences
    → Update GridConfiguration.cellSizeMeters
    → Recalculate all GridCell bounds (same origin, new size)
    → Regenerate visible cells
    → Redraw grid overlay
    → Recalculate AddressPoint.containingCellId if address exists
```

### 4. Map Pan/Zoom

```
User pans or zooms map
    → Get new map viewport bounds
    → Recalculate GridConfiguration.visibleCells
        - Determine which cells intersect viewport
        - Generate GridCell instances for those cells only
    → Redraw grid overlay with new visible cells
    → Origin and cell size remain unchanged
```

---

## Data Validation & Constraints

### GridCell Constraints
- Maximum visible cells: ~100 (performance limit)
- Column names support up to 3 letters (AAA = column 18278; exceeding map bounds in practice)
- Row numbers theoretically unlimited (practical limit ~10,000 for readability)

### GridConfiguration Constraints
- Cell size validation: Only 250, 500, 1000, 2000 allowed (enforced at UI level)
- Origin validation: Must be valid LatLng (-90 ≤ lat ≤ 90, -180 ≤ lon ≤ 180)
- Visible cells culling: Only generate cells within viewport + small buffer

### AddressPoint Constraints
- One AddressPoint active at a time (latest search wins)
- containingCellId only valid if GridConfiguration.origin exists
- Boundary rule ensures deterministic cell assignment (no ambiguity)

---

## Immutability & Value Objects

### Immutable Entities
- `GridCell`: Immutable value object (created from origin + indices, never modified)
- `AddressPoint`: Immutable once created (new search creates new instance)

### Mutable State
- `GridConfiguration`: Mutable state object (origin set once, cellSizeMeters can change)
- `GridSettings`: Mutable persisted state (user can change preference)

**Rationale**:
- Immutable cells simplify rendering (no need to track changes)
- Mutable configuration allows dynamic updates without recreating entire grid
- Follows Flutter best practices (immutable data, mutable state holders)

---

## Edge Cases & Special Handling

### 1. Address on Cell Boundary (FR-005a)
**Scenario**: Address coordinates exactly match a cell edge
**Handling**: Apply north-west priority rule
```
If address.lat == cell.northEdge AND address.lon == cell.westEdge:
    → Address belongs to this cell (north-west corner)
If address.lat == cell.southEdge OR address.lon == cell.eastEdge:
    → Address belongs to adjacent cell (south or east)
```

### 2. Grid Exceeds 26 Columns (FR-011)
**Scenario**: Map viewport spans more than 26 columns
**Handling**: Excel-style naming (A-Z, AA-AZ, BA-BZ, ...)
```
columnIndex 0-25 → A-Z
columnIndex 26-51 → AA-AZ
columnIndex 52-77 → BA-BZ
...
```

### 3. Invalid Grid Configuration
**Scenario**: Corrupted shared_preferences value
**Handling**: Fall back to default 500m
```
if (storedValue not in [250, 500, 1000, 2000]):
    cellSizeMeters = 500  // default
```

### 4. Map at Extreme Latitudes
**Scenario**: Grid near poles (>85°N or <85°S)
**Handling**: Haversine formula still works; document latitude limitations
- Performance may degrade at extreme latitudes (Mercator distortion)
- Acceptable for typical use cases (most cities below 70° latitude)

---

## Summary

**Total Entities**: 4 (GridCell, GridConfiguration, AddressPoint, GridSettings)

**Persistence Strategy**:
- Persisted: GridSettings (shared_preferences)
- Session-only: GridConfiguration, GridCell, AddressPoint (in-memory)

**Key Relationships**:
- GridSettings → GridConfiguration (initialization)
- GridConfiguration → GridCell (one-to-many, generated on-demand)
- GridConfiguration → AddressPoint (one-to-one, current search)
- AddressPoint → GridCell (calculated relationship via coordinates)

**Data Model Stability**: High. Entities align with functional requirements; minimal risk of schema changes during implementation.
