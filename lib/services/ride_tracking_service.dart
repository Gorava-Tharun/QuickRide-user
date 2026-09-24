import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/ride_history_model.dart';
import '../models/ride_model.dart';
import '../models/firestore_models.dart';
import 'notification_service.dart';
import 'ride_history_service.dart';

/// Service managing local mock captain movement, ETA updates, and ride status transitions.
///
/// Decouples simulation logic from the UI. Ready to be replaced by WebSockets/GPS in production.
class RideTrackingService extends ChangeNotifier {
  RideTrackingService({
    required RideRequest initialRequest,
    this.simulationStepMs = 500,
    this.totalArrivalSteps = 12,
  }) {
    _currentRequest = initialRequest;
    _initializeInitialCaptainLocation();
  }

  final int simulationStepMs;
  final int totalArrivalSteps;

  late RideRequest _currentRequest;
  Timer? _movementTimer;
  int _currentStep = 0;

  RideRequest get currentRequest => _currentRequest;
  RideStatus get status => _currentRequest.status;
  CaptainLocation? get captainLocation => _currentRequest.captainLocation;

  void _initializeInitialCaptainLocation() {
    final pickup = _currentRequest.pickup;
    // Initial mock position placed ~0.015 deg (~1.5 km) offset from pickup
    final initialLat = pickup.latitude + 0.012;
    final initialLng = pickup.longitude + 0.010;

    final initialLocation = CaptainLocation(
      latitude: initialLat,
      longitude: initialLng,
      bearing: _calculateBearing(initialLat, initialLng, pickup.latitude, pickup.longitude),
    );

    _currentRequest = _currentRequest.copyWith(
      captainLocation: initialLocation,
      status: RideStatus.captainFound,
    );
  }

  /// Updates Captain location from live Firestore / GPS updates
  void updateCaptainLocationFromGps(double lat, double lng) {
    // Cancel mock movement timer since live GPS data is active
    _movementTimer?.cancel();

    final prevLocation = _currentRequest.captainLocation;
    final bearing = prevLocation != null
        ? _calculateBearing(prevLocation.latitude, prevLocation.longitude, lat, lng)
        : 0.0;

    final updatedLocation = CaptainLocation(
      latitude: lat,
      longitude: lng,
      bearing: bearing,
    );

    _currentRequest = _currentRequest.copyWith(
      captainLocation: updatedLocation,
    );
    notifyListeners();
  }

