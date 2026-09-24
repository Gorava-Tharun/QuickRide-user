import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a geographic location point with readable name and address.
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.address,
    this.placeId,
  });

  final double latitude;
  final double longitude;
  final String name;
  final String address;
  final String? placeId;

  LatLng toLatLng() => LatLng(latitude, longitude);

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    String? name,
    String? address,
    String? placeId,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationPoint &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, name);
}

/// Represents route metrics between pickup and destination.
class RouteDetails {
  const RouteDetails({
    required this.pickup,
    required this.destination,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.polylinePoints,
  });

  final LocationPoint pickup;
  final LocationPoint destination;
  final double distanceKm;
  final int estimatedMinutes;
  final List<LatLng> polylinePoints;

  String get formattedDistance {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (estimatedMinutes < 60) {
      return '$estimatedMinutes min';
    }
    final hours = estimatedMinutes ~/ 60;
    final mins = estimatedMinutes % 60;
    return mins == 0 ? '$hours hr' : '$hours hr $mins min';
  }
}
