# Find Map Location

A Flutter geolocation game that challenges users to find random addresses on an interactive map with a grid overlay system.

## Features

### 🗺️ Interactive Map with Grid Overlay
- **Alphanumeric Grid System**: Displays an Excel-style grid (A1, B2, C3, etc.) overlaid on the map
- **Dynamic Grid Rendering**: Grid updates automatically as you pan and zoom
- **Configurable Cell Sizes**: Choose from 250m, 500m, 1000m, or 2000m grid cells
- **Smart Performance**: Maximum 100 visible cells with 300ms debounce for smooth panning

### 🎮 Geolocation Challenge Game
- **Random Address Generation**: Get random street addresses within French cities
- **Find the Location**: Search for the given address on the map
- **Grid Cell Identification**: Each address is associated with a specific grid cell
- **Solution Reveal**: Click "Show Solution" to see which grid cell contains the address
- **Persistent Sessions**: Grid remains consistent across multiple address searches

### 🏙️ City Selection
- **Postal Code Lookup**: Enter any French postal code (e.g., 75001 for Paris)
- **Multi-City Support**: Automatically handles postal codes with multiple cities
- **City Selection Interface**: Choose from available cities when multiple matches exist
- **Single City Bypass**: Instantly loads map for postal codes with one city

### ⚙️ Configuration
- **Grid Cell Size**: Adjust grid granularity via settings dialog
- **Persistent Settings**: Cell size preference saved across app restarts
- **Real-time Updates**: Grid automatically redraws when settings change
- **Cell ID Recalculation**: Address location updates for new grid sizes

## Technical Implementation

### Grid Calculation Service
- Pure functional calculation logic using Haversine formula
- Supports arbitrary grid sizes and orientations
- North-west boundary rule for deterministic cell assignment
- Efficient visible cell generation with viewport clipping

### Architecture
- **Models**: `GridCell`, `GridConfiguration`, `GridSettings`, `GameSessionState`
- **Services**: `GridCalculationService`, `GridSettingsService`, `GeocodingService`
- **Widgets**: `GridOverlayWidget`, `GridSettingsDialog`, custom UI components
- **State Management**: ChangeNotifier pattern for grid configuration
- **Persistence**: SharedPreferences for settings storage

### Testing
- **158 Unit/Widget Tests**: Comprehensive coverage for all services and widgets
- **Integration Tests**: End-to-end validation of user flows
- **Test Coverage**: 80%+ for services, 60%+ for widgets

## Getting Started

### Prerequisites
- Flutter SDK 3.x or higher
- Dart 3.10.4 or higher
- Android/iOS device or emulator

### Installation
```bash
# Clone the repository
git clone https://github.com/ygo74/find_map_location.git

# Navigate to the app directory
cd find_map_location/src/app/find_map_location

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Running Tests
```bash
# Run all unit and widget tests
flutter test --exclude-tags=integration

# Run integration tests
flutter test integration_test/

# Check code coverage
flutter test --coverage
```

## How to Play

1. **Enter a Postal Code**: Type a French postal code (e.g., 75001)
2. **Select City** (if multiple): Choose from the list if the postal code has multiple cities
3. **View the Address**: A random street address is generated for you
4. **Start Searching**: Click "Start Search" to zoom to your location (or search from city view)
5. **Find the Location**: Pan and zoom the map to locate the address
6. **Check Solution**: Click "Show Solution" to reveal which grid cell contains the address
7. **Try Again**: Click the refresh button to get a new random address

## Grid System Details

### Cell Naming Convention
- Columns: A, B, C, ..., Z, AA, AB, ..., AZ, BA, ...
- Rows: 1, 2, 3, 4, ...
- Example: Cell "C5" is 3rd column, 5th row

### Grid Origin
- Automatically calculated to center on the first address
- Remains fixed for all subsequent addresses in the same city
- Positioned approximately 5 cells away from address in each direction

### Boundary Rules
- Points on north edges belong to the cell
- Points on west edges belong to the cell
- Points on south edges belong to the cell below
- Points on east edges belong to the cell to the right

## Configuration Options

### Grid Cell Sizes
- **250m**: Fine-grained grid for detailed navigation
- **500m**: Default balanced grid (recommended)
- **1000m**: Larger cells for broader areas
- **2000m**: Extra-large cells for city-wide views

Access settings via the gear icon (⚙️) in the app bar.

## Dependencies

- `flutter_map`: ^8.2.2 - Interactive map widget
- `latlong2`: ^0.9.0 - Geographic coordinate calculations
- `shared_preferences`: ^2.0.0 - Settings persistence
- `geolocator`: For device location access
- `permission_handler`: For location permissions

## Contributing

This project follows the Speckit workflow for feature development. See `/specs/` directory for detailed feature specifications.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenStreetMap for map tiles
- api-adresse.data.gouv.fr for French geocoding services
- Flutter and Dart teams for the excellent framework
