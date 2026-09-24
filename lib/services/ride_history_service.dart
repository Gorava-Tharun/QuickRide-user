import '../models/ride_history_model.dart';
import 'ride_history_repository.dart';

/// Decoupled local service managing completed and cancelled ride history records.
///
/// Implements [RideHistoryRepository] as a singleton so the same in-memory store
/// is accessible across the application and easily swappable for cloud storage.
class RideHistoryService implements RideHistoryRepository {
  factory RideHistoryService() => _instance;
  RideHistoryService._internal();
  static final RideHistoryService _instance = RideHistoryService._internal();

  final List<RideHistoryItem> _history = [];

  /// Adds or updates a ride in local history (newest first).
  void addCompletedRide(RideHistoryItem item) {
    final idx = _history.indexWhere((r) => r.rideId == item.rideId);
    if (idx != -1) {
      _history[idx] = item;
    } else {
      _history.insert(0, item);
    }
  }

  /// Returns unmodifiable list of completed and cancelled rides, sorted newest first.
  List<RideHistoryItem> getHistory() {
    _history.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return List.unmodifiable(_history);
  }

  /// Marks a completed ride as rated and updates optional rating/review details.
  void markAsRated(
    String rideId,
    String reviewId, {
    int? rating,
    String? reviewText,
    List<String>? reviewTags,
  }) {
    final index = _history.indexWhere((item) => item.rideId == rideId);
    if (index == -1) return;
    _history[index] = _history[index].copyWith(
      isRated: true,
      reviewId: reviewId,
      rating: rating,
      reviewText: reviewText,
      reviewTags: reviewTags,
    );
  }

  /// Returns the history item for [rideId], or null if not found.
  RideHistoryItem? findById(String rideId) {
    try {
      return _history.firstWhere((item) => item.rideId == rideId);
    } catch (_) {
      return null;
    }
  }

  /// Clears history — used in tests.
  void clearHistory() => _history.clear();

  // ── RideHistoryRepository implementation ──────────────────────────────────

  @override
  Future<void> saveRide(RideHistoryItem item) async {
    addCompletedRide(item);
  }

  @override
  Future<List<RideHistoryItem>> getRides() async {
    return getHistory();
  }

  @override
  Future<RideHistoryItem?> getRideById(String rideId) async {
    return findById(rideId);
  }

  @override
  Future<void> updateRide(RideHistoryItem item) async {
    final idx = _history.indexWhere((r) => r.rideId == item.rideId);
    if (idx != -1) {
      _history[idx] = item;
    } else {
      _history.insert(0, item);
    }
  }

  @override
  Future<void> deleteRide(String rideId) async {
    _history.removeWhere((item) => item.rideId == rideId);
  }
}