  /// Syncs ride status from Cloud Firestore lifecycle
  void updateStatusFromFirestore(SharedRideStatus firestoreStatus) {
    RideStatus mappedStatus;
    switch (firestoreStatus) {
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

    if (_currentRequest.status != mappedStatus) {
      _currentRequest = _currentRequest.copyWith(status: mappedStatus);
      if (mappedStatus == RideStatus.rideCompleted) {
        _movementTimer?.cancel();
        RideHistoryService().addCompletedRide(
          RideHistoryItem.fromRequest(_currentRequest),
        );
      }
      notifyListeners();
    }
  }

  /// Starts simulated captain movement toward pickup location.
  void startArrivingSimulation() {
    _movementTimer?.cancel();
    _currentStep = 0;

    _currentRequest = _currentRequest.copyWith(
      status: RideStatus.arriving,
    );
    notifyListeners();

    final pickup = _currentRequest.pickup;
    final startLat = _currentRequest.captainLocation!.latitude;
    final startLng = _currentRequest.captainLocation!.longitude;

    _movementTimer = Timer.periodic(Duration(milliseconds: simulationStepMs), (timer) {
      _currentStep++;
      final progress = (_currentStep / totalArrivalSteps).clamp(0.0, 1.0);

      // Interpolate position along line to pickup
      final newLat = startLat + (pickup.latitude - startLat) * progress;
      final newLng = startLng + (pickup.longitude - startLng) * progress;
      final bearing = _calculateBearing(newLat, newLng, pickup.latitude, pickup.longitude);

      final remainingEta = math.max(0, ((1.0 - progress) * 3).ceil());

      final updatedCaptain = _currentRequest.captain?.copyWith(
        estimatedArrivalMinutes: remainingEta,
      ) ?? _currentRequest.captain;

      final updatedLocation = CaptainLocation(
        latitude: newLat,
        longitude: newLng,
        bearing: bearing,
      );

      if (progress >= 1.0) {
        timer.cancel();
        _currentRequest = _currentRequest.copyWith(
          status: RideStatus.arrived,
          captainLocation: updatedLocation,
          captain: updatedCaptain,
        );
        NotificationService().addNotification(
          AppNotification(
            id: 'notif_arrived_${_currentRequest.rideId}',
            type: NotificationType.captainArriving,
            title: 'Captain Arrived',
            message: 'Your captain has reached the pickup location.',
            createdAt: DateTime.now(),
            rideId: _currentRequest.rideId,
          ),
        );
      } else {
        _currentRequest = _currentRequest.copyWith(
          captainLocation: updatedLocation,
          captain: updatedCaptain,
        );
      }

      notifyListeners();
    });
  }

  /// Tapped by user when captain has arrived to start trip.
  void startRide() {
    _movementTimer?.cancel();
    _currentStep = 0;

    _currentRequest = _currentRequest.copyWith(
      status: RideStatus.rideStarted,
    );
    NotificationService().addNotification(
      AppNotification(
        id: 'notif_started_${_currentRequest.rideId}',
        type: NotificationType.rideStarted,
        title: 'Ride Started',
        message: 'Your QuickRide trip has started. Enjoy your ride!',
        createdAt: DateTime.now(),
        rideId: _currentRequest.rideId,
      ),
    );
    notifyListeners();

    _startInRideSimulation();
  }

  void _startInRideSimulation() {
    final destination = _currentRequest.destination;
    final startLat = _currentRequest.captainLocation!.latitude;
    final startLng = _currentRequest.captainLocation!.longitude;

    _movementTimer = Timer.periodic(Duration(milliseconds: simulationStepMs), (timer) {
      _currentStep++;
      final progress = (_currentStep / totalArrivalSteps).clamp(0.0, 1.0);

      final newLat = startLat + (destination.latitude - startLat) * progress;
      final newLng = startLng + (destination.longitude - startLng) * progress;
      final bearing = _calculateBearing(newLat, newLng, destination.latitude, destination.longitude);

      final updatedLocation = CaptainLocation(
        latitude: newLat,
        longitude: newLng,
        bearing: bearing,
      );

      if (progress >= 1.0) {
        timer.cancel();
        _currentRequest = _currentRequest.copyWith(
          status: RideStatus.rideCompleted,
          captainLocation: updatedLocation,
        );
        RideHistoryService().addCompletedRide(
          RideHistoryItem.fromRequest(_currentRequest),
        );
        NotificationService().addNotification(
          AppNotification(
            id: 'notif_completed_${_currentRequest.rideId}',
            type: NotificationType.rideCompleted,
            title: 'Ride Completed',
            message: 'Thank you for riding with QuickRide! Please take a moment to rate your captain.',
            createdAt: DateTime.now(),
            rideId: _currentRequest.rideId,
          ),
        );
      } else {
        _currentRequest = _currentRequest.copyWith(
          captainLocation: updatedLocation,
        );
      }

      notifyListeners();
    });
  }

  /// Stops tracking and sets status to CANCELLED.
  void cancelRide() {
    _movementTimer?.cancel();
    _currentRequest = _currentRequest.copyWith(
      status: RideStatus.cancelled,
    );
    RideHistoryService().addCompletedRide(
      RideHistoryItem.fromRequest(_currentRequest).copyWith(
        status: RideStatus.cancelled,
      ),
    );
    notifyListeners();
  }

  double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    final dLng = (endLng - startLng) * (math.pi / 180.0);
    final lat1 = startLat * (math.pi / 180.0);
    final lat2 = endLat * (math.pi / 180.0);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final brng = math.atan2(y, x) * (180.0 / math.pi);
    return (brng + 360.0) % 360.0;
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}

extension CaptainModelCopyWith on CaptainModel {
  CaptainModel copyWith({
    int? estimatedArrivalMinutes,
  }) {
    return CaptainModel(
      id: id,
      name: name,
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      vehicleNumber: vehicleNumber,
      rating: rating,
      completedRides: completedRides,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      phone: phone,
      avatarUrl: avatarUrl,
    );
  }
}
