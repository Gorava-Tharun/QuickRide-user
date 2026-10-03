import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/google_maps_config.dart';
import '../models/location_model.dart';

/// Service providing real Google Places Autocomplete and Geocoding search.
///
/// Uses official Google Places API (New) with GPS location bias and Google Geocoding API.
/// Does NOT use fake locations, mock lists, hardcoded databases, or OpenStreetMap.
/// Handles API errors gracefully returning empty results with clear diagnostic reporting.
class PlacesService {
  /// Test hook for unit and widget testing
  static List<LocationPoint>? mockSearchResults;

  /// Searches real locations matching the query using Google Places API (New)
  /// biased toward the user's current GPS position (50 km radius) without restrictive type filters,
  /// enabling discovery of small/local addresses, streets, shops, colleges, and landmarks.
  static Future<List<LocationPoint>> searchLocations(
    String query, {
    double? currentLat,
    double? currentLng,
  }) async {
    if (mockSearchResults != null) {
      return mockSearchResults!;
    }

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    final apiKey = GoogleMapsConfig.apiKey;
    if (apiKey.isEmpty) {
      debugPrint('[PlacesService] Google Maps API key is not configured.');
      return const [];
    }

    final biasLat = currentLat ?? GoogleMapsConfig.defaultLat;
    final biasLng = currentLng ?? GoogleMapsConfig.defaultLng;

    // 1. Primary: Try Google Places API (New) Autocomplete
    try {
      final placesNewResults = await _searchPlacesApiNew(
        cleanQuery,
        biasLat: biasLat,
        biasLng: biasLng,
        apiKey: apiKey,
      );
      if (placesNewResults.isNotEmpty) {
        return placesNewResults;
      }
    } catch (e) {
      debugPrint('[PlacesService] Places API (New) note: $e');
    }

    // 2. Secondary: Try Google Geocoding API by address
    try {
      final geocodingResults = await _searchGeocodingApi(
        cleanQuery,
        biasLat: biasLat,
        biasLng: biasLng,
        apiKey: apiKey,
      );
      if (geocodingResults.isNotEmpty) {
        return geocodingResults;
      }
    } catch (e) {
      debugPrint('[PlacesService] Google Geocoding note: $e');
    }

    // 3. Tertiary: Try Google Places Legacy Autocomplete
    try {
      final legacyResults = await _searchPlacesLegacyApi(
        cleanQuery,
        biasLat: biasLat,
        biasLng: biasLng,
        apiKey: apiKey,
      );
      if (legacyResults.isNotEmpty) {
        return legacyResults;
      }
    } catch (e) {
      debugPrint('[PlacesService] Google Places Legacy note: $e');
    }

    // Graceful fallback: return empty list so UI presents "No matching location found"
    return const [];
  }

  /// Calls Google Places API (New) Autocomplete with GPS location bias
  static Future<List<LocationPoint>> _searchPlacesApiNew(
    String input, {
    required double biasLat,
    required double biasLng,
    required String apiKey,
  }) async {
    final uri = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
    final payload = {
      'input': input,
      'locationBias': {
        'circle': {
          'center': {
            'latitude': biasLat,
            'longitude': biasLng,
          },
          'radius': GoogleMapsConfig.defaultSearchRadiusMeters,
        },
      },
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>?;
      if (suggestions != null && suggestions.isNotEmpty) {
        final points = <LocationPoint>[];
        for (final item in suggestions) {
          final placePrediction = item['placePrediction'] as Map<String, dynamic>?;
          if (placePrediction == null) continue;

          final placeId = placePrediction['placeId'] as String? ?? '';
          final textObj = placePrediction['text'] as Map<String, dynamic>?;
          final fullText = textObj?['text'] as String? ?? '';

          final structured = placePrediction['structuredFormat'] as Map<String, dynamic>?;
          final mainTextObj = structured?['mainText'] as Map<String, dynamic>?;
          final mainText = mainTextObj?['text'] as String? ?? fullText;

          final secondaryTextObj = structured?['secondaryText'] as Map<String, dynamic>?;
          final secondaryText = secondaryTextObj?['text'] as String? ?? '';

          final displayAddress = secondaryText.isNotEmpty ? '$mainText, $secondaryText' : fullText;

          points.add(
            LocationPoint(
              latitude: 0.0,
              longitude: 0.0,
              name: mainText.isNotEmpty ? mainText : input,
              address: displayAddress.isNotEmpty ? displayAddress : fullText,
              placeId: placeId,
            ),
          );
        }
        return points;
      }
    } else {
      debugPrint('[PlacesService] Places API (New) returned HTTP ${response.statusCode}');
    }
    return const [];
  }

