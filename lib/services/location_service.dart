import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Result wrapper for location permission and position queries.
class LocationResult {
  const LocationResult({
    this.position,
    required this.isPermissionGranted,
    required this.isPermanentlyDenied,
    this.errorMessage,
  });

  final Position? position;
  final bool isPermissionGranted;
  final bool isPermanentlyDenied;
  final String? errorMessage;
}

/// Service handling runtime location permissions, GPS positioning, and geocoding.
class LocationService {
  static const double defaultLatitude = 12.9716; // Bengaluru default
  static const double defaultLongitude = 77.5946;

  /// Requests or checks location permission and fetches current position.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          isPermissionGranted: false,
          isPermanentlyDenied: false,
          errorMessage: 'Location services are disabled on this device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            isPermissionGranted: false,
            isPermanentlyDenied: false,
            errorMessage: 'Location permission was denied by user.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          isPermissionGranted: false,
          isPermanentlyDenied: true,
          errorMessage: 'Location permission is permanently denied.',
        );
      }

      // Permission granted - fetch coordinates
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        position: position,
        isPermissionGranted: true,
        isPermanentlyDenied: false,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return LocationResult(
        isPermissionGranted: false,
        isPermanentlyDenied: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Opens the operating system app settings page.
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Generates a readable address string from geographic coordinates.
  static String formatCoordinatesAddress(double lat, double lng, {String? defaultName}) {
    final latStr = lat.toStringAsFixed(4);
    final lngStr = lng.toStringAsFixed(4);
    if (defaultName != null && defaultName.isNotEmpty) {
      return '$defaultName ($latStr, $lngStr)';
    }
    return 'Location near $latStr, $lngStr';
  }

  /// Calculates the Haversine distance in kilometers between two coordinate pairs.
  static double calculateDistanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLon = _degreesToRadians(endLongitude - startLongitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(startLatitude)) *
            math.cos(_degreesToRadians(endLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Estimates travel time in minutes based on distance and average city traffic speed.
  static int estimateTravelTimeMinutes(double distanceKm) {
    // Average urban traffic speed in Indian cities: ~22 km/h + 3 mins base buffer
    const averageSpeedKmh = 22.0;
    final travelHours = distanceKm / averageSpeedKmh;
    final minutes = (travelHours * 60).round() + 3;
    return math.max(3, minutes);
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }
}
