import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/constants/google_maps_config.dart';
import '../models/location_model.dart';

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
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;

  /// Test mocks for automated verification
  static Position? mockPosition;
  static String? mockAddress;
  static bool mockPermissionDenied = false;

  /// Requests or checks location permission and fetches current position.
  static Future<LocationResult> getCurrentLocation() async {
    if (mockPermissionDenied) {
      return const LocationResult(
        isPermissionGranted: false,
        isPermanentlyDenied: false,
        errorMessage: 'Location permission was denied by user.',
      );
    }

    if (mockPosition != null) {
      return LocationResult(
        position: mockPosition,
        isPermissionGranted: true,
        isPermanentlyDenied: false,
      );
    }

    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (bindingName.contains('TestWidgetsFlutterBinding') ||
        bindingName.contains('AutomatedTestWidgetsFlutterBinding')) {
      return const LocationResult(
        isPermissionGranted: false,
        isPermanentlyDenied: false,
        errorMessage: 'Location services unavailable in test runner',
      );
    }

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

  /// Reverse geocodes coordinates to a human-readable real-world street address.
  ///
  /// Uses official Google Geocoding API.
  /// If reverse geocoding is unavailable or fails, gracefully falls back to
  /// "Location selected, address unavailable" or formatted coordinate string
  /// without using hardcoded or fake locations, and NEVER uses OpenStreetMap.
  static Future<String> reverseGeocode(double latitude, double longitude) async {
    if (mockAddress != null) {
      return mockAddress!;
    }

    try {
      final apiKey = GoogleMapsConfig.apiKey;
      if (apiKey.isEmpty) {
        return 'Location selected, address unavailable';
      }

      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'OK') {
          final results = data['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            final formattedAddress = first['formatted_address'] as String?;
            if (formattedAddress != null && formattedAddress.trim().isNotEmpty) {
              return formattedAddress.trim();
            }
          }
        }
      }
    } catch (e) {
      // Keep API key confidential - do not log request URL
      debugPrint('[LocationService] Google reverse geocoding note: $e');
    }

    return 'Location selected, address unavailable';
  }

  /// Reverse geocodes coordinates to a complete [LocationPoint] including real address
  /// and Place ID where available from Google Geocoding API.
  static Future<LocationPoint> reverseGeocodePoint(
    double latitude,
    double longitude, {
    String defaultName = 'Selected Destination',
  }) async {
    if (mockAddress != null) {
      return LocationPoint(
        latitude: latitude,
        longitude: longitude,
        name: defaultName,
        address: mockAddress!,
      );
    }

    try {
      final apiKey = GoogleMapsConfig.apiKey;
      if (apiKey.isNotEmpty) {
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final status = data['status'] as String?;
          if (status == 'OK') {
            final results = data['results'] as List<dynamic>?;
            if (results != null && results.isNotEmpty) {
              final first = results.first as Map<String, dynamic>;
              final formattedAddress = first['formatted_address'] as String? ?? '';
              final placeId = first['place_id'] as String?;

              // Derive a recognizable title from address components if available
              String name = defaultName;
              final components = first['address_components'] as List<dynamic>?;
              if (components != null && components.isNotEmpty) {
                final firstComp = components.first as Map<String, dynamic>;
                final shortName = firstComp['short_name'] as String?;
                final longName = firstComp['long_name'] as String?;
                if (longName != null && longName.isNotEmpty) {
                  name = longName;
                } else if (shortName != null && shortName.isNotEmpty) {
                  name = shortName;
                }
              } else if (formattedAddress.contains(',')) {
                name = formattedAddress.split(',').first.trim();
              }

              return LocationPoint(
                latitude: latitude,
                longitude: longitude,
                name: name.isNotEmpty ? name : defaultName,
                address: formattedAddress.isNotEmpty
                    ? formattedAddress
                    : 'Location selected, address unavailable',
                placeId: placeId,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Google reverseGeocodePoint note: $e');
    }

    return LocationPoint(
      latitude: latitude,
      longitude: longitude,
      name: defaultName,
      address: 'Location selected, address unavailable',
    );
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
