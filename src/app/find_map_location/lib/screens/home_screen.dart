import 'package:flutter/material.dart';
import 'package:find_map_location/models/postal_code.dart';
import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/widgets/postal_code_input.dart';
import 'package:find_map_location/widgets/map_display.dart';
import 'package:find_map_location/screens/city_selection_screen.dart';

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
  final _controller = TextEditingController();

  City? _currentCity;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestId = 0; // For request cancellation tracking

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            _currentCity = selectedCity;
          });
        }
      } else if (result.isSingleCity) {
        // Single city - display map immediately
        setState(() {
          _currentCity = result.singleCity;
          _isLoading = false;
        });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Map Location'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PostalCodeInput(
              controller: _controller,
              onSubmit: _handleSubmit,
              errorMessage: _errorMessage,
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_currentCity != null)
            Expanded(
              child: MapDisplay(
                latitude: _currentCity!.latitude,
                longitude: _currentCity!.longitude,
                cityName: _currentCity!.name,
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
    );
  }
}
