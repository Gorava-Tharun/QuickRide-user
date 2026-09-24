import 'package:flutter/material.dart';

/// Categories of vehicles available on QuickRide.
enum VehicleCategory {
  bike,
  auto,
  car,
}

/// Represents a selectable vehicle option on the Vehicle Selection Screen.
class VehicleOption {
  const VehicleOption({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.capacity,
    required this.icon,
    required this.estimatedArrival,
  });

  final String id;
  final VehicleCategory category;
  final String title;
  final String subtitle;
  final String capacity;
  final IconData icon;
  final String estimatedArrival;

  /// Default vehicle options according to QuickRide Step 6 specifications.
  static const List<VehicleOption> standardOptions = [
    VehicleOption(
      id: 'quickride_bike',
      category: VehicleCategory.bike,
      title: 'Bike',
      subtitle: 'Fast & Affordable',
      capacity: '1 Passenger',
      icon: Icons.two_wheeler_rounded,
      estimatedArrival: '2-3 mins away',
    ),
    VehicleOption(
      id: 'quickride_auto',
      category: VehicleCategory.auto,
      title: 'Auto',
      subtitle: 'Comfortable & Convenient',
      capacity: 'Up to 3 Passengers',
      icon: Icons.electric_rickshaw_rounded,
      estimatedArrival: '3-4 mins away',
    ),
    VehicleOption(
      id: 'quickride_car',
      category: VehicleCategory.car,
      title: 'Car',
      subtitle: 'Comfortable & Premium',
      capacity: 'Up to 4 Passengers',
      icon: Icons.directions_car_rounded,
      estimatedArrival: '4-5 mins away',
    ),
  ];
}
