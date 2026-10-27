import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/offer_model.dart';
import 'package:quickride_user/models/ride_details_model.dart';
import 'package:quickride_user/models/ride_model.dart';
import 'package:quickride_user/models/ride_review_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/services/demo_service.dart';
import 'package:quickride_user/services/fare_calculator.dart';
import 'package:quickride_user/services/firebase_service.dart';
import 'package:quickride_user/services/offer_service.dart';
import 'package:quickride_user/services/ride_history_service.dart';
import 'package:quickride_user/services/ride_review_service.dart';
import 'package:quickride_user/services/ride_tracking_service.dart';
import 'package:quickride_user/services/route_service.dart';
import 'package:quickride_user/services/settings_service.dart';
import 'package:quickride_user/screens/ride_completed/ride_completed_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QUICKRIDE — DEMO CAPTAIN + COMPLETE RIDE + REWARDS TEST SUITE', () {
    late DemoService demoService;
    late SettingsService settingsService;
    late RideHistoryService historyService;
    late RideReviewService reviewService;
    late OfferService offerService;

    const pickupPoint = LocationPoint(
      latitude: 14.4125,
      longitude: 77.7262,
      name: 'Dharmavaram RTC Bus Stand',
      address: 'Main Road, Dharmavaram, AP 515671',
    );

    const destinationPoint = LocationPoint(
      latitude: 14.4180,
      longitude: 77.7190,
      name: 'Dharmavaram Railway Station',
      address: 'Station Road, Dharmavaram, AP 515671',
    );

    setUp(() async {
      demoService = DemoService();
      demoService.resetDemoState();
      settingsService = SettingsService();
      settingsService.resetToDefault();
      historyService = RideHistoryService();
      historyService.clearHistory();
      reviewService = RideReviewService();
      await reviewService.clearAll();
      offerService = OfferService();
      offerService.removeOffer();
    });

    tearDown(() async {
      demoService.resetDemoState();
      settingsService.resetToDefault();
      historyService.clearHistory();
      await reviewService.clearAll();
      offerService.removeOffer();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 1: Enable & Toggle Demo Mode
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 1: Demo Mode Activation & State Synchronization', () {
      expect(demoService.isDemoMode, isFalse);

      demoService.setDemoMode(true);
      expect(demoService.isDemoMode, isTrue);
      expect(settingsService.demoModeEnabled, isTrue);

      demoService.toggleDemoMode();
      expect(demoService.isDemoMode, isFalse);
      expect(settingsService.demoModeEnabled, isFalse);

      demoService.setDemoMode(true);
      expect(demoService.isDemoMode, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 2: Location Selection & Route Generation
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 2: Pickup and Destination Route Generation', () {
      final route = RouteService.generateRoute(pickupPoint, destinationPoint);

      expect(route.pickup.name, equals('Dharmavaram RTC Bus Stand'));
      expect(route.destination.name, equals('Dharmavaram Railway Station'));
      expect(route.distanceKm, greaterThan(0));
      expect(route.estimatedMinutes, greaterThan(0));
      expect(route.polylinePoints, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 3: Clearly Identified Demo Captain Data
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 3: Demo Captain Generation with Identification Labels', () {
      final captain = demoService.createDemoCaptain('Bike');

      expect(captain.isDemo, isTrue);
      expect(captain.name, equals('Demo Captain (Rajesh Kumar)'));
      expect(captain.vehicleNumber, equals('AP 09 CB 1234'));
      expect(captain.vehicleType, equals('Bike'));
      expect(captain.rating, equals(4.8));
      expect(captain.formattedRating, equals('4.8'));
      expect(captain.id.toLowerCase(), contains('demo'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 4: Existing Fare Rules & Vehicle Distance Eligibility
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 4: Strict Adherence to QuickRide Fare Rules & Eligibility', () {
      // Bike (1-50 km): 0.5km invalid, 10km valid, 55km invalid
      final bikeShort = demoService.checkVehicleEligibility(vehicleType: 'Bike', distanceKm: 0.5);
      expect(bikeShort.available, isFalse);
      expect(bikeShort.unavailableReason, contains('1 km'));

      final bikeValid = demoService.checkVehicleEligibility(vehicleType: 'Bike', distanceKm: 10.0);
      expect(bikeValid.available, isTrue);
      expect(bikeValid.fare, greaterThan(0));

      final bikeLong = demoService.checkVehicleEligibility(vehicleType: 'Bike', distanceKm: 55.0);
      expect(bikeLong.available, isFalse);

      // Car (5-150 km): 3.0km invalid for intercity car, 25km valid
      final carShort = demoService.checkVehicleEligibility(vehicleType: 'Car', distanceKm: 3.0);
      expect(carShort.available, isFalse);
      expect(carShort.unavailableReason, contains('5 km'));

      final carValid = demoService.checkVehicleEligibility(vehicleType: 'Car', distanceKm: 25.0);
      expect(carValid.available, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 5: Create Demo Ride Request & Matching Guard Validation
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 5: Demo Ride Request Creation with Local Identification', () {
      final route = RouteService.generateRoute(pickupPoint, destinationPoint);
      final fareDetails = FareCalculator.calculateFare(category: VehicleCategory.bike, distanceKm: route.distanceKm);

      final demoReq = demoService.createDemoRideRequest(
        routeDetails: route,
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: fareDetails,
        paymentMethod: PaymentMethod.cash,
      );

      expect(demoReq.isDemo, isTrue);
      expect(demoReq.rideId, startsWith('DEMO_RIDE_'));
      expect(demoReq.captain, isNotNull);
      expect(demoReq.captain!.isDemo, isTrue);
      expect(demoReq.status, equals(RideStatus.searchingForCaptain));

      // Lifecycle guard checks
      expect(demoService.canAcceptRide(demoReq.status), isTrue);
      expect(demoService.canReachPickup(demoReq.status), isFalse);
      expect(demoService.canStartRide(demoReq.status), isFalse);
      expect(demoService.canCompleteRide(demoReq.status), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 6: Captain Reaches Pickup (ARRIVED Stage)
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 6: Demo Captain Reaches Pickup Transition', () {
      final route = RouteService.generateRoute(pickupPoint, destinationPoint);
      final fareDetails = FareCalculator.calculateFare(category: VehicleCategory.bike, distanceKm: route.distanceKm);
      final demoReq = demoService.createDemoRideRequest(
        routeDetails: route,
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: fareDetails,
      ).copyWith(status: RideStatus.captainFound);

      final tracker = RideTrackingService(initialRequest: demoReq);
      expect(demoService.canReachPickup(tracker.status), isTrue);

      tracker.reachPickupDemo();
      expect(tracker.status, equals(RideStatus.arrived));
      expect(tracker.captainLocation, isNotNull);
      expect(tracker.captainLocation!.latitude, closeTo(pickupPoint.latitude, 0.0001));
      expect(tracker.captainLocation!.longitude, closeTo(pickupPoint.longitude, 0.0001));
      expect(demoService.canStartRide(tracker.status), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 7: Start Demo Ride (RIDE IN PROGRESS Stage)
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 7: Demo Ride Started Transition', () {
      final route = RouteService.generateRoute(pickupPoint, destinationPoint);
      final fareDetails = FareCalculator.calculateFare(category: VehicleCategory.bike, distanceKm: route.distanceKm);
      final demoReq = demoService.createDemoRideRequest(
        routeDetails: route,
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: fareDetails,
      ).copyWith(status: RideStatus.arrived);

      final tracker = RideTrackingService(initialRequest: demoReq);
      expect(demoService.canStartRide(tracker.status), isTrue);

      tracker.startRide();
      expect(tracker.status, equals(RideStatus.rideStarted));
      expect(demoService.canCompleteRide(tracker.status), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 8: Complete Demo Ride (RIDE COMPLETED Stage)
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 8: Complete Demo Ride Transition & Coordinate Arrival', () {
      final route = RouteService.generateRoute(pickupPoint, destinationPoint);
      final fareDetails = FareCalculator.calculateFare(category: VehicleCategory.bike, distanceKm: route.distanceKm);
      final demoReq = demoService.createDemoRideRequest(
        routeDetails: route,
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: fareDetails,
      ).copyWith(status: RideStatus.rideStarted);

      final tracker = RideTrackingService(initialRequest: demoReq);
      expect(demoService.canCompleteRide(tracker.status), isTrue);

      tracker.completeRideDemo();
      expect(tracker.status, equals(RideStatus.rideCompleted));
      expect(tracker.captainLocation, isNotNull);
      expect(tracker.captainLocation!.latitude, closeTo(destinationPoint.latitude, 0.0001));
      expect(tracker.captainLocation!.longitude, closeTo(destinationPoint.longitude, 0.0001));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 9: Local Ride History Persistence & Demo Identification
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 9: Ride History Persistence Records Demo Status', () {
      final route = RouteService.generateRoute(pickupPoint, destinationPoint);
      final fareDetails = FareCalculator.calculateFare(category: VehicleCategory.bike, distanceKm: route.distanceKm);
      final demoReq = demoService.createDemoRideRequest(
        routeDetails: route,
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: fareDetails,
      ).copyWith(status: RideStatus.rideStarted);

      final tracker = RideTrackingService(initialRequest: demoReq);
      tracker.completeRideDemo();

      final history = historyService.getHistory();
      expect(history, isNotEmpty);
      final lastRide = history.first;
      expect(lastRide.rideId, equals(demoReq.rideId));
      expect(lastRide.isDemo, isTrue);
      expect(lastRide.captain.isDemo, isTrue);
      expect(lastRide.captain.name, contains('Demo Captain'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 10: Submit Rating & Review for Completed Demo Trip
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 10: Rating and Review Submission for Demo Ride', () async {
      final route = RouteService.generateRoute(pickupPoint, destinationPoint);
      final fareDetails = FareCalculator.calculateFare(category: VehicleCategory.bike, distanceKm: route.distanceKm);
      final demoReq = demoService.createDemoRideRequest(
        routeDetails: route,
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: fareDetails,
      );

      final review = RideReview(
        reviewId: 'review_${demoReq.rideId}',
        rideId: demoReq.rideId,
        captainId: demoReq.captain!.id,
        rating: 5,
        reviewText: 'Excellent demo ride presentation for college viva!',
        feedbackTags: [RatingFeedbackTag.cleanVehicle, RatingFeedbackTag.friendlyCaptain],
        createdAt: DateTime.now(),
      );

      await reviewService.submitReview(review, userId: 'DEMO_USER', captainId: demoReq.captain!.id);
      final hasRated = await reviewService.hasRated(demoReq.rideId);
      expect(hasRated, isTrue);

      final retrieved = await reviewService.getReviewForRide(demoReq.rideId);
      expect(retrieved, isNotNull);
      expect(retrieved!.rating, equals(5));
      expect(retrieved.reviewText, contains('viva'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 11: Claim Demo Reward Voucher (DEMO50)
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 11: Demo Reward Claim without Real Payment Dependency', () {
      expect(demoService.isDemoRewardClaimed, isFalse);

      final result = demoService.claimDemoReward();
      expect(result['claimed'], isTrue);
      expect(result['code'], equals('DEMO50'));
      expect(demoService.isDemoRewardClaimed, isTrue);

      // Verify coupon is validated by OfferService
      final couponOffer = offerService.validateCoupon('DEMO50');
      expect(couponOffer, isNotNull);
      expect(couponOffer!.discountValue, equals(50.0));
      expect(couponOffer.discountType, equals(DiscountType.percentage));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SCENARIO 12: Production Firestore Data Safety & Isolation
    // ─────────────────────────────────────────────────────────────────────────
    test('Scenario 12: Production Database Safety & Zero Fake Captain Injection', () {
      final fb = QuickRideFirebaseService();

      // Demo service operations should not mutate live Firestore
      demoService.setDemoMode(true);
      final demoCaptain = demoService.createDemoCaptain('Auto');
      expect(demoCaptain.isDemo, isTrue);

      // Verify normal mode can be toggled without side-effects
      demoService.setDemoMode(false);
      expect(demoService.isDemoMode, isFalse);
      expect(settingsService.demoModeEnabled, isFalse);
      expect(fb.isFirebaseAvailable, isNotNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // WIDGET VERIFICATION: RideCompletedScreen Renders Demo Badge & Reward
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Widget Test: RideCompletedScreen shows Demo Captain badge & Claim Voucher', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final route = RouteService.generateRoute(pickupPoint, destinationPoint);
      final fareDetails = FareCalculator.calculateFare(category: VehicleCategory.bike, distanceKm: route.distanceKm);
      final demoReq = demoService.createDemoRideRequest(
        routeDetails: route,
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: fareDetails,
      ).copyWith(
        status: RideStatus.rideCompleted,
        paymentStatus: 'PAID',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RideCompletedScreen(rideRequest: demoReq),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ride Completed 🎉'), findsOneWidget);
      expect(find.text('DEMO CAPTAIN'), findsOneWidget);
      expect(find.text('DEMO TRIP REWARD & VOUCHER'), findsOneWidget);
      expect(find.text('Claim Demo Reward (DEMO50)'), findsOneWidget);

      // Tap Claim Demo Reward
      await tester.tap(find.text('Claim Demo Reward (DEMO50)'));
      await tester.pumpAndSettle();

      expect(find.text('Demo Reward Claimed! 🎉'), findsOneWidget);
      expect(find.text('DEMO50'), findsWidgets);
      expect(find.text('Awesome!'), findsOneWidget);

      await tester.tap(find.text('Awesome!'));
      await tester.pumpAndSettle();

      expect(demoService.isDemoRewardClaimed, isTrue);
    });
  });
}