  /// Calls Google Geocoding API by address text with viewport bounds around current GPS
  static Future<List<LocationPoint>> _searchGeocodingApi(
    String query, {
    required double biasLat,
    required double biasLng,
    required String apiKey,
  }) async {
    // 0.45 degrees roughly corresponds to ~50 km
    final minLat = biasLat - 0.45;
    final maxLat = biasLat + 0.45;
    final minLng = biasLng - 0.45;
    final maxLng = biasLng + 0.45;

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&bounds=$minLat,$minLng|$maxLat,$maxLng&key=$apiKey',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status == 'OK') {
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final points = <LocationPoint>[];
          for (final res in results.take(6)) {
            final formatted = res['formatted_address'] as String? ?? '';
            final placeId = res['place_id'] as String?;
            final geometry = res['geometry'] as Map<String, dynamic>?;
            final location = geometry?['location'] as Map<String, dynamic>?;
            final lat = (location?['lat'] as num?)?.toDouble() ?? 0.0;
            final lng = (location?['lng'] as num?)?.toDouble() ?? 0.0;

            String name = formatted.split(',').first.trim();
            final components = res['address_components'] as List<dynamic>?;
            if (components != null && components.isNotEmpty) {
              final firstComp = components.first as Map<String, dynamic>;
              name = firstComp['long_name'] as String? ?? name;
            }

            points.add(
              LocationPoint(
                latitude: lat,
                longitude: lng,
                name: name.isNotEmpty ? name : query,
                address: formatted,
                placeId: placeId,
              ),
            );
          }
          return points;
        }
      }
    }
    return const [];
  }

  /// Calls Google Places Legacy Autocomplete API
  static Future<List<LocationPoint>> _searchPlacesLegacyApi(
    String input, {
    required double biasLat,
    required double biasLng,
    required String apiKey,
  }) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&location=$biasLat,$biasLng&radius=50000&key=$apiKey',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status == 'OK') {
        final predictions = data['predictions'] as List<dynamic>?;
        if (predictions != null && predictions.isNotEmpty) {
          final points = <LocationPoint>[];
          for (final pred in predictions.take(6)) {
            final description = pred['description'] as String? ?? '';
            final placeId = pred['place_id'] as String? ?? '';
            final structured = pred['structured_formatting'] as Map<String, dynamic>?;
            final mainText = structured?['main_text'] as String? ?? description;

            points.add(
              LocationPoint(
                latitude: 0.0,
                longitude: 0.0,
                name: mainText,
                address: description,
                placeId: placeId,
              ),
            );
          }
          return points;
        }
      }
    }
    return const [];
  }

  /// Resolves exact latitude and longitude for a place if coordinates are (0, 0).
  ///
  /// Uses Google Places API (New) Place Details or Google Geocoding API by placeId.
  static Future<LocationPoint> resolvePlaceCoordinates(LocationPoint point) async {
    if (point.latitude != 0.0 && point.longitude != 0.0) {
      return point;
    }

    if (point.placeId == null || point.placeId!.isEmpty) {
      return point;
    }

    final apiKey = GoogleMapsConfig.apiKey;
    if (apiKey.isEmpty) {
      return point;
    }

    // 1. Try Google Places API (New) Details
    try {
      final uri = Uri.parse(
        'https://places.googleapis.com/v1/places/${point.placeId}?fields=id,displayName,formattedAddress,location&key=$apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final location = data['location'] as Map<String, dynamic>?;
        final lat = (location?['latitude'] as num?)?.toDouble();
        final lng = (location?['longitude'] as num?)?.toDouble();
        final formattedAddress = data['formattedAddress'] as String?;
        final displayNameObj = data['displayName'] as Map<String, dynamic>?;
        final displayName = displayNameObj?['text'] as String?;

        if (lat != null && lng != null) {
          return point.copyWith(
            latitude: lat,
            longitude: lng,
            name: displayName ?? point.name,
            address: formattedAddress ?? point.address,
          );
        }
      }
    } catch (e) {
      debugPrint('[PlacesService] Places Details New note: $e');
    }

    // 2. Try Google Geocoding API by place_id
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?place_id=${point.placeId}&key=$apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'OK') {
          final results = data['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            final geometry = first['geometry'] as Map<String, dynamic>?;
            final location = geometry?['location'] as Map<String, dynamic>?;
            final lat = (location?['lat'] as num?)?.toDouble();
            final lng = (location?['lng'] as num?)?.toDouble();
            final formattedAddress = first['formatted_address'] as String?;

            if (lat != null && lng != null) {
              return point.copyWith(
                latitude: lat,
                longitude: lng,
                address: formattedAddress ?? point.address,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PlacesService] Geocoding place_id note: $e');
    }

    return point;
  }
}
