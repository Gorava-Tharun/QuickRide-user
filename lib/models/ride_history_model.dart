import 'fare_model.dart';
import 'location_model.dart';
import 'ride_details_model.dart';
import 'ride_model.dart';
import 'vehicle_model.dart';

/// Represents a completed or cancelled ride entry saved in local user history.
class RideHistoryItem {
  const RideHistoryItem({
    required this.rideId,
    required this.userId,
    required this.pickup,
    required this.destination,
    required this.vehicle,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.fareDetails,
    required this.paymentMethod,
    required this.captain,
    required this.completedAt,
    DateTime? createdAt,
    this.status = RideStatus.rideCompleted,
    this.paymentStatus = 'PAID',
    this.isRated = false,
    this.reviewId,
    this.rating,
    this.reviewText,
    this.reviewTags,
  }) : createdAt = createdAt ?? completedAt;

  final String rideId;
  final String userId;
  final LocationPoint pickup;
  final LocationPoint destination;
  final VehicleOption vehicle;
  final double distanceKm;
  final int estimatedMinutes;
  final FareDetails fareDetails;
  final PaymentMethod paymentMethod;
  final CaptainModel captain;
  final DateTime completedAt;
  final DateTime createdAt;
  final RideStatus status;
  final String paymentStatus;

  /// Whether the user has already submitted a rating for this ride.
  final bool isRated;

  /// Reference to the associated [RideReview.reviewId], if rated.
  final String? reviewId;

  /// Optional cached star rating (1–5) if rated.
  final int? rating;

  /// Optional cached review comments if provided.
  final String? reviewText;

  /// Optional cached feedback tags selected by user.
  final List<String>? reviewTags;

  /// Whether the ride was cancelled.
  bool get isCancelled => status == RideStatus.cancelled;

  /// Formatted date string, e.g. "07 Sep 2026".
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = completedAt.day.toString().padLeft(2, '0');
    final month = months[completedAt.month - 1];
    final year = completedAt.year;
    return '$day $month $year';
  }

  /// Formatted time string, e.g. "05:30 PM".
  String get formattedTime {
    final hour = completedAt.hour == 0
        ? 12
        : (completedAt.hour > 12 ? completedAt.hour - 12 : completedAt.hour);
    final minute = completedAt.minute.toString().padLeft(2, '0');
    final period = completedAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Formatted date & time, e.g. "07 Sep 2026, 05:30 PM".
  String get formattedDateTime => '$formattedDate, $formattedTime';

  /// Human readable status label.
  String get formattedStatus {
    switch (status) {
      case RideStatus.cancelled:
        return 'Ride Cancelled';
      case RideStatus.rideCompleted:
        return 'Completed';
      default:
        return status.label;
    }
  }

  /// Creates a [RideHistoryItem] from a [RideRequest].
  factory RideHistoryItem.fromRequest(RideRequest request) {
    final now = DateTime.now();
    return RideHistoryItem(
      rideId: request.rideId,
      userId: request.userId,
      pickup: request.pickup,
      destination: request.destination,
      vehicle: request.selectedVehicle,
      distanceKm: request.distanceKm,
      estimatedMinutes: request.estimatedMinutes,
      fareDetails: request.fareDetails,
      paymentMethod: request.paymentMethod,
      captain: request.captain ??
          CaptainModel.demo(vehicleCategoryTitle: request.selectedVehicle.title),
      completedAt: now,
      createdAt: now,
      status: request.status == RideStatus.cancelled
          ? RideStatus.cancelled
          : RideStatus.rideCompleted,
      paymentStatus: request.paymentStatus ?? (request.paymentMethod == PaymentMethod.cash ? 'PENDING' : 'PAID'),
    );
  }

  /// Reconstructs a [RideRequest] from this history item (e.g. to open [RatingReviewScreen] or [PaymentScreen]).
  RideRequest toRideRequest() {
    return RideRequest(
      rideId: rideId,
      userId: userId,
      pickup: pickup,
      destination: destination,
      selectedVehicle: vehicle,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      fareDetails: fareDetails,
      paymentMethod: paymentMethod,
      captain: captain,
      status: status,
      paymentStatus: paymentStatus,
      createdAt: createdAt,
    );
  }

  /// Returns a copy of this item with overridden fields.
  RideHistoryItem copyWith({
    bool? isRated,
    String? reviewId,
    RideStatus? status,
    String? paymentStatus,
    DateTime? completedAt,
    DateTime? createdAt,
    int? rating,
    String? reviewText,
    List<String>? reviewTags,
  }) {
    return RideHistoryItem(
      rideId: rideId,
      userId: userId,
      pickup: pickup,
      destination: destination,
      vehicle: vehicle,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      fareDetails: fareDetails,
      paymentMethod: paymentMethod,
      captain: captain,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isRated: isRated ?? this.isRated,
      reviewId: reviewId ?? this.reviewId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      reviewTags: reviewTags ?? this.reviewTags,
    );
  }

  String get paymentMethodTitle {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.online:
        return 'Online Payment';
    }
  }
}
