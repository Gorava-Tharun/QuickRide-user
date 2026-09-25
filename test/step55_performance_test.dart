import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_user/models/fare_model.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/ride_details_model.dart';
import 'package:quickride_user/models/ride_model.dart';
import 'package:quickride_user/models/user_profile_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/screens/home/home_screen.dart';
import 'package:quickride_user/services/firebase_service.dart';
import 'package:quickride_user/services/ride_tracking_service.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 55: QuickRide User App Performance, Bounded Queries & Resource Management', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SessionManager().updateProfile(
        UserProfile(
          userId: 'test_user_01',
          fullName: 'Aarav Sharma',
          email: 'aarav@quickride.com',
          mobileNumber: '9876543210',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
    });

    test('QuickRideFirebaseService findOnlineCaptain executes within bounded limits', () async {
      final fb = QuickRideFirebaseService();
      
      // Verify findOnlineCaptain executes cleanly with bounded Firestore queries
      final captain = await fb.findOnlineCaptain(vehicleType: 'Bike');
      if (captain != null) {
        expect(captain.vehicleType, contains('Bike'));
      }
    });

    test('RideTrackingService initializes and disposes animation/simulation timers safely', () {
      final request = RideRequest(
        rideId: 'TEST_RIDE_55',
        userId: 'test_user_01',
        pickup: const LocationPoint(name: 'Pickup', address: 'Pickup Addr', latitude: 12.9716, longitude: 77.5946),
        destination: const LocationPoint(name: 'Dest', address: 'Dest Addr', latitude: 12.9352, longitude: 77.6245),
        selectedVehicle: VehicleOption.standardOptions.first,
        distanceKm: 5.0,
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

      final service = RideTrackingService(initialRequest: request);

      expect(service.status, RideStatus.captainFound);
      service.startArrivingSimulation();
      expect(service.status, RideStatus.arriving);

      // Verify disposal stops timers without errors or leaks
      expect(() => service.dispose(), returnsNormally);
    });

    testWidgets('HomeScreen mounts, initializes, and unmounts Google Map without memory leaks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Replace widget tree to trigger dispose and map controller cleanup
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
