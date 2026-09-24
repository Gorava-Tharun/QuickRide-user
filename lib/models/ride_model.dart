import 'fare_model.dart';
import 'firestore_models.dart';
import 'location_model.dart';
import 'ride_details_model.dart';
import 'vehicle_model.dart';

/// Extensible ride status state machine enum for QuickRide.
enum RideStatus {
  searchingForCaptain,
  captainFound,
  arriving,
  arrived,
  rideStarted,
  cancelled,
  noCaptainAvailable,
  rideCompleted,
}

extension RideStatusExtension on RideStatus {
  String get label {
    switch (this) {
      case RideStatus.searchingForCaptain:
        return 'Searching for Captain';
      case RideStatus.captainFound:
        return 'Captain Found';
      case RideStatus.arriving:
        return 'Captain is on the way';
      case RideStatus.arrived:
        return 'Captain has arrived';
      case RideStatus.rideStarted:
        return 'Ride in Progress';
      case RideStatus.cancelled:
        return 'Ride Cancelled';
      case RideStatus.noCaptainAvailable:
        return 'No Captain Available';
      case RideStatus.rideCompleted:
        return 'Ride Completed';
    }
  }
}

/// Represents real-time or simulated Captain geographical position.
class CaptainLocation {
  const CaptainLocation({
    required this.latitude,
    required this.longitude,
    this.bearing = 0.0,
  });

  final double latitude;
  final double longitude;
  final double bearing;
}

