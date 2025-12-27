# Visual Diagrams: Grid Centering Changes

This document provides ASCII diagrams to visualize the architectural changes made on 2025-12-27.

---

## Before vs After: Grid Centering

### BEFORE: Address-Centered Grid

```
┌─────────────────────────────────────────────────┐
│                                                 │
│          City: Paris                            │
│                                                 │
│                                                 │
│                  ●  Address A                   │
│                (48.8566, 2.3522)                │
│                                                 │
│         Grid centered here:                     │
│         ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐                  │
│         │ │ │ │ │●│ │ │ │ │ │  10x10 grid      │
│         ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  (arbitrary)     │
│         │ │ │ │ │ │ │ │ │ │ │                  │
│         └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘                  │
│                                                 │
│  ⚠️ Problem: Grid might not cover entire city  │
│                                                 │
└─────────────────────────────────────────────────┘

Next address search:
┌─────────────────────────────────────────────────┐
│                                                 │
│          City: Paris                            │
│                                                 │
│                                                 │
│                         ● Address B             │
│                       (far from center)         │
│                                                 │
│         Same grid as before:                    │
│         ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐                  │
│         │ │ │ │ │ │ │ │ │ │ │                  │
│         ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤                  │
│         │ │ │ │ │ │ │ │ │ │●│ ← Near edge!     │
│         └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘                  │
│                                                 │
│  ❌ Poor coverage of Address B                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

### AFTER: City-Centered Grid

```
┌─────────────────────────────────────────────────┐
│                                                 │
│          City: Paris                            │
│          (5km radius bounds)                    │
│   ╔═══════════════════════════════╗             │
│   ║                               ║             │
│   ║  A  B  C  D  E  F  G  H  I  J ║ 1          │
│   ║ ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐            │
│   ║ │  │  │  │  │  │  │  │  │  │  │ 2          │
│   ║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤            │
│   ║ │  │  │  │  │ ●│  │  │  │  │  │ 3          │
│   ║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤  (City     │
│   ║ │  │  │  │  │  │  │  │  │  │  │ 4  center) │
│   ║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤            │
│   ║ │  │  │  │  │  │  │  │  │  │  │ 5          │
│   ║ └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘            │
│   ║                               ║             │
│   ╚═══════════════════════════════╝             │
│                                                 │
│  ✅ Grid covers entire city uniformly           │
│  ✅ Aligned to city bounds (NW corner)          │
│                                                 │
└─────────────────────────────────────────────────┘

All addresses in Paris:
┌─────────────────────────────────────────────────┐
│   ╔═══════════════════════════════╗             │
│   ║  A  B  C  D  E  F  G  H  I  J ║             │
│   ║ ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐            │
│   ║ │  │  │  │●1│  │  │  │  │  │  │ Address 1  │
│   ║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤            │
│   ║ │  │  │  │  │  │  │  │●2│  │  │ Address 2  │
│   ║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤            │
│   ║ │  │  │  │  │  │  │  │  │  │  │            │
│   ║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤            │
│   ║ │●3│  │  │  │  │  │  │  │  │  │ Address 3  │
│   ║ └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘            │
│   ╚═══════════════════════════════╝             │
│                                                 │
│  ✅ Same grid for ALL addresses                 │
│  ✅ Consistent cell IDs (D1, H2, A4)            │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Snap-to-Grid Algorithm

### Problem: Simple Centering
```
City Bounds (NW corner at origin):
┌────────────────────────────────┐ North
│                                │
│                                │
│              ●  City Center    │
│         (might not align       │
│          with grid lines)      │
│                                │
│                                │
└────────────────────────────────┘ South
West                           East

If we just use city center as origin:
│     │     │     │     │     │  Grid lines
│     │     │  ●  │     │     │  ← Center not on line!
│     │     │     │     │     │
      ↑ Cell boundaries misaligned
```

