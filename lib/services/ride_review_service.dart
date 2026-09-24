import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/firestore_models.dart';
import '../models/ride_review_model.dart';
import 'firebase_service.dart';
import 'session_manager.dart';

/// Decoupled service for storing and retrieving ride reviews.
///
/// Persists to SharedPreferences and synchronizes with Cloud Firestore.
/// Implements the singleton pattern — same instance throughout the app lifecycle.
class RideReviewService {
  factory RideReviewService() => _instance;
  RideReviewService._internal();
  static final RideReviewService _instance = RideReviewService._internal();

  static const String _prefsKey = 'quickride_reviews';

  /// In-memory cache populated lazily from SharedPreferences.
  final Map<String, RideReview> _cache = {};
  bool _loaded = false;

  /// Loads reviews from [SharedPreferences] into the in-memory cache.
  /// Idempotent — safe to call multiple times.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          final review = RideReview.fromJson(item as Map<String, dynamic>);
          _cache[review.rideId] = review;
        }
      }
    } catch (_) {
      // If decoding fails, start with empty cache — don't crash.
    }
    _loaded = true;
  }

  /// Persists the current cache to [SharedPreferences].
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _cache.values.map((r) => r.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (_) {
      // Persistence failures are non-fatal — in-memory data remains valid.
    }
  }

  /// Saves [review] locally and persists to disk.
  /// Saves [review] locally and persists to disk, and syncs to Firestore.
  ///
  /// If a review for [review.rideId] already exists, it is overwritten locally.
  Future<void> submitReview(RideReview review, {String? userId, String? captainId}) async {
    await _ensureLoaded();
    _cache[review.rideId] = review;
    await _persist();

    // Also sync to Cloud Firestore
    final fb = QuickRideFirebaseService();
    if (fb.isFirebaseAvailable) {
      final actualUserId = userId ?? SessionManager().currentUser.userId;
      final actualCaptainId = captainId ?? review.captainId;
      await fb.submitRating(
        FirestoreRatingModel(
          ratingId: '${review.rideId}_user',
          rideId: review.rideId,
          userId: actualUserId,
          captainId: actualCaptainId,
          ratedBy: 'user',
          stars: review.rating,
          rating: review.rating.toDouble(),
          review: review.reviewText,
          createdAt: review.createdAt,
        ),
      );
    }
  }

  /// Returns the [RideReview] for [rideId], or null if not yet rated.
  Future<RideReview?> getReviewForRide(String rideId) async {
    await _ensureLoaded();
    return _cache[rideId];
  }

  /// Returns true if the user has already submitted a rating for [rideId].
  Future<bool> hasRated(String rideId) async {
    await _ensureLoaded();
    if (_cache.containsKey(rideId)) return true;
    final fb = QuickRideFirebaseService();
    if (fb.isFirebaseAvailable) {
      final inFirestore = await fb.hasRated(rideId, ratedBy: 'user');
      if (inFirestore) return true;
    }
    return false;
  }

  /// Synchronous check using the in-memory cache only.
  ///
  /// Only reliable after [_ensureLoaded] has completed at least once.
  bool hasRatedSync(String rideId) => _cache.containsKey(rideId);

  /// Clears all reviews — used in tests.
  Future<void> clearAll() async {
    _cache.clear();
    _loaded = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