/// Demo/Mock Captain Data Model.
class CaptainModel {
  const CaptainModel({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.rating,
    required this.completedRides,
    required this.estimatedArrivalMinutes,
    this.phone = '+91 98765 43210',
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleNumber;
  final double rating;
  final int completedRides;
  final int estimatedArrivalMinutes;
  final String phone;
  final String? avatarUrl;

  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedEta => '$estimatedArrivalMinutes min';
  String get formattedCompletedRides => '$completedRides rides';

  /// Standard demo captain factory.
  factory CaptainModel.demo({required String vehicleCategoryTitle}) {
    String modelName = 'Standard Vehicle';
    if (vehicleCategoryTitle.toLowerCase().contains('bike')) {
      modelName = 'Hero Splendor Plus';
    } else if (vehicleCategoryTitle.toLowerCase().contains('auto')) {
      modelName = 'Bajaj RE Auto';
    } else if (vehicleCategoryTitle.toLowerCase().contains('car')) {
      modelName = 'Maruti Swift Dzire';
    }

    return CaptainModel(
      id: 'CPT_DEMO_9981',
      name: 'Demo Captain (Rajesh Kumar)',
      vehicleType: vehicleCategoryTitle,
      vehicleModel: modelName,
      vehicleNumber: 'AP 09 CB 1234',
      rating: 4.8,
      completedRides: 1240,
      estimatedArrivalMinutes: 3,
    );
  }
}

/// Comprehensive model encapsulating a ride request and live tracking state.
class RideRequest {
  const RideRequest({
    required this.rideId,
    required this.userId,
    required this.pickup,
    required this.destination,
    required this.selectedVehicle,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.fareDetails,
    required this.paymentMethod,
    required this.status,
    this.captain,
    this.captainLocation,
    this.paymentStatus,
    required this.createdAt,
  });

  final String rideId;
  final String userId;
  final LocationPoint pickup;
  final LocationPoint destination;
  final VehicleOption selectedVehicle;
  final double distanceKm;
  final int estimatedMinutes;
  final FareDetails fareDetails;
  final PaymentMethod paymentMethod;
  final RideStatus status;
  final CaptainModel? captain;
  final CaptainLocation? captainLocation;
  final String? paymentStatus;
  final DateTime createdAt;

  String get paymentMethodTitle {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.online:
        return 'Online Payment';
    }
  }

  /// Creates an initial ride request in SEARCHING_FOR_CAPTAIN state.
  factory RideRequest.create({
    required RouteDetails routeDetails,
    required VehicleOption selectedVehicle,
    required FareDetails fareDetails,
    required PaymentMethod paymentMethod,
    String userId = 'USER_DEMO_1001',
  }) {
    final timestamp = DateTime.now();
    final rideId = 'QR_${timestamp.millisecondsSinceEpoch}';

    return RideRequest(
      rideId: rideId,
      userId: userId,
      pickup: routeDetails.pickup,
      destination: routeDetails.destination,
      selectedVehicle: selectedVehicle,
      distanceKm: routeDetails.distanceKm,
      estimatedMinutes: routeDetails.estimatedMinutes,
      fareDetails: fareDetails,
      paymentMethod: paymentMethod,
      status: RideStatus.searchingForCaptain,
      createdAt: timestamp,
    );
  }

  RideRequest copyWith({
    RideStatus? status,
    CaptainModel? captain,
    CaptainLocation? captainLocation,
    String? paymentStatus,
  }) {
    return RideRequest(
      rideId: rideId,
      userId: userId,
      pickup: pickup,
      destination: destination,
      selectedVehicle: selectedVehicle,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      fareDetails: fareDetails,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      captain: captain ?? this.captain,
      captainLocation: captainLocation ?? this.captainLocation,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
    );
  }

  /// Reconstructs a [RideRequest] from a Firestore [SharedRideModel]
  factory RideRequest.fromSharedRide(
    SharedRideModel shared, {
    CaptainModel? captain,
  }) {
    final vehicle = VehicleOption.standardOptions.firstWhere(
      (v) => v.title.toLowerCase() == shared.vehicleType.toLowerCase(),
      orElse: () => VehicleOption.standardOptions.first,
    );

    final pickupLat = (shared.pickupLocation['lat'] as num?)?.toDouble() ?? 12.9716;
    final pickupLng = (shared.pickupLocation['lng'] as num?)?.toDouble() ?? 77.5946;
    final destLat = (shared.destinationLocation['lat'] as num?)?.toDouble() ?? 12.9352;
    final destLng = (shared.destinationLocation['lng'] as num?)?.toDouble() ?? 77.6245;

    RideStatus mappedStatus;
    switch (shared.status) {
      case SharedRideStatus.requested:
        mappedStatus = RideStatus.searchingForCaptain;
        break;
      case SharedRideStatus.accepted:
        mappedStatus = RideStatus.captainFound;
        break;
      case SharedRideStatus.arrived:
        mappedStatus = RideStatus.arrived;
        break;
      case SharedRideStatus.inProgress:
        mappedStatus = RideStatus.rideStarted;
        break;
      case SharedRideStatus.completed:
        mappedStatus = RideStatus.rideCompleted;
        break;
      case SharedRideStatus.cancelled:
        mappedStatus = RideStatus.cancelled;
        break;
    }

    CaptainLocation? captainLoc;
    if (shared.captainLocation != null) {
      final cLat = (shared.captainLocation!['latitude'] as num?)?.toDouble();
      final cLng = (shared.captainLocation!['longitude'] as num?)?.toDouble();
      final cBearing = (shared.captainLocation!['bearing'] as num?)?.toDouble() ?? 0.0;
      if (cLat != null && cLng != null) {
        captainLoc = CaptainLocation(
          latitude: cLat,
          longitude: cLng,
          bearing: cBearing,
        );
      }
    }

    return RideRequest(
      rideId: shared.rideId,
      userId: shared.userId,
      pickup: LocationPoint(
        name: shared.pickup,
        address: shared.pickup,
        latitude: pickupLat,
        longitude: pickupLng,
      ),
      destination: LocationPoint(
        name: shared.destination,
        address: shared.destination,
        latitude: destLat,
        longitude: destLng,
      ),
      selectedVehicle: vehicle,
      distanceKm: shared.distance,
      estimatedMinutes: shared.estimatedTime,
      fareDetails: FareDetails(
        baseFare: 30.0,
        distanceFare: ((shared.originalFare ?? shared.fare) - 30.0).clamp(0.0, double.infinity),
        timeFare: 0.0,
        waitingCharge: 0.0,
        originalFare: shared.originalFare ?? shared.fare,
        discount: shared.discountAmount ?? 0.0,
        finalFare: shared.fare,
        offerDiscount: (shared.discountAmount ?? 0.0) > 0 ? (shared.discountAmount ?? 0.0) : 0.0,
        offerLabel: shared.couponCode != null ? '${shared.couponCode} Promo' : null,
      ),
      paymentMethod: PaymentMethod.cash,
      status: mappedStatus,
      captain: captain,
      captainLocation: captainLoc,
      paymentStatus: shared.paymentStatus,
      createdAt: shared.requestedAt,
    );
  }
}
