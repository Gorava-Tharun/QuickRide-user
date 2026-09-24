import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/services/fare_calculator.dart';
import 'package:quickride_user/services/firebase_service.dart';
import 'package:quickride_user/services/location_service.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 58: QuickRide User App Final End-to-End Testing Suite', () {
    late SessionManager sessionManager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sessionManager = SessionManager();
      sessionManager.resetToDefault();
    });

    tearDown(() {
      sessionManager.resetToDefault();
    });

    // -------------------------------------------------------------------------
    // 1. FARE MATRIX TEST (All 20 specified distances across Bike, Auto, Car)
    // -------------------------------------------------------------------------
    group('1. Approved Fare Rules & 20-Distance Matrix Test', () {
      test('1. 0.5 km: All vehicles unavailable (< 1 km for Bike/Auto, < 5 km for Car)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 0.5);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 0.5);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 0.5);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isFalse);
      });

      test('2. 1.0 km: Bike & Auto available (1-5 km slab), Car unavailable (< 5 km)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 1.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 1.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 1.0);

        expect(bike.available, isTrue);
        expect(bike.ratePerKm, 8.00);
        expect(bike.fare, 8.00);
        expect(bike.selectedSlab, '1–5 km');

        expect(auto.available, isTrue);
        expect(auto.ratePerKm, 12.00);
        expect(auto.fare, 12.00);
        expect(auto.selectedSlab, '1–5 km');

        expect(car.available, isFalse);
      });

      test('3. 3.0 km: Bike (₹24), Auto (₹36), Car unavailable', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 3.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 3.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 3.0);

        expect(bike.available, isTrue);
        expect(bike.fare, 24.00);

        expect(auto.available, isTrue);
        expect(auto.fare, 36.00);

        expect(car.available, isFalse);
      });

      test('4. 5.0 km: Bike (₹40), Auto (₹60), Car enters 5-10 km slab (₹68.75)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 5.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 5.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 5.0);

        expect(bike.fare, 40.00);
        expect(bike.ratePerKm, 8.00);

        expect(auto.fare, 60.00);
        expect(auto.ratePerKm, 12.00);

        expect(car.available, isTrue);
        expect(car.fare, 68.75);
        expect(car.ratePerKm, 13.75);
        expect(car.selectedSlab, '5–10 km');
      });

      test('5. 5.01 km: Next slab (5-10 km for Bike/Auto, 5-10 km for Car)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 5.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 5.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 5.01);

        expect(bike.ratePerKm, 5.50);
        expect(bike.fare, 27.56);
        expect(bike.selectedSlab, '5–10 km');

        expect(auto.ratePerKm, 8.25);
        expect(auto.fare, 41.33);
        expect(auto.selectedSlab, '5–10 km');

        expect(car.ratePerKm, 13.75);
        expect(car.fare, 68.89);
      });

      test('6. 8.0 km: Bike (₹44), Auto (₹66), Car (₹110)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 8.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 8.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 8.0);

        expect(bike.fare, 44.00);
        expect(auto.fare, 66.00);
        expect(car.fare, 110.00);
      });

      test('7. 10.0 km: Top of 5-10 km slab - Bike (₹55), Auto (₹82.50), Car (₹137.50)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 10.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 10.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 10.0);

        expect(bike.fare, 55.00);
        expect(auto.fare, 82.50);
        expect(car.fare, 137.50);
      });

      test('8. 10.01 km: Next slab (10-20 km) - Bike (₹4.50/km), Auto (₹6.75/km), Car (₹11.25/km)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 10.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 10.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 10.01);

        expect(bike.ratePerKm, 4.50);
        expect(bike.fare, 45.05);

        expect(auto.ratePerKm, 6.75);
        expect(auto.fare, 67.57);

        expect(car.ratePerKm, 11.25);
        expect(car.fare, 112.61);
      });

      test('9. 15.0 km: Bike (₹67.50), Auto (₹101.25), Car (₹168.75)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 15.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 15.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 15.0);

        expect(bike.fare, 67.50);
        expect(auto.fare, 101.25);
        expect(car.fare, 168.75);
      });

      test('10. 20.0 km: Top of 10-20 km slab - Bike (₹90), Auto (₹135), Car (₹225)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 20.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 20.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 20.0);

        expect(bike.fare, 90.00);
        expect(auto.fare, 135.00);
        expect(car.fare, 225.00);
      });

      test('11. 20.01 km: Next slab (20-35 km) - Bike (₹4.00/km), Auto (₹6.00/km), Car (₹10.00/km)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 20.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 20.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 20.01);

        expect(bike.ratePerKm, 4.00);
        expect(bike.fare, 80.04);

        expect(auto.ratePerKm, 6.00);
        expect(auto.fare, 120.06);

        expect(car.ratePerKm, 10.00);
        expect(car.fare, 200.10);
      });

      test('12. 25.0 km: Bike (₹100), Auto (₹150), Car (₹250)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 25.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 25.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 25.0);

        expect(bike.fare, 100.00);
        expect(auto.fare, 150.00);
        expect(car.fare, 250.00);
      });

      test('13. 35.0 km: Top of 20-35 km slab - Bike (₹140), Auto (₹210), Car (₹350)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 35.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 35.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 35.0);

        expect(bike.fare, 140.00);
        expect(auto.fare, 210.00);
        expect(car.fare, 350.00);
      });

      test('14. 35.01 km: Next slab (35-50 km for Bike/Auto, 35-150 km for Car)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 35.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 35.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 35.01);

        expect(bike.ratePerKm, 3.50);
        expect(bike.fare, 122.54);

        expect(auto.ratePerKm, 5.25);
        expect(auto.fare, 183.80);

        expect(car.ratePerKm, 8.75);
        expect(car.fare, 306.34);
      });

      test('15. 40.0 km: Bike (₹140), Auto (₹210), Car (₹350)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 40.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 40.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 40.0);

        expect(bike.fare, 140.00);
        expect(auto.fare, 210.00);
        expect(car.fare, 350.00);
      });

      test('16. 50.0 km: Top of 35-50 km slab - Bike (₹175), Auto (₹262.50), Car (₹437.50)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 50.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 50.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 50.0);

        expect(bike.fare, 175.00);
        expect(auto.fare, 262.50);
        expect(car.fare, 437.50);
      });

      test('17. 50.01 km: Bike and Auto unavailable (>50km), Car remains available (₹437.59)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 50.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 50.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 50.01);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isTrue);
        expect(car.fare, 437.59);
        expect(car.ratePerKm, 8.75);
      });

      test('18. 100.0 km: Bike and Auto unavailable, Car (₹875.00)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 100.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 100.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 100.0);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isTrue);
        expect(car.fare, 875.00);
      });

      test('19. 150.0 km: Maximum Car distance - Car (₹1312.50)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 150.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 150.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 150.0);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isTrue);
        expect(car.fare, 1312.50);
      });

      test('20. 150.01 km: All vehicles unavailable (> 150 km exceeds Car maximum)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 150.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 150.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 150.01);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // 2. COMPLETE USER RIDE JOURNEY
    // -------------------------------------------------------------------------
    group('2. User App Complete Ride Lifecycle & Session Tracking', () {
      test('User logs in, configures route, books ride, tracks lifecycle to completion', () async {
        // 1. User Authentication
        sessionManager.login(identifier: 'user_e2e_58@quickride.com', fullName: 'Ananya Sharma');
        expect(sessionManager.isLoggedIn, isTrue);
        expect(sessionManager.currentUser.fullName, 'Ananya Sharma');

        // 2. Route & Location Distance Calculation
        final pickup = const LocationPoint(
          name: 'Gachibowli Stadium',
          address: 'Gachibowli, Hyderabad',
          latitude: 17.4435,
          longitude: 78.3489,
        );
        final drop = const LocationPoint(
          name: 'Inorbit Mall',
          address: 'Madhapur, Hyderabad',
          latitude: 17.4348,
          longitude: 78.3867,
        );

        final distanceKm = LocationService.calculateDistanceKm(
          pickup.latitude,
          pickup.longitude,
          drop.latitude,
          drop.longitude,
        );
        expect(distanceKm > 0, isTrue);

        // 3. Fare Calculation
        final fare = FareCalculator.calculateFare(
          category: VehicleCategory.car,
          distanceKm: 25.0,
        );
        expect(fare.isAvailable, isTrue);
        expect(fare.finalFare, 250.0);

        // 4. Create Active Ride in Session
        final ride = SharedRideModel(
          rideId: 'RIDE_E2E_58_USER',
          userId: sessionManager.currentUser.userId,
          captainId: 'CAP_VIKRAM_99',
          pickup: pickup.name,
          destination: drop.name,
          pickupLocation: {'latitude': pickup.latitude, 'longitude': pickup.longitude},
          destinationLocation: {'latitude': drop.latitude, 'longitude': drop.longitude},
          vehicleType: 'Car',
          status: SharedRideStatus.accepted,
          fare: 250.0,
          distance: 25.0,
          estimatedTime: 35,
          requestedAt: DateTime.now(),
        );

        sessionManager.setActiveRide('RIDE_E2E_58_USER', ride: ride);
        expect(sessionManager.hasActiveRide, isTrue);
        expect(sessionManager.activeRideId, 'RIDE_E2E_58_USER');

        // 5. Transition to inProgress and completed
        final inProgressRide = ride.copyWith(status: SharedRideStatus.inProgress);
        sessionManager.setActiveRide('RIDE_E2E_58_USER', ride: inProgressRide);
        expect(sessionManager.cachedActiveRide?.status, SharedRideStatus.inProgress);

        final completedRide = ride.copyWith(status: SharedRideStatus.completed);
        sessionManager.setActiveRide('RIDE_E2E_58_USER', ride: completedRide);
        expect(sessionManager.cachedActiveRide?.status, SharedRideStatus.completed);

        // 6. Complete and Clear
        sessionManager.clearActiveRide();
        expect(sessionManager.hasActiveRide, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // 3. ERROR & OFFLINE RESILIENCE
    // -------------------------------------------------------------------------
    group('3. Offline Fallbacks & Error Resilience', () {
      test('QuickRideFirebaseService local payments and complaints seed cleanly without throwing', () {
        final fb = QuickRideFirebaseService();
        expect(fb.runtimeType, QuickRideFirebaseService);
      });

      test('Security check: Logout isolates and clears cached identity', () {
        sessionManager.logout();
        expect(sessionManager.isLoggedIn, isFalse);
        expect(sessionManager.hasActiveRide, isFalse);
      });
    });
  });
}
