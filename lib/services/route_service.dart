import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import 'location_service.dart';

/// Service for generating route polylines and computing route metrics.
class RouteService {
  /// Builds route details between pickup and destination.
  /// Generates a realistic multi-point polyline along the geodesic path with waypoints.
  static RouteDetails generateRoute(LocationPoint pickup, LocationPoint destination) {
    final distanceKm = LocationService.calculateDistanceKm(
      pickup.latitude,
      pickup.longitude,
      destination.latitude,
      destination.longitude,
    );

    final estimatedMinutes = LocationService.estimateTravelTimeMinutes(distanceKm);

    final polylinePoints = _buildInterpolatedPoints(
      LatLng(pickup.latitude, pickup.longitude),
      LatLng(destination.latitude, destination.longitude),
    );

    return RouteDetails(
      pickup: pickup,
      destination: destination,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      polylinePoints: polylinePoints,
    );
  }

  /// Creates realistic intermediate road waypoints between start and end.
  static List<LatLng> _buildInterpolatedPoints(LatLng start, LatLng end) {
    final points = <LatLng>[start];
    const steps = 10;

    for (int i = 1; i < steps; i++) {
      final fraction = i / steps;
      // Slight road curvature simulation
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;

      // Small orthogonal deviation to simulate natural road curves
      final perpLat = -(end.longitude - start.longitude) * 0.05 * (fraction * (1 - fraction));
      final perpLng = (end.latitude - start.latitude) * 0.05 * (fraction * (1 - fraction));

      points.add(LatLng(lat + perpLat, lng + perpLng));
    }

    points.add(end);
    return points;
  }
}
