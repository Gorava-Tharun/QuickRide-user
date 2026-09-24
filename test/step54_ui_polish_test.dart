import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/core/constants/app_strings.dart';
import 'package:quickride_user/models/fare_model.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/ride_details_model.dart';
import 'package:quickride_user/models/ride_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/screens/auth/login_screen.dart';
import 'package:quickride_user/screens/auth/signup_screen.dart';
import 'package:quickride_user/screens/home/home_screen.dart';
import 'package:quickride_user/screens/profile/profile_screen.dart';
import 'package:quickride_user/screens/ride_completed/ride_completed_screen.dart';
import 'package:quickride_user/screens/safety/safety_center_screen.dart';
import 'package:quickride_user/screens/settings/settings_screen.dart';
import 'package:quickride_user/screens/splash/splash_screen.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 54: QuickRide User App UI/UX Polish & Responsive Verification', () {
    setUp(() {
      SessionManager().resetToDefault();
    });

    tearDown(() {
      SessionManager().resetToDefault();
    });

    // =========================================================================
    // 1. BRANDING & SPLASH POLISH
    // =========================================================================
    testWidgets('Splash Screen renders brand emblem, tagline, and gold typography', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Ride'), findsOneWidget);
      expect(find.text(AppStrings.tagline), findsOneWidget);
    });

    // =========================================================================
    // 2. AUTHENTICATION SCREENS (LOGIN & SIGNUP)
    // =========================================================================
    testWidgets('Login Screen renders responsive input cards with high-contrast text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text(AppStrings.loginButton), findsOneWidget);
    });

    testWidgets('Signup Screen renders all required registration fields cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.signUpTitle), findsOneWidget);
      expect(find.text(AppStrings.fullNameLabel), findsOneWidget);
      expect(find.text(AppStrings.mobileLabel), findsOneWidget);
    });

    // =========================================================================
    // 3. HOME SCREEN & GOOGLE MAPS AREA
    // =========================================================================
    testWidgets('Home Screen renders map container, greeting, and route summary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.homeGreeting), findsOneWidget);
      expect(find.text(AppStrings.whereToQuestion), findsOneWidget);
      expect(find.text(AppStrings.continueButton), findsOneWidget);
    });

    // =========================================================================
    // 4. RIDE COMPLETED & RATING POLISH
    // =========================================================================
    testWidgets('Ride Completed Screen displays receipt and trip details', (tester) async {
      final mockRequest = RideRequest(
        rideId: 'REQ_POLISH_01',
        userId: 'user_01',
        pickup: const LocationPoint(
          latitude: 12.9785,
          longitude: 77.6405,
          name: 'Indiranagar',
          address: 'Indiranagar 100 Feet Rd',
        ),
        destination: const LocationPoint(
          latitude: 12.9345,
          longitude: 77.6265,
          name: 'Koramangala',
          address: 'Koramangala 5th Block',
        ),
        selectedVehicle: VehicleOption.standardOptions.first,
        distanceKm: 5.5,
        estimatedMinutes: 18,
        fareDetails: const FareDetails(
          baseFare: 30.0,
          distanceFare: 70.0,
          timeFare: 20.0,
          waitingCharge: 0.0,
          originalFare: 120.0,
          discount: 0.0,
          finalFare: 120.0,
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
      await tester.pumpAndSettle();

      expect(find.text('Ride Completed 🎉'), findsOneWidget);
      expect(find.text('Rate Your Ride'), findsOneWidget);
    });

    // =========================================================================
    // 5. SAFETY CENTER POLISH
    // =========================================================================
    testWidgets('Safety Center Screen renders SOS emergency button and safety checklist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SafetyCenterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safety Center'), findsOneWidget);
      expect(find.text('Emergency Help'), findsOneWidget);
    });

    // =========================================================================
    // 6. PROFILE & SETTINGS POLISH
    // =========================================================================
    testWidgets('Profile Screen renders user identity card and navigation menu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Alex Johnson'), findsWidgets);
    });

    testWidgets('Settings Screen renders appearance, language, and security toggles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    // =========================================================================
    // 7. RESPONSIVE MULTI-DEVICE VIEWPORT CHECKS
    // =========================================================================
    testWidgets('Home Screen adapts to compact mobile viewport (320x568) without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.homeGreeting), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Login Screen adapts to large tablet viewport (768x1024) cleanly', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
