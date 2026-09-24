import '../models/ride_history_model.dart';

/// Abstract repository interface for managing ride history records.
///
/// Decouples persistence mechanisms (in-memory, local database, or future backend)
/// from the UI.
abstract class RideHistoryRepository {
  /// Saves or appends a ride history record.
  Future<void> saveRide(RideHistoryItem item);

  /// Retrieves all saved rides, sorted newest first.
  Future<List<RideHistoryItem>> getRides();

  /// Finds a specific ride history record by [rideId], or null if not found.
  Future<RideHistoryItem?> getRideById(String rideId);

  /// Updates an existing ride history record.
  Future<void> updateRide(RideHistoryItem item);

  /// Deletes a ride history record by [rideId].
  Future<void> deleteRide(String rideId);
}
