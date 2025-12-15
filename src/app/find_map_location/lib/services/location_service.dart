import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service for obtaining user's current location
///
/// Uses geolocator package with appropriate permissions and timeout handling.
/// Returns null if location cannot be obtained for any reason.
class LocationService {
  static const Duration _timeout = Duration(seconds: 5);

  /// Gets the user's current location
  ///
  /// Returns null if:
  /// - Permission is denied
  /// - Location service is disabled
  /// - Timeout occurs (5 seconds)
  /// - Any error occurs during retrieval
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(_timeout);

      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      debugPrint('Location request timed out');
      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
}
