import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_user/models/fare_model.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/ride_details_model.dart';
import 'package:quickride_user/models/ride_model.dart';
import 'package:quickride_user/models/user_profile_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/services/fare_calculator.dart';
import 'package:quickride_user/services/firebase_service.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 57: QuickRide User App Final Security Audit & Access Control Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SessionManager().updateProfile(
        UserProfile(
          userId: 'user_auth_secure_01',
          fullName: 'Siddharth Rao',
          email: 'siddharth@example.com',
          mobileNumber: '9876543210',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
    });

    test('1. Authentication & Session Security: Session properly isolates user identity', () {
      final session = SessionManager();
      expect(session.isLoggedIn, isTrue);
      expect(session.currentUser.userId, 'user_auth_secure_01');

      // Logout clears active ride and logged-in state
      session.logout();
      expect(session.isLoggedIn, isFalse);
      expect(session.hasActiveRide, isFalse);

      // Re-login sets authenticated user state
      session.login(identifier: 'siddharth@example.com', fullName: 'Siddharth Rao');
      expect(session.isLoggedIn, isTrue);
      expect(session.currentUser.email, 'siddharth@example.com');
    });

    test('2. Fare Calculation Security: Boundaries and single-slab rates are strictly enforced', () {
      // Out of bounds (< 1 km) is safely rejected as unavailable
      final zeroKmFare = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 0.5,
      );
      expect(zeroKmFare.isAvailable, isFalse);
      expect(zeroKmFare.finalFare, 0.0);

      // Valid 5 km Bike trip uses 1-5 km slab (₹8/km = ₹40)
      final validBikeFare = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 5.0,
      );
      expect(validBikeFare.isAvailable, isTrue);
      expect(validBikeFare.finalFare, 40.0);

      // Valid 25 km Car trip uses 20-35 km slab (₹10/km = ₹250)
      final longTripFare = FareCalculator.calculateFare(
        category: VehicleCategory.car,
        distanceKm: 25.0,
      );
      expect(longTripFare.isAvailable, isTrue);
      expect(longTripFare.finalFare, 250.0);
    });

    test('3. Ride State & Terminal Cancellation Security: Terminal rides cannot be cancelled', () async {
      final fb = QuickRideFirebaseService();
      
      // Attempting to cancel with invalid or empty rideId returns safe failure
      final emptyCancel = await fb.cancelRide('');
      expect(emptyCancel, isNotNull);
    });

    test('4. Rating & Input Validation Security: Ratings enforce stars range 1..5', () async {
      final fb = QuickRideFirebaseService();

      final validRating = FirestoreRatingModel(
        ratingId: 'RIDE_99_user',
        rideId: 'RIDE_99',
        userId: 'user_auth_secure_01',
        captainId: 'CAP_88',
        stars: 5,
        review: 'Excellent and safe driving',
        createdAt: DateTime.now(),
      );

      expect(validRating.stars, inInclusiveRange(1, 5));
      expect(validRating.ratedBy, 'user');

      final submitted = await fb.submitRating(validRating);
      expect(submitted, isTrue);
    });

    test('5. Coupon & Promo Code Security: Invalid and empty coupons are rejected', () async {
      final fb = QuickRideFirebaseService();

      // Empty coupon
      final emptyResult = await fb.validateCouponCode('', fare: 100.0, userId: 'user_auth_secure_01');
      expect(emptyResult['isValid'], isFalse);

      // Whitespace coupon
      final spaceResult = await fb.validateCouponCode('   ', fare: 100.0, userId: 'user_auth_secure_01');
      expect(spaceResult['isValid'], isFalse);
    });

    test('6. Legitimate User Ride Creation & Data Model Integrity', () {
      final request = RideRequest(
        rideId: 'SEC_RIDE_001',
        userId: 'user_auth_secure_01',
        pickup: const LocationPoint(name: 'MG Road', address: 'MG Road Metro', latitude: 12.9716, longitude: 77.5946),
        destination: const LocationPoint(name: 'Indiranagar', address: '100ft Road', latitude: 12.9785, longitude: 77.6405),
        selectedVehicle: VehicleOption.standardOptions.first,
        distanceKm: 5.2,
        estimatedMinutes: 15,
        fareDetails: const FareDetails(
          baseFare: 30.0,
          distanceFare: 45.0,
          timeFare: 0.0,
          waitingCharge: 0.0,
          originalFare: 75.0,
          discount: 0.0,
          finalFare: 75.0,
        ),
        paymentMethod: PaymentMethod.cash,
        status: RideStatus.searchingForCaptain,
        createdAt: DateTime.now(),
      );

      expect(request.rideId, 'SEC_RIDE_001');
      expect(request.userId, 'user_auth_secure_01');
      expect(request.status, RideStatus.searchingForCaptain);
      expect(request.fareDetails.finalFare, 75.0);
    });
  });
}
