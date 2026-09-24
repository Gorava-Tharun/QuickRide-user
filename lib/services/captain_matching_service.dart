import 'dart:async';
import '../models/ride_model.dart';
import 'fare_calculator.dart';

/// Callback type for status updates during captain matching search.
typedef StatusUpdateCallback = void Function(String statusMessage);

/// Decoupled Captain Matching Service (Step 44).
///
/// Handles captain discovery, vehicle distance verification, and assignment.
class CaptainMatchingService {
  /// Searches for an eligible nearby verified captain.
  ///
  /// Emits progressive status updates via [onStatusUpdate].
  /// Verifies vehicle availability for route distance.
  /// Returns a matched [CaptainModel] or null if no captain is available.
  Future<CaptainModel?> searchForCaptain({
    required RideRequest rideRequest,
    required StatusUpdateCallback onStatusUpdate,
    int totalDurationSeconds = 6,
    bool simulateNoCaptain = false,
  }) async {
    // 1. Verify that the requested vehicle is available for the trip distance
    final fareCheck = FareCalculator.calculate(
      vehicleType: rideRequest.selectedVehicle.title,
      distanceKm: rideRequest.distanceKm,
    );

    if (!fareCheck.available) {
      onStatusUpdate(fareCheck.unavailableReason ?? 'Vehicle is unavailable for this distance.');
      return null;
    }

    final statusMessages = [
      'Finding nearby captains...',
      'Checking availability...',
      'Connecting you with a captain...',
    ];

    onStatusUpdate(statusMessages[0]);

    if (totalDurationSeconds <= 0) {
      if (simulateNoCaptain) return null;
      return CaptainModel.demo(vehicleCategoryTitle: rideRequest.selectedVehicle.title);
    }

    final intervalMs = (totalDurationSeconds * 1000) ~/ statusMessages.length;

    for (int i = 0; i < statusMessages.length; i++) {
      onStatusUpdate(statusMessages[i]);
      await Future<void>.delayed(Duration(milliseconds: intervalMs));
    }

    if (simulateNoCaptain) {
      return null;
    }

    return CaptainModel.demo(
      vehicleCategoryTitle: rideRequest.selectedVehicle.title,
    );
  }
}
