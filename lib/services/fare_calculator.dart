import '../models/fare_model.dart';
import '../models/vehicle_model.dart';

/// STEP 44: Centralized Fare Calculation Result
class FareCalculationResult {
  final bool available;
  final double ratePerKm;
  final double fare;
  final String selectedSlab;
  final String? unavailableReason;

  const FareCalculationResult({
    required this.available,
    required this.ratePerKm,
    required this.fare,
    required this.selectedSlab,
    this.unavailableReason,
  });

  factory FareCalculationResult.unavailable({
    required String reason,
    String selectedSlab = 'None',
  }) {
    return FareCalculationResult(
      available: false,
      ratePerKm: 0.0,
      fare: 0.0,
      selectedSlab: selectedSlab,
      unavailableReason: reason,
    );
  }

  @override
  String toString() {
    return 'FareCalculationResult(available: $available, ratePerKm: $ratePerKm, fare: $fare, selectedSlab: $selectedSlab, unavailableReason: $unavailableReason)';
  }
}

/// Centralized fare calculation service for QuickRide.
///
/// Implements Step 44 single-slab pricing rules:
/// - Bike:
///   < 1 km: Unavailable
///   1 <= d <= 5: ₹8/km (1–5 km)
///   5 < d <= 10: ₹5.50/km (5–10 km)
///   10 < d <= 20: ₹4.50/km (10–20 km)
///   20 < d <= 35: ₹4.00/km (20–35 km)
///   35 < d <= 50: ₹3.50/km (35–50 km)
///   > 50 km: Unavailable
///
/// - Auto (Bike × 1.5):
///   < 1 km: Unavailable
///   1 <= d <= 5: ₹12/km (1–5 km)
///   5 < d <= 10: ₹8.25/km (5–10 km)
///   10 < d <= 20: ₹6.75/km (10–20 km)
///   20 < d <= 35: ₹6.00/km (20–35 km)
///   35 < d <= 50: ₹5.25/km (35–50 km)
///   > 50 km: Unavailable
///
/// - Car (Bike × 2.5, min 5 km, max 150 km):
///   < 5 km: Unavailable
///   5 <= d <= 10: ₹13.75/km (5–10 km)
///   10 < d <= 20: ₹11.25/km (10–20 km)
///   20 < d <= 35: ₹10.00/km (20–35 km)
///   35 < d <= 150: ₹8.75/km (35–150 km)
///   > 150 km: Unavailable
class FareCalculator {
  /// Core centralized calculation engine.
  /// Accepts vehicleType ('Bike', 'Auto', 'Car', or category name) and distance in km.
  static FareCalculationResult calculate({
    required String vehicleType,
    required double distanceKm,
  }) {
    final vType = vehicleType.trim().toLowerCase();

    if (vType.contains('bike')) {
      return _calculateBikeFare(distanceKm);
    } else if (vType.contains('auto')) {
      return _calculateAutoFare(distanceKm);
    } else if (vType.contains('car')) {
      return _calculateCarFare(distanceKm);
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Unsupported vehicle type: $vehicleType',
      );
    }
  }

  /// Helper accepting [VehicleCategory]
  static FareCalculationResult calculateForCategory({
    required VehicleCategory category,
    required double distanceKm,
  }) {
    switch (category) {
      case VehicleCategory.bike:
        return _calculateBikeFare(distanceKm);
      case VehicleCategory.auto:
        return _calculateAutoFare(distanceKm);
      case VehicleCategory.car:
        return _calculateCarFare(distanceKm);
    }
  }

  static FareCalculationResult _calculateBikeFare(double distance) {
    if (distance < 1.0) {
      return FareCalculationResult.unavailable(
        reason: 'Distance is below 1 km minimum for Bike.',
      );
    } else if (distance <= 5.0) {
      const rate = 8.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '1–5 km',
      );
    } else if (distance <= 10.0) {
      const rate = 5.50;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '5–10 km',
      );
    } else if (distance <= 20.0) {
      const rate = 4.50;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '10–20 km',
      );
    } else if (distance <= 35.0) {
      const rate = 4.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '20–35 km',
      );
    } else if (distance <= 50.0) {
      const rate = 3.50;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '35–50 km',
      );
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Distance exceeds 50 km maximum for Bike.',
      );
    }
  }

  static FareCalculationResult _calculateAutoFare(double distance) {
    if (distance < 1.0) {
      return FareCalculationResult.unavailable(
        reason: 'Distance is below 1 km minimum for Auto.',
      );
    } else if (distance <= 5.0) {
      const rate = 12.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '1–5 km',
      );
    } else if (distance <= 10.0) {
      const rate = 8.25;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '5–10 km',
      );
    } else if (distance <= 20.0) {
      const rate = 6.75;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '10–20 km',
      );
    } else if (distance <= 35.0) {
      const rate = 6.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '20–35 km',
      );
    } else if (distance <= 50.0) {
      const rate = 5.25;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '35–50 km',
      );
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Distance exceeds 50 km maximum for Auto.',
      );
    }
  }

  static FareCalculationResult _calculateCarFare(double distance) {
    if (distance < 5.0) {
      return FareCalculationResult.unavailable(
        reason: 'Distance is below 5 km minimum for Car.',
      );
    } else if (distance <= 10.0) {
      const rate = 13.75;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '5–10 km',
      );
    } else if (distance <= 20.0) {
      const rate = 11.25;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '10–20 km',
      );
    } else if (distance <= 35.0) {
      const rate = 10.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '20–35 km',
      );
    } else if (distance <= 150.0) {
      const rate = 8.75;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '35–150 km',
      );
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Distance exceeds 150 km maximum for Car.',
      );
    }
  }

  /// Calculates complete fare breakdown given vehicle, distance, and duration.
  /// Uses the Step 44 centralized single-slab pricing engine.
  static FareDetails calculateFare({
    required VehicleCategory category,
    required double distanceKm,
    int estimatedMinutes = 0,
    int waitingMinutes = 0,
    bool applyFirstRideDiscount = false,
  }) {
    final result = calculateForCategory(
      category: category,
      distanceKm: distanceKm,
    );

    final double originalFare = result.available ? result.fare : 0.0;
    final double discount = (result.available && applyFirstRideDiscount)
        ? _round(originalFare * 0.50)
        : 0.0;
    final double finalFare = _round(originalFare - discount);

    return FareDetails(
      baseFare: 0.0,
      distanceFare: originalFare,
      timeFare: 0.0,
      waitingCharge: 0.0,
      originalFare: originalFare,
      discount: discount,
      finalFare: finalFare,
      discountPercentage: applyFirstRideDiscount ? 50.0 : 0.0,
      ratePerKm: result.ratePerKm,
      selectedSlab: result.selectedSlab,
      isAvailable: result.available,
      unavailableReason: result.unavailableReason,
    );
  }

  static double _round(double val) {
    return (val * 100).roundToDouble() / 100.0;
  }
}
