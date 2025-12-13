import 'package:flutter/material.dart';
import 'package:find_map_location/models/postal_code.dart';
import 'package:find_map_location/models/city_location.dart';
import 'package:find_map_location/services/geocoding_service.dart';
import 'package:find_map_location/widgets/postal_code_input.dart';
import 'package:find_map_location/widgets/map_display.dart';

/// Main screen for postal code lookup and map display.
///
/// Allows users to enter French postal codes and view the corresponding
/// city location on an interactive map. Handles validation, loading states,
/// and error messages.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _geocodingService = ApiAdresseGeocodingService();
  final _controller = TextEditingController();

  CityLocation? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;
  Future<CityLocation>? _pendingRequest;

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

    // Cancel previous request (latest-wins pattern)
    _pendingRequest = null;

    // Start new request
    final request = _geocodingService.fetchLocation(postalCode);
    _pendingRequest = request;

    try {
      final location = await request;

      // Only update if this is still the current request
      if (_pendingRequest == request) {
        setState(() {
          _currentLocation = location;
          _isLoading = false;
        });
      }
    } on PostalCodeNotFoundException catch (e) {
      if (_pendingRequest == request) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No city found for postal code ${e.postalCode}. Please verify and try again.';
        });
      }
    } on NetworkException {
      if (_pendingRequest == request) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No internet connection. Please check your network and try again.';
        });
      }
    } on ServerException {
      if (_pendingRequest == request) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Service temporarily unavailable. Please try again later.';
        });
      }
    } catch (e) {
      if (_pendingRequest == request) {
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
          else if (_currentLocation != null)
            Expanded(
              child: MapDisplay(location: _currentLocation!),
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