### Solution: Snap to Grid Cell
```
Step 1: Find NW corner of bounds
┌────────────────────────────────┐
●  NW Corner (48.9016, 2.2822)   │
│                                │
│              ●  City Center    │
│           (48.8566, 2.3522)    │
│                                │
└────────────────────────────────┘

Step 2: Calculate distance from NW to center
┌────────────────────────────────┐
●─────────────────┐              │
│ eastDist: 4850m │              │
│                 ↓              │
│              ●──┘  City Center │
│              │                 │
│              │ southDist: 4950m
│              ↓                 │
└────────────────────────────────┘

Step 3: Find cell containing center (500m cells)
┌────────────────────────────────┐
●─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐            │
│ │ │ │ │ │ │ │ │ │ │  cellsEast = 9
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  (4850 / 500 = 9.7 → floor = 9)
│ │ │ │ │ │ │ │ │ │ │
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ │ │ │ │ │ │ │ │ │ │  cellsSouth = 9
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  (4950 / 500 = 9.9 → floor = 9)
│ │ │ │ │ │ │ │ │●│ │  ← Cell (9, 9)
└─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

Step 4: Snap origin to that cell's NW corner
┌────────────────────────────────┐
●─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐            │
│ │ │ │ │ │ │ │ │ │ │
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ │ │ │ │ │ │ │ │ │ │
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ │ │ │ │ │ │ │ │ │ │
├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
│ │ │ │ │ │ │ │ │ ○ │  ← Origin snapped to cell boundary!
└─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
                ↑
         Grid Origin (aligned)

Result: Perfect alignment with city bounds
```

---

## Map Navigation Constraints

### BEFORE: No Constraints
```
User can pan anywhere:

     London
        ●
         \
          \
┌──────────\─────────┐
│  Paris    \        │
│            ●       │  User drags →
│    (game area)     │
│                    │
└────────────────────┘
                      \
                       \
                        ● Brussels

❌ User lost outside game area!
```

### AFTER: CameraConstraint.contain()
```
User tries to pan outside city:

┌═════════════════════┐ ← City Bounds (5km)
║  Paris              ║
║                     ║
║    ● (game area)    ║
║                     ║   User drags → → →
║                     ║
╚═════════════════════╝ ← Rubber band effect
                        ↖ Camera stays inside!

✅ User cannot leave Paris
✅ Focus maintained on game area
✅ Better user experience
```

---

## Grid Coverage Comparison

### BEFORE: Address-Centered (10x10 grid)
```
City boundaries not considered:

┌─────────────────────────────────┐
│                                 │
│  City Actual Bounds (unknown)   │
│                                 │
│    ┌─────────────┐              │
│    │  10x10 Grid │              │
│    │   (5km²)    │              │
│    │      ●      │  ← Address   │
│    │             │              │
│    └─────────────┘              │
│                                 │
│  ⚠️ Grid might miss city edges  │
│                                 │
└─────────────────────────────────┘
```

### AFTER: City-Bounds-Aligned
```
Grid perfectly covers city:

┌═════════════════════════════════┐
║                                 ║
║  City Bounds (calculated)       ║
║                                 ║
║  A  B  C  D  E  F  G  H  I  J  ║
║ ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐ ║ 1
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 2
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 3
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 4
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 5
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 6
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 7
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 8
║ ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤ ║ 9
║ └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘ ║ 10
║                                 ║
╚═════════════════════════════════╝

✅ Grid aligned to bounds (NW corner)
✅ Entire city covered uniformly
✅ No wasted cells outside city
```

---

## Data Flow: Grid Initialization

### BEFORE
```
User searches address
         ↓
    Get address coords
         ↓
    Calculate grid origin
    (centered on address)
         ↓
    Initialize grid
         ↓
    Display grid on map
```

### AFTER
```
User selects city (via postal code)
         ↓
    Get city center coords
         ↓
    Calculate city bounds
    (5km radius from center)
         ↓
    Calculate grid origin
    (aligned to bounds)
         ↓
    Initialize grid + map constraints
         ↓
    Display grid + restricted navigation
         ↓
    Generate random address in city
         ↓
    Calculate cell ID for address
```

---

## Component Interaction

