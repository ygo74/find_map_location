import 'package:flutter/material.dart';
import 'package:find_map_location/models/postal_code.dart';
import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/models/game_session_state.dart';
import 'package:find_map_location/models/grid_configuration.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/services/random_address_service.dart';
import 'package:find_map_location/services/location_service.dart';
import 'package:find_map_location/services/grid_settings_service.dart';
import 'package:find_map_location/services/grid_calculation_service.dart';
import 'package:find_map_location/widgets/postal_code_input.dart';
import 'package:find_map_location/widgets/map_display.dart';
import 'package:find_map_location/widgets/address_display.dart';
import 'package:find_map_location/widgets/start_search_button.dart';
import 'package:find_map_location/widgets/grid_settings_dialog.dart';
import 'package:find_map_location/screens/city_selection_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

/// Main screen for postal code lookup and map display.
///
/// Allows users to enter French postal codes and view the corresponding
/// city location on an interactive map. Handles multiple cities per postal code
/// with selection interface. Supports validation, loading states, and error messages.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _geocodingService = ApiAdresseGeocodingService();
  late final RandomAddressService _addressService;
  final _locationService = LocationService();
  final _controller = TextEditingController();
  final _mapController = MapController();
  GridConfiguration? _gridConfig;

  GameSessionState? _sessionState;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0; // For request cancellation tracking

  @override
  void initState() {
    super.initState();
    _addressService = RandomAddressService(geocodingService: _geocodingService);
    _initializeGridConfiguration();
  }

  /// Initializes grid configuration with persisted settings
  Future<void> _initializeGridConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsService = GridSettingsService(prefs);
    final gridSize = settingsService.getGridSize();

    if (mounted) {
      setState(() {
        _gridConfig = GridConfiguration(cellSizeMeters: gridSize);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Generates a random address for the given city using RandomAddressService
  ///
  /// Updates game session state with the new address and ensures uniqueness.
  /// If this is the first address, also initializes the grid origin.
  Future<void> _generateAndSetAddress(City city) async {
    // Create or update session state for this city
    final currentState = _sessionState?.city == city
        ? _sessionState!
        : GameSessionState.initial(city: city);

    // Generate address with uniqueness check
    final address = await _addressService.generateAddress(
      city,
      usedAddresses: currentState.usedAddresses,
    );

    if (address != null) {
      // Initialize grid origin if this is the first address and grid not initialized
      if (_gridConfig != null && _gridConfig!.origin == null) {
        // Use city center for grid alignment, not the specific address
        final cityCenter = LatLng(city.latitude, city.longitude);
        final cityBounds = GridCalculationService.calculateCityBounds(
          cityCenter,
          5000.0, // 5km radius
        );
        final origin = GridCalculationService.calculateGridOrigin(
          cityCenter,
          _gridConfig!.cellSizeMeters.toDouble(),
          cityBounds: cityBounds,
        );
        _gridConfig!.setOrigin(origin);
      }

      // Calculate cell ID for this address (for "Show Solution" feature)
      String? cellId;
      if (_gridConfig != null && _gridConfig!.origin != null) {
        final addressPoint = LatLng(address.latitude, address.longitude);
        final cell = GridCalculationService.getCellForPoint(
          addressPoint,
          _gridConfig!.origin!,
          _gridConfig!.cellSizeMeters.toDouble(),
        );
        cellId = cell.id;
      }

      setState(() {
        _sessionState = currentState.withAddress(address, cellId: cellId);
      });
    } else {
      // Could not generate address
      setState(() {
        _errorMessage = 'Could not find a valid address in this city. Please try again.';
      });
    }
  }

  /// Handles Start Search button press
  ///
  /// Attempts to get user's current location and zoom map to street-level.
  /// If location unavailable, map remains at city view. Button becomes disabled after press.
  Future<void> _handleStartSearch() async {
    if (_sessionState == null) return;

    // Mark search as started (disables button)
    setState(() {
      _sessionState = _sessionState!.withSearchStarted();
    });

    // Try to get user's current location
    final userLocation = await _locationService.getCurrentLocation();

    if (userLocation != null) {
      // Zoom to user's location at street level (zoom 17)
      _mapController.move(userLocation, 17.0);
    } else {
      // Location unavailable - show message but keep map at city view
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location unavailable - search from city view'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Handles Stop Search button press
  ///
  /// Returns to postal code input mode but keeps the city and allows new address generation
  void _handleStopSearch() {
    if (_sessionState == null) return;

    setState(() {
      // Reset search state but keep the city
      _sessionState = GameSessionState.initial(city: _sessionState!.city)
          .withAddress(_sessionState!.currentAddress!);
    });
  }

  /// Handles Refresh Address button press
  ///
  /// Generates a new random address for the current city
  Future<void> _handleRefreshAddress() async {
    if (_sessionState?.city == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _generateAndSetAddress(_sessionState!.city);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _errorMessage = null;
    });

    final postalCode = PostalCode(_controller.text);

    // Validate empty field
    if (postalCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a postal code';
      });
      return;
    }

    // Validate format
    if (!postalCode.isValid) {
      setState(() {
        _errorMessage = 'Please enter a valid 5-digit French postal code';
      });
      return;
    }

    // Start loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Increment request ID for cancellation tracking
    final currentRequestId = ++_requestId;

    try {
      final result = await _geocodingService.fetchLocations(postalCode);

      // Discard if this request was superseded (latest-wins pattern)
      if (currentRequestId != _requestId) {
        return;
      }

      // Check if result requires city selection
      if (result.requiresSelection) {
        // Multiple cities - show selection screen
        setState(() {
          _isLoading = false;
        });

        // Navigate to selection screen (full screen push)
        if (!mounted) return;
        final selectedCity = await Navigator.push<City>(
          context,
          MaterialPageRoute(
            builder: (context) => CitySelectionScreen(cities: result.cities),
          ),
        );

        // Check if user cancelled selection
        if (selectedCity != null && mounted) {
          setState(() {
            _isLoading = true; // Start loading for address generation
          });

          // Generate random address for selected city
          await _generateAndSetAddress(selectedCity);

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else if (result.isSingleCity) {
        // Single city - display map immediately and generate address
        final city = result.singleCity;
        setState(() {
          _isLoading = true; // Continue loading for address generation
        });

        // Generate random address for the city
        await _generateAndSetAddress(city);

        if (mounted && currentRequestId == _requestId) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Empty result (should not happen - API throws exception)
        setState(() {
          _isLoading = false;
          _errorMessage = 'No cities found for this postal code.';
        });
      }
    } on PostalCodeNotFoundException catch (e) {
      if (currentRequestId == _requestId) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No city found for postal code ${e.postalCode}. Please verify and try again.';
        });
      }
    } on NetworkException {
      if (currentRequestId == _requestId) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No internet connection. Please check your network and try again.';
        });
      }
    } on ServerException {
      if (currentRequestId == _requestId) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Service temporarily unavailable. Please try again later.';
        });
      }
    } catch (e) {
      if (currentRequestId == _requestId) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearchMode = _sessionState?.hasStartedSearch ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Map Location'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _handleGridSettings,
            tooltip: 'Grid Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Hide postal code input and search button when in search mode
          if (!isSearchMode) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PostalCodeInput(
                controller: _controller,
                onSubmit: _handleSubmit,
                errorMessage: _errorMessage,
              ),
            ),
            // Display city name when a city is selected
            if (_sessionState?.city != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_city,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Playing in: ${_sessionState!.city.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            // Display random address if available with refresh button
            if (_sessionState?.currentAddress != null)
              AddressDisplay(
                address: _sessionState!.currentAddress!,
                onRefresh: _handleRefreshAddress,
              ),
            // Display Start Search button if address exists and search not started
            if (_sessionState?.currentAddress != null)
              StartSearchButton(
                isEnabled: true,
                onPressed: _handleStartSearch,
              ),
          ],
          // In search mode: show city name, address with refresh and stop button
          if (isSearchMode && _sessionState?.currentAddress != null) ...[
            // City name banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_city,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Playing in: ${_sessionState!.city.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Address and controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: AddressDisplay(
                      address: _sessionState!.currentAddress!,
                      onRefresh: _handleRefreshAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _handleStopSearch,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_sessionState?.city != null)
            Expanded(
              child: MapDisplay(
                latitude: _sessionState!.city.latitude,
                longitude: _sessionState!.city.longitude,
                cityName: _sessionState!.city.name,
                mapController: _mapController,
                targetLatitude: _sessionState!.currentAddress?.latitude,
                targetLongitude: _sessionState!.currentAddress?.longitude,
                gridConfiguration: _gridConfig,
                cityBounds: _gridConfig?.origin != null
                    ? GridCalculationService.calculateCityBounds(
                        LatLng(_sessionState!.city.latitude, _sessionState!.city.longitude),
                        5000.0,
                      )
                    : null,
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text(
                  'Enter a postal code to view the map',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _sessionState?.currentCellId != null
          ? Semantics(
              label: 'Show solution button. Reveals which grid cell contains the address',
              button: true,
              child: FloatingActionButton.extended(
                onPressed: _showSolution,
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Show Solution'),
                tooltip: 'Show Solution',
              ),
            )
          : null,
    );
  }

  /// Shows a SnackBar displaying the grid cell ID containing the target address
  void _showSolution() {
    if (_sessionState?.currentCellId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Address is in cell ${_sessionState!.currentCellId}'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handles grid settings button press
  ///
  /// Shows GridSettingsDialog and applies new cell size if changed.
  /// Persists the setting and recalculates cell ID if address exists.
  Future<void> _handleGridSettings() async {
    if (_gridConfig == null) return;

    final newSize = await showDialog<int>(
      context: context,
      builder: (context) => GridSettingsDialog(
        currentCellSizeMeters: _gridConfig!.cellSizeMeters,
      ),
    );

    // User cancelled or selected same size
    if (newSize == null || newSize == _gridConfig!.cellSizeMeters) {
      return;
    }

    // Update grid configuration
    _gridConfig!.setCellSize(newSize);

    // Persist the setting
    final prefs = await SharedPreferences.getInstance();
    final settingsService = GridSettingsService(prefs);
    await settingsService.setGridSize(newSize);

    // Recalculate cell ID if address exists
    if (_sessionState?.currentAddress != null && _gridConfig!.origin != null) {
      final addressPoint = LatLng(
        _sessionState!.currentAddress!.latitude,
        _sessionState!.currentAddress!.longitude,
      );
      final cell = GridCalculationService.getCellForPoint(
        addressPoint,
        _gridConfig!.origin!,
        _gridConfig!.cellSizeMeters.toDouble(),
      );

      setState(() {
        _sessionState = _sessionState!.withAddress(
          _sessionState!.currentAddress!,
          cellId: cell.id,
        );
      });
    }
  }
}
