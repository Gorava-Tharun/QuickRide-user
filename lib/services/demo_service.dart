import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fare_model.dart';
import '../models/location_model.dart';
import '../models/offer_model.dart';
import '../models/ride_details_model.dart';
import '../models/ride_model.dart';
import '../models/vehicle_model.dart';
import 'fare_calculator.dart';
import 'offer_service.dart';
import 'settings_service.dart';

/// Centralized service managing Demo Captain data, simulated ride lifecycle,
/// and academic presentation demo flows in QuickRide.
///
/// Keeps all simulated demo records strictly separated from production Firestore collections.
class DemoService extends ChangeNotifier {
  DemoService._internal();
  static final DemoService _instance = DemoService._internal();
  factory DemoService() => _instance;

  bool _overrideDemoMode = false;
  bool _demoRewardClaimed = false;

  /// Whether Demo Mode is currently active in the application.
  bool get isDemoMode => _overrideDemoMode || SettingsService().demoModeEnabled;

  /// Whether the demo trip reward has already been claimed in this session.
  bool get isDemoRewardClaimed => _demoRewardClaimed;

  /// Enables or disables Demo Mode.
  void setDemoMode(bool enabled) {
    _overrideDemoMode = enabled;
    SettingsService().setDemoMode(enabled);
    notifyListeners();
  }

  /// Toggles Demo Mode state.
  void toggleDemoMode() {
    setDemoMode(!isDemoMode);
  }

  /// Verifies vehicle distance eligibility against QuickRide fare rules.
  FareCalculationResult checkVehicleEligibility({
    required String vehicleType,
    required double distanceKm,
  }) {
    return FareCalculator.calculate(
      vehicleType: vehicleType,
      distanceKm: distanceKm,
    );
  }

  /// Generates a clearly identified Demo Captain for the requested vehicle type.
  CaptainModel createDemoCaptain(String vehicleType) {
    return CaptainModel.demo(
      vehicleCategoryTitle: vehicleType,
      captainName: 'Demo Captain (Rajesh Kumar)',
      vehicleNumber: 'AP 09 CB 1234',
      rating: 4.8,
    );
  }

  /// Validates if a ride can be accepted by the demo captain.
  bool canAcceptRide(RideStatus status) {
    return status == RideStatus.searchingForCaptain;
  }

  /// Validates if the demo captain can arrive at the pickup point.
  bool canReachPickup(RideStatus status) {
    return status == RideStatus.captainFound || status == RideStatus.arriving;
  }

  /// Validates if the demo trip can be started.
  bool canStartRide(RideStatus status) {
    return status == RideStatus.arrived;
  }

  /// Validates if the demo trip can be completed.
  bool canCompleteRide(RideStatus status) {
    return status == RideStatus.rideStarted;
  }

  /// Creates a mock demo [RideRequest] ensuring data safety.
  RideRequest createDemoRideRequest({
    required RouteDetails routeDetails,
    required VehicleOption selectedVehicle,
    required FareDetails fareDetails,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) {
    final timestamp = DateTime.now();
    return RideRequest(
      rideId: 'DEMO_RIDE_${timestamp.millisecondsSinceEpoch}',
      userId: 'DEMO_STUDENT_USER',
      pickup: routeDetails.pickup,
      destination: routeDetails.destination,
      selectedVehicle: selectedVehicle,
      distanceKm: routeDetails.distanceKm,
      estimatedMinutes: routeDetails.estimatedMinutes,
      fareDetails: fareDetails,
      paymentMethod: paymentMethod,
      status: RideStatus.searchingForCaptain,
      createdAt: timestamp,
      isDemo: true,
      captain: createDemoCaptain(selectedVehicle.title),
    );
  }

  /// Broadcasts the demo booking to the shared demo bus so Captain App can display it.
  Future<void> broadcastDemoRideBooking(RideRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'rideId': request.rideId,
        'userId': request.userId,
        'passengerName': 'Rahul (Demo Rider)',
        'passengerPhone': '+91 98450 77123',
        'pickupAddress': request.pickup.address,
        'pickupLat': request.pickup.latitude,
        'pickupLng': request.pickup.longitude,
        'dropAddress': request.destination.address,
        'dropLat': request.destination.latitude,
        'dropLng': request.destination.longitude,
        'vehicleType': request.selectedVehicle.title,
        'fare': request.fareDetails.finalFare,
        'distanceKm': request.distanceKm,
        'estimatedMinutes': request.estimatedMinutes,
        'paymentMode': request.paymentMethod == PaymentMethod.cash ? 'Cash / UPI' : 'Online / UPI',
        'status': 'REQUESTED',
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('quickride_demo_active_booking', json.encode(map));
    } catch (_) {}
  }

  /// Clears active demo booking on the shared demo bus.
  Future<void> clearActiveDemoBooking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quickride_demo_active_booking');
    } catch (_) {}
  }

  /// Claims a simulated demo discount voucher without processing real currency.
  Map<String, dynamic> claimDemoReward() {
    _demoRewardClaimed = true;

    // Register a demo offer in OfferService if not present
    final demoOffer = Offer(
      id: 'offer_demo_reward',
      title: 'DEMO RIDE REWARD — 50% OFF',
      subtitle: 'Claimed from Demo Ride Completion',
      description:
          '🎉 Congratulations on completing the QuickRide Demo Ride!\n'
          'Use promo code DEMO50 for 50% off on your next demo ride.\n\n'
          '⚠️ Simulated demo reward for academic presentation & viva — no real money involved.',
      couponCode: 'DEMO50',
      discountType: DiscountType.percentage,
      discountValue: 50.0,
      maximumDiscount: 50.0,
      minimumFare: 30.0,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
      termsAndConditions:
          '• Valid on demo rides only.\n'
          '• Enter coupon code DEMO50 at checkout.\n'
          '• Simulated academic demonstration voucher.',
      badgeColor: const Color(0xFFFFC700),
      iconData: const IconData(0xe160, fontFamily: 'MaterialIcons'),
    );

    // Apply into active offers cache
    OfferService().applyOffer(demoOffer);
    notifyListeners();

    return {
      'claimed': true,
      'code': 'DEMO50',
      'title': 'DEMO RIDE REWARD — 50% OFF',
      'discount': '50% OFF',
      'message': 'Demo voucher DEMO50 claimed successfully! (Simulated reward)',
      'offer': demoOffer,
    };
  }

  /// Resets demo session state.
  void resetDemoState() {
    _overrideDemoMode = false;
    _demoRewardClaimed = false;
    notifyListeners();
  }
}
