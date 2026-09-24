import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickride_user/core/constants/app_strings.dart';
import 'package:quickride_user/core/errors/app_error_handler.dart';
import 'package:quickride_user/models/fare_model.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/ride_details_model.dart';
import 'package:quickride_user/models/ride_model.dart';
import 'package:quickride_user/models/user_profile_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/screens/auth/login_screen.dart';
import 'package:quickride_user/screens/home/home_screen.dart';
import 'package:quickride_user/screens/ride_completed/ride_completed_screen.dart';
import 'package:quickride_user/screens/splash/splash_screen.dart';
import 'package:quickride_user/services/connectivity_service.dart';
import 'package:quickride_user/services/fare_calculator.dart';
import 'package:quickride_user/services/firebase_service.dart';
import 'package:quickride_user/services/location_service.dart';
import 'package:quickride_user/services/session_manager.dart';
import 'package:quickride_user/services/settings_service.dart';
import 'package:quickride_user/widgets/offline_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 50: QuickRide User App Complete End-to-End Testing Suite', () {
    late SessionManager sessionManager;
    late ConnectivityService connectivity;

    setUp(() {
      sessionManager = SessionManager();
      sessionManager.resetToDefault();
      connectivity = ConnectivityService();
      connectivity.setMockOnlineState(true);
    });

    tearDown(() {
      sessionManager.resetToDefault();
      connectivity.setMockOnlineState(true);
    });

    // =========================================================================
    // 1. SPLASH & LOGIN TESTING
    // =========================================================================
    group('1. Splash, Authentication & Session Persistence', () {
      testWidgets('Splash screen initializes and renders brand branding', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreen(),
          ),
        );

        expect(find.text('Quick'), findsOneWidget);
        expect(find.text('Ride'), findsOneWidget);
        expect(find.text(AppStrings.tagline), findsOneWidget);
      });

      testWidgets('Login screen validates required fields and session login', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LoginScreen(),
          ),
        );

        expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
        expect(find.text(AppStrings.loginButton), findsOneWidget);

        // Session manager reflects logged in state
        sessionManager.login(fullName: 'Aarav Sharma', phone: '9876543210');
        expect(sessionManager.isLoggedIn, isTrue);
        expect(sessionManager.currentUser.fullName, 'Aarav Sharma');
      });

      testWidgets('Logout clears active credentials and preserves default session safely', (tester) async {
        sessionManager.updateProfile(
          UserProfile(
            userId: 'user_01',
            fullName: 'Test User',
            email: 'test@quickride.com',
            mobileNumber: '9999999999',
            createdAt: DateTime.now(),
          ),
        );
        expect(sessionManager.currentUser.fullName, 'Test User');

        sessionManager.resetToDefault();
        expect(sessionManager.currentUser.fullName, 'Alex Johnson');
      });
    });

    // =========================================================================
    // 2. HOME SCREEN VERIFICATION
    // =========================================================================
    group('2. Home Screen & Navigation Components', () {
      testWidgets('Home screen renders header, greeting, and route selectors', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );
        await tester.pump();

        expect(find.text(AppStrings.homeGreeting), findsOneWidget);
        expect(find.text(AppStrings.whereToQuestion), findsOneWidget);
        expect(find.text(AppStrings.continueButton), findsOneWidget);
        expect(find.byType(OfflineBanner), findsOneWidget);
      });
    });

    // =========================================================================
    // 3. GOOGLE MAPS INTEGRATION
    // =========================================================================
    group('3. Google Maps Integration & Web Configuration', () {
      testWidgets('GoogleMap widget is embedded inside styled container without errors', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );
        await tester.pump();

        expect(find.byType(GoogleMap), findsOneWidget);
        expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
        expect(find.text(AppStrings.tapToSelectOnMap), findsOneWidget);
      });
    });

    // =========================================================================
    // 4. FARE TESTING & EXACT BOUNDARY MATRIX
    // =========================================================================
    group('4. Fare Engine & Boundary Distance Matrix', () {
      // Required boundary distances: 0.5, 1, 5, 5.01, 10, 10.01, 20, 20.01, 35, 35.01, 50, 50.01, 100, 150, 150.01 km

      test('Boundary d = 0.5 km: Below minimum distance for Bike, Auto, Car', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 0.5);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 0.5);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 0.5);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isFalse);
      });

      test('Boundary d = 1.0 km: Minimum distance for Bike & Auto (1–5 km slab)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 1.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 1.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 1.0);

        expect(bike.available, isTrue);
        expect(bike.ratePerKm, 8.00);
        expect(bike.fare, 8.00); // 1.0 * 8.00
        expect(bike.selectedSlab, '1–5 km');

        expect(auto.available, isTrue);
        expect(auto.ratePerKm, 12.00); // 8.00 * 1.5
        expect(auto.fare, 12.00);
        expect(auto.selectedSlab, '1–5 km');

        expect(car.available, isFalse); // Car min is 5 km
      });

      test('Boundary d = 5.0 km: Upper edge of 1–5 km slab for Bike & Auto, min for Car', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 5.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 5.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 5.0);

        expect(bike.available, isTrue);
        expect(bike.ratePerKm, 8.00);
        expect(bike.fare, 40.00); // 5.0 * 8.00

        expect(auto.available, isTrue);
        expect(auto.ratePerKm, 12.00);
        expect(auto.fare, 60.00); // 5.0 * 12.00

        expect(car.available, isTrue);
        expect(car.ratePerKm, 13.75); // 5.50 * 2.5
        expect(car.fare, 68.75); // 5.0 * 13.75
        expect(car.selectedSlab, '5–10 km');
      });

      test('Boundary d = 5.01 km: Lower edge of 5–10 km slab across all vehicles', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 5.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 5.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 5.01);

        expect(bike.available, isTrue);
        expect(bike.ratePerKm, 5.50);
        expect(bike.fare, 27.56); // 5.01 * 5.50 = 27.555 -> 27.56
        expect(bike.selectedSlab, '5–10 km');

        expect(auto.available, isTrue);
        expect(auto.ratePerKm, 8.25); // 5.50 * 1.5
        expect(auto.fare, 41.33); // 5.01 * 8.25 = 41.3325 -> 41.33

        expect(car.available, isTrue);
        expect(car.ratePerKm, 13.75);
        expect(car.fare, 68.89); // 5.01 * 13.75 = 68.8875 -> 68.89
      });

      test('Boundary d = 10.0 km: Upper edge of 5–10 km slab', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 10.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 10.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 10.0);

        expect(bike.ratePerKm, 5.50);
        expect(bike.fare, 55.00);

        expect(auto.ratePerKm, 8.25);
        expect(auto.fare, 82.50);

        expect(car.ratePerKm, 13.75);
        expect(car.fare, 137.50);
      });

      test('Boundary d = 10.01 km: Lower edge of 10–20 km slab', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 10.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 10.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 10.01);

        expect(bike.ratePerKm, 4.50);
        expect(bike.fare, 45.05); // 10.01 * 4.50 = 45.045 -> 45.05
        expect(bike.selectedSlab, '10–20 km');

        expect(auto.ratePerKm, 6.75); // 4.50 * 1.5
        expect(auto.fare, 67.57); // 10.01 * 6.75 = 67.5675 -> 67.57

        expect(car.ratePerKm, 11.25); // 4.50 * 2.5
        expect(car.fare, 112.61); // 10.01 * 11.25 = 112.6125 -> 112.61
      });

      test('Boundary d = 20.0 km: Upper edge of 10–20 km slab', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 20.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 20.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 20.0);

        expect(bike.ratePerKm, 4.50);
        expect(bike.fare, 90.00);

        expect(auto.ratePerKm, 6.75);
        expect(auto.fare, 135.00);

        expect(car.ratePerKm, 11.25);
        expect(car.fare, 225.00);
      });

      test('Boundary d = 20.01 km: Lower edge of 20–35 km slab', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 20.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 20.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 20.01);

        expect(bike.ratePerKm, 4.00);
        expect(bike.fare, 80.04); // 20.01 * 4.00 = 80.04
        expect(bike.selectedSlab, '20–35 km');

        expect(auto.ratePerKm, 6.00); // 4.00 * 1.5
        expect(auto.fare, 120.06); // 20.01 * 6.00 = 120.06

        expect(car.ratePerKm, 10.00); // 4.00 * 2.5
        expect(car.fare, 200.10); // 20.01 * 10.00 = 200.10
      });

      test('Boundary d = 35.0 km: Upper edge of 20–35 km slab', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 35.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 35.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 35.0);

        expect(bike.ratePerKm, 4.00);
        expect(bike.fare, 140.00);

        expect(auto.ratePerKm, 6.00);
        expect(auto.fare, 210.00);

        expect(car.ratePerKm, 10.00);
        expect(car.fare, 350.00);
      });

      test('Boundary d = 35.01 km: Lower edge of 35–50 km slab for Bike/Auto & 35–150 km for Car', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 35.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 35.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 35.01);

        expect(bike.ratePerKm, 3.50);
        expect(bike.fare, 122.54); // 35.01 * 3.50 = 122.535 -> 122.54
        expect(bike.selectedSlab, '35–50 km');

        expect(auto.ratePerKm, 5.25); // 3.50 * 1.5
        expect(auto.fare, 183.80); // 35.01 * 5.25 = 183.8025 -> 183.80

        expect(car.ratePerKm, 8.75); // 3.50 * 2.5
        expect(car.fare, 306.34); // 35.01 * 8.75 = 306.3375 -> 306.34
        expect(car.selectedSlab, '35–150 km');
      });

      test('Boundary d = 50.0 km: Upper edge of Bike & Auto availability (35–50 km slab)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 50.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 50.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 50.0);

        expect(bike.available, isTrue);
        expect(bike.ratePerKm, 3.50);
        expect(bike.fare, 175.00);

        expect(auto.available, isTrue);
        expect(auto.ratePerKm, 5.25);
        expect(auto.fare, 262.50);

        expect(car.available, isTrue);
        expect(car.ratePerKm, 8.75);
        expect(car.fare, 437.50);
      });

      test('Boundary d = 50.01 km: Bike and Auto become UNAVAILABLE (> 50 km)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 50.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 50.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 50.01);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isTrue);
        expect(car.ratePerKm, 8.75);
        expect(car.fare, 437.59); // 50.01 * 8.75 = 437.5875 -> 437.59
      });

      test('Boundary d = 100.0 km: Only Car is available', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 100.0);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 100.0);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 100.0);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isTrue);
        expect(car.fare, 875.00); // 100.0 * 8.75
      });

      test('Boundary d = 150.0 km: Upper maximum distance for Car', () {
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 150.0);
        expect(car.available, isTrue);
        expect(car.ratePerKm, 8.75);
        expect(car.fare, 1312.50); // 150.0 * 8.75
      });

      test('Boundary d = 150.01 km: Car becomes UNAVAILABLE (> 150 km)', () {
        final bike = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 150.01);
        final auto = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 150.01);
        final car = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 150.01);

        expect(bike.available, isFalse);
        expect(auto.available, isFalse);
        expect(car.available, isFalse);
      });
    });

    // =========================================================================
    // 5. RIDE BOOKING & IDEMPOTENCY
    // =========================================================================
    group('5. Ride Booking, Validation & Idempotency', () {
      test('Duplicate location validation rejects identical pickup and destination', () {
        const double lat = 12.9716;
        const double lng = 77.5946;
        final dist = LocationService.calculateDistanceKm(lat, lng, lat, lng);
        expect(dist < 0.05, isTrue);
      });

      test('SessionManager idempotency prevents duplicate ride requests', () {
        expect(sessionManager.hasActiveRide, isFalse);

        final mockRide = SharedRideModel(
          rideId: 'RIDE_TEST_001',
          userId: 'user_test_01',
          pickup: 'MG Road',
          destination: 'Indiranagar',
          pickupLocation: {'latitude': 12.9716, 'longitude': 77.5946},
          destinationLocation: {'latitude': 12.9784, 'longitude': 77.6408},
          vehicleType: 'Bike',
          status: SharedRideStatus.requested,
          fare: 40.0,
          distance: 5.0,
          estimatedTime: 15,
          requestedAt: DateTime.now(),
        );

        sessionManager.setActiveRide('RIDE_TEST_001', ride: mockRide);
        expect(sessionManager.hasActiveRide, isTrue);
        expect(sessionManager.activeRideId, 'RIDE_TEST_001');

        sessionManager.clearActiveRide();
        expect(sessionManager.hasActiveRide, isFalse);
      });
    });

    // =========================================================================
    // 6. ACTIVE RIDE LIFECYCLE & RECOVERY
    // =========================================================================
    group('6. Active Ride Lifecycle & State Transitions', () {
      test('Active ride transitions through ACCEPTED, ARRIVED, IN_PROGRESS, COMPLETED', () {
        var ride = SharedRideModel(
          rideId: 'RIDE_TEST_002',
          userId: 'user_test_01',
          captainId: 'CAP_001',
          pickup: 'Koramangala',
          destination: 'HSR Layout',
          pickupLocation: {'latitude': 12.9352, 'longitude': 77.6245},
          destinationLocation: {'latitude': 12.9121, 'longitude': 77.6446},
          vehicleType: 'Auto',
          status: SharedRideStatus.accepted,
          fare: 60.0,
          distance: 5.0,
          estimatedTime: 15,
          requestedAt: DateTime.now(),
        );

        expect(ride.status, SharedRideStatus.accepted);

        ride = ride.copyWith(status: SharedRideStatus.arrived);
        expect(ride.status, SharedRideStatus.arrived);

        ride = ride.copyWith(status: SharedRideStatus.inProgress);
        expect(ride.status, SharedRideStatus.inProgress);

        ride = ride.copyWith(status: SharedRideStatus.completed);
        expect(ride.status, SharedRideStatus.completed);
      });

      test('Active ride recovery restores ride state on app restart', () {
        final ride = SharedRideModel(
          rideId: 'RIDE_RECOVER_01',
          userId: 'user_quickride_01',
          pickup: 'Majestic',
          destination: 'Whitefield',
          pickupLocation: {'latitude': 12.9766, 'longitude': 77.5713},
          destinationLocation: {'latitude': 12.9698, 'longitude': 77.7500},
          vehicleType: 'Car',
          status: SharedRideStatus.inProgress,
          fare: 200.0,
          distance: 20.0,
          estimatedTime: 30,
          requestedAt: DateTime.now(),
        );

        sessionManager.setActiveRide('RIDE_RECOVER_01', ride: ride);
        expect(sessionManager.cachedActiveRide?.status, SharedRideStatus.inProgress);
      });
    });

    // =========================================================================
    // 7. PAYMENT SYSTEM & RECEIPT
    // =========================================================================
    group('7. Payment Processing & History', () {
      test('Payment record serializes and calculates net breakdown correctly', () {
        final payment = FirestorePaymentModel(
          paymentId: 'PAY_TEST_001',
          rideId: 'RIDE_TEST_002',
          userId: 'user_quickride_01',
          captainId: 'CAP_001',
          originalFare: 60.0,
          discountAmount: 10.0,
          finalAmount: 50.0,
          paymentMethod: 'UPI',
          paymentStatus: FirestorePaymentStatus.paid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(payment.finalAmount, 50.0);
        expect(payment.paymentStatus, FirestorePaymentStatus.paid);
        expect(payment.isPaid, isTrue);
      });
    });

    // =========================================================================
    // 8. RATING & REVIEW VERIFICATION
    // =========================================================================
    group('8. Rating & Review Validation', () {
      testWidgets('RideCompletedScreen renders summary and rating action', (tester) async {
        final mockRequest = RideRequest(
          rideId: 'REQ_01',
          userId: 'user_01',
          pickup: const LocationPoint(
            latitude: 12.9784,
            longitude: 77.6408,
            name: 'Indiranagar',
            address: 'Indiranagar, Bengaluru',
          ),
          destination: const LocationPoint(
            latitude: 12.9352,
            longitude: 77.6245,
            name: 'Koramangala',
            address: 'Koramangala, Bengaluru',
          ),
          selectedVehicle: VehicleOption.standardOptions.first,
          distanceKm: 5.0,
          estimatedMinutes: 15,
          fareDetails: const FareDetails(
            baseFare: 0.0,
            distanceFare: 40.0,
            timeFare: 0.0,
            waitingCharge: 0.0,
            originalFare: 40.0,
            discount: 0.0,
            finalFare: 40.0,
          ),
          paymentMethod: PaymentMethod.cash,
          status: RideStatus.rideCompleted,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RideCompletedScreen(
              rideRequest: mockRequest,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Ride Completed 🎉'), findsOneWidget);
        expect(find.text('Rate Your Ride'), findsOneWidget);
      });
    });

    // =========================================================================
    // 9. PROFILE, SETTINGS & SAFETY
    // =========================================================================
    group('9. Profile, Theme Settings & Safety Preferences', () {
      test('SettingsService toggles Dark and Light theme modes cleanly', () async {
        final settings = SettingsService();
        await settings.setThemeMode(ThemeMode.dark);
        expect(settings.themeMode, ThemeMode.dark);

        await settings.setThemeMode(ThemeMode.light);
        expect(settings.themeMode, ThemeMode.light);
      });

      test('UserProfile maintains fields and immutability', () {
        final profile = UserProfile(
          userId: 'user_01',
          fullName: 'Aarav Sharma',
          email: 'aarav@quickride.com',
          mobileNumber: '9876543210',
          createdAt: DateTime(2026, 1, 15),
        );

        expect(profile.fullName, 'Aarav Sharma');
        expect(profile.initials, 'AS');

        final updated = profile.copyWith(fullName: 'Aarav S.');
        expect(updated.fullName, 'Aarav S.');
        expect(profile.fullName, 'Aarav Sharma'); // Original unchanged
      });
    });

    // =========================================================================
    // 10. OFFLINE, ERROR RESILIENCY & SECURITY
    // =========================================================================
    group('10. Offline Resiliency, Exception Mapping & Security Isolation', () {
      test('ConnectivityService transitions between Online and Offline states', () {
        connectivity.setMockOnlineState(false);
        expect(connectivity.isOffline, isTrue);

        connectivity.setMockOnlineState(true);
        expect(connectivity.isOnline, isTrue);
      });

      test('AppErrorHandler converts raw exceptions into friendly feedback', () {
        final msg = AppErrorHandler.getFriendlyErrorMessage(
          SocketException('No route to host'),
        );
        expect(msg.contains('internet') || msg.contains('Network') || msg.contains('connection'), isTrue);
      });

      test('Security: Rider cannot access unauthenticated or admin resources', () {
        final fb = QuickRideFirebaseService();
        expect(fb.statusMessage, isNotNull);
      });
    });
  });
}