### System Architecture
```
┌─────────────────────────────────────────────────┐
│                  HomeScreen                     │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ Grid Initialization Logic                 │  │
│  │                                           │  │
│  │  1. Get city center                      │  │
│  │  2. Calculate city bounds ────────┐      │  │
│  │  3. Calculate grid origin   │     │      │  │
│  │  4. Initialize GridConfig   │     │      │  │
│  │  5. Generate address         │     │      │  │
│  │                              ↓     ↓      │  │
│  └──────────────────────────────┼─────┼──────┘  │
│                                 │     │         │
│  ┌──────────────────────────────┼─────┼──────┐  │
│  │          MapDisplay          │     │      │  │
│  │                              │     │      │  │
│  │  ┌──────────────────┐        │     │      │  │
│  │  │  FlutterMap      │        │     │      │  │
│  │  │                  │        │     │      │  │
│  │  │  ┌────────────┐  │ ←──────┘     │      │  │
│  │  │  │ TileLayer  │  │  CameraConstraint    │  │
│  │  │  └────────────┘  │              │      │  │
│  │  │                  │              │      │  │
│  │  │  ┌────────────┐  │              │      │  │
│  │  │  │   Grid     │  │ ←────────────┘      │  │
│  │  │  │  Overlay   │  │  cityBounds         │  │
│  │  │  └────────────┘  │                     │  │
│  │  │                  │                     │  │
│  │  │  ┌────────────┐  │                     │  │
│  │  │  │  Address   │  │                     │  │
│  │  │  │  Marker    │  │                     │  │
│  │  │  └────────────┘  │                     │  │
│  │  └──────────────────┘                     │  │
│  └────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘

       ↕ Data Flow

┌─────────────────────────────────┐
│  GridCalculationService         │
│                                 │
│  ● calculateCityBounds()        │
│  ● calculateGridOrigin()        │
│  ● getCellForPoint()            │
│  ● generateVisibleCells()       │
└─────────────────────────────────┘
```

---

## Zoom Level Constraints

### Visual Zoom Range
```
Zoom 12 (Min) - City-level view:
┌═══════════════════════════════════════┐
║                                       ║
║         Entire city visible           ║
║                                       ║
║  ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐               ║
║  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤  Grid visible ║
║  ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤               ║
║  └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘               ║
║                                       ║
╚═══════════════════════════════════════╝
Cell labels: 12px readable ✓


Zoom 14 (Default) - Balanced view:
┌═══════════════════════════════════════┐
║                                       ║
║      District-level detail            ║
║                                       ║
║  ┌───┬───┬───┬───┬───┐               ║
║  │ A │ B │ C │ D │ E │  Grid clear   ║
║  ├───┼───┼───┼───┼───┤               ║
║  │   │   │   │   │   │  Streets      ║
║  └───┴───┴───┴───┴───┘  visible      ║
║                                       ║
╚═══════════════════════════════════════╝
Cell labels: 14px very readable ✓


Zoom 18 (Max) - Street-level detail:
┌═══════════════════════════════════════┐
║                                       ║
║  Few cells visible, but detailed:     ║
║                                       ║
║  ┌───────────┬───────────┐           ║
║  │           │           │           ║
║  │    F7     │    G7     │  Building ║
║  │           │           │  details  ║
║  ├───────────┼───────────┤           ║
║  │           │           │           ║
║  │    F8     │    G8     │           ║
║  │           │           │           ║
║  └───────────┴───────────┘           ║
╚═══════════════════════════════════════╝
Cell labels: 18px, very large ✓


❌ Zoom 10 (Blocked) - Too far out:
Grid labels too small, unreadable

❌ Zoom 20 (Blocked) - Too close:
Only fraction of cell visible, confusing
```

---

## Summary: Key Visual Changes

### Grid Origin
```
BEFORE: ● Address point
AFTER:  ○ Aligned to city bounds (snapped to grid cell)
```

### Grid Coverage
```
BEFORE: [  Small box around address  ]
AFTER:  ═══════════════════════════════
        ║  Entire city uniformly   ║
        ═══════════════════════════════
```

### Map Navigation
```
BEFORE: User can pan anywhere ──→ ∞
AFTER:  User locked to city ──→ ║WALL║
```

### Consistency
```
BEFORE: Address 1 → Grid A
        Address 2 → Grid A (might not fit well)

AFTER:  Address 1 → Grid covering city
        Address 2 → Same grid ✓
        Address N → Same grid ✓
```

---

**These diagrams visually represent the architectural improvements made to ensure consistent, city-wide grid coverage with proper alignment and navigation constraints.**
