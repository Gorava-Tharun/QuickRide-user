/// Feedback tag options available in the quick-feedback chip row.
enum RatingFeedbackTag {
  cleanVehicle('Clean Vehicle'),
  friendlyCaptain('Friendly Captain'),
  safeRide('Safe Ride'),
  onTime('On Time'),
  smoothRide('Smooth Ride'),
  goodDriving('Good Driving');

  const RatingFeedbackTag(this.label);

  /// Human-readable label shown on the chip.
  final String label;
}

/// Immutable model representing a completed ride rating & review.
///
/// Stored locally via [RideReviewService]. Ready to be serialised and
/// persisted to a backend in a future step.
class RideReview {
  const RideReview({
    required this.reviewId,
    required this.rideId,
    required this.captainId,
    required this.rating,
    required this.createdAt,
    this.reviewText = '',
    this.feedbackTags = const [],
  }) : assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5');

  /// Unique ID for this review (UUID-style, generated at creation time).
  final String reviewId;

  /// ID of the [RideHistoryItem] / [RideRequest] this review belongs to.
  final String rideId;

  /// ID of the captain who completed the ride.
  final String captainId;

  /// Star rating selected by the user (1–5).
  final int rating;

  /// Optional free-text review written by the user. May be empty.
  final String reviewText;

  /// Quick-feedback tags selected by the user.
  final List<RatingFeedbackTag> feedbackTags;

  /// Timestamp when the review was submitted.
  final DateTime createdAt;

  /// Returns the human-readable rating message matching [rating].
  String get ratingMessage {
    switch (rating) {
      case 1:
        return "We're sorry your experience wasn't good.";
      case 2:
        return "We'll try to improve your experience.";
      case 3:
        return 'Thanks for your feedback.';
      case 4:
        return "Great! We're glad you enjoyed your ride.";
      case 5:
        return 'Excellent! Thanks for rating QuickRide.';
      default:
        return '';
    }
  }

  /// Converts the review to a JSON-compatible map for [shared_preferences].
  Map<String, dynamic> toJson() => {
        'reviewId': reviewId,
        'rideId': rideId,
        'captainId': captainId,
        'rating': rating,
        'reviewText': reviewText,
        'feedbackTags':
            feedbackTags.map((t) => t.name).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  /// Restores a [RideReview] from a JSON map read from [shared_preferences].
  factory RideReview.fromJson(Map<String, dynamic> json) {
    final tagNames = (json['feedbackTags'] as List<dynamic>? ?? [])
        .cast<String>();
    final tags = tagNames
        .map((name) {
          try {
            return RatingFeedbackTag.values
                .firstWhere((t) => t.name == name);
          } catch (_) {
            return null;
          }
        })
        .whereType<RatingFeedbackTag>()
        .toList();

    return RideReview(
      reviewId: json['reviewId'] as String,
      rideId: json['rideId'] as String,
      captainId: json['captainId'] as String,
      rating: json['rating'] as int,
      reviewText: json['reviewText'] as String? ?? '',
      feedbackTags: tags,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
