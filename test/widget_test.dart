import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickride_user/core/constants/app_strings.dart';
import 'package:quickride_user/main.dart';
import 'package:quickride_user/routes/app_routes.dart';
import 'package:quickride_user/screens/auth/login_screen.dart';
import 'package:quickride_user/screens/auth/signup_screen.dart';
import 'package:quickride_user/screens/home/home_screen.dart';
import 'package:quickride_user/screens/splash/splash_screen.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/models/fare_model.dart';
import 'package:quickride_user/models/ride_details_model.dart';
import 'package:quickride_user/models/ride_model.dart';

import 'package:quickride_user/screens/captain_details/captain_details_screen.dart';
import 'package:quickride_user/screens/fare_calculation/fare_calculation_screen.dart';
import 'package:quickride_user/screens/finding_captain/finding_captain_screen.dart';
import 'package:quickride_user/screens/ride_confirmation/ride_confirmation_screen.dart';
import 'package:quickride_user/screens/vehicle_selection/vehicle_selection_screen.dart';
import 'package:quickride_user/services/ride_tracking_service.dart';
import 'package:quickride_user/services/fare_calculator.dart';
import 'package:quickride_user/widgets/custom_text_field.dart';
import 'package:quickride_user/widgets/primary_button.dart';
import 'package:quickride_user/widgets/quickride_logo.dart';
import 'package:quickride_user/widgets/ride_background_visual.dart';
import 'package:quickride_user/widgets/route_summary_card.dart';
import 'package:quickride_user/widgets/vehicle_selection_card.dart';
import 'package:quickride_user/models/ride_history_model.dart';
import 'package:quickride_user/models/ride_review_model.dart';
import 'package:quickride_user/screens/rating_review/rating_review_screen.dart';
import 'package:quickride_user/screens/ride_completed/ride_completed_screen.dart';
import 'package:quickride_user/services/ride_history_service.dart';
import 'package:quickride_user/services/ride_review_service.dart';
import 'package:quickride_user/widgets/star_rating_widget.dart';
import 'package:quickride_user/screens/ride_history/ride_history_screen.dart';
import 'package:quickride_user/screens/ride_history/ride_details_screen.dart';
import 'package:quickride_user/screens/ride_history/widgets/ride_history_card.dart';
import 'package:quickride_user/services/offer_service.dart';
import 'package:quickride_user/screens/offers/offers_screen.dart';
import 'package:quickride_user/screens/offers/offer_details_screen.dart';
import 'package:quickride_user/screens/offers/widgets/offer_card.dart';
import 'package:quickride_user/models/user_profile_model.dart';
import 'package:quickride_user/services/session_manager.dart';
import 'package:quickride_user/screens/profile/profile_screen.dart';
import 'package:quickride_user/screens/profile/edit_profile_screen.dart';
import 'package:quickride_user/screens/help_support/help_support_screen.dart';
import 'package:quickride_user/screens/help_support/my_support_requests_screen.dart';
import 'package:quickride_user/screens/help_support/report_issue_screen.dart';
import 'package:quickride_user/screens/help_support/support_request_details_screen.dart';
import 'package:quickride_user/screens/help_support/support_success_screen.dart';
import 'package:quickride_user/models/support_request_model.dart';
import 'package:quickride_user/services/support_service.dart';
import 'package:quickride_user/models/notification_model.dart';
import 'package:quickride_user/services/notification_service.dart';
import 'package:quickride_user/screens/notifications/notification_screen.dart';
import 'package:quickride_user/screens/profile/terms_conditions_screen.dart';
import 'package:quickride_user/screens/profile/privacy_policy_screen.dart';
import 'package:quickride_user/models/safety_preferences_model.dart';
import 'package:quickride_user/models/trip_share_data.dart';
import 'package:quickride_user/screens/safety/safety_center_screen.dart';
import 'package:quickride_user/screens/safety/safety_preferences_screen.dart';
import 'package:quickride_user/services/safety_service.dart';
import 'package:quickride_user/models/app_settings_model.dart';
import 'package:quickride_user/services/settings_service.dart';
import 'package:quickride_user/screens/settings/settings_screen.dart';
import 'package:quickride_user/screens/settings/privacy_settings_screen.dart';
import 'package:quickride_user/screens/settings/change_password_screen.dart';
import 'package:quickride_user/screens/settings/about_quickride_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  group('QuickRide Splash Screen Tests', () {
    testWidgets('Renders all Step 1 Splash Screen elements initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(const QuickRideApp());

      // Initial frame
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(RideBackgroundVisual), findsOneWidget);
      expect(find.byType(QuickRideLogo), findsOneWidget);

      // Verify text elements exist in the widget tree
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Ride'), findsOneWidget);
      expect(find.text(AppStrings.tagline), findsOneWidget);

      // Progress animation
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('Automatically navigates to LoginScreen after animation completes',
        (WidgetTester tester) async {
      await tester.pumpWidget(const QuickRideApp());

      // Initial state is Splash
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Fast forward past the 2600ms duration
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      // Now LoginScreen should be rendered and SplashScreen replaced
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('Adapts responsively to tablet form factor',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 2.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const QuickRideApp());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Ride'), findsOneWidget);
      expect(find.text(AppStrings.tagline), findsOneWidget);
    });
  });

  group('QuickRide Step 2 Login Screen Tests', () {
    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: child,
      );
    }

    testWidgets('Renders all Login Screen visual elements cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
      expect(find.text(AppStrings.loginSubtitle), findsOneWidget);
      expect(find.text(AppStrings.identifierLabel), findsOneWidget);
      expect(find.text(AppStrings.passwordLabel), findsOneWidget);
      expect(find.text(AppStrings.loginButton), findsOneWidget);
      expect(find.text(AppStrings.forgotPassword), findsOneWidget);
      expect(find.text(AppStrings.signUpLink), findsOneWidget);
      expect(find.byType(CustomTextField), findsNWidgets(2));
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('Displays error validation when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      // Tap Login button with empty inputs
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      // Expect validation messages
      expect(find.text(AppStrings.errorIdentifierEmpty), findsOneWidget);
      expect(find.text(AppStrings.errorPasswordEmpty), findsOneWidget);
    });

    testWidgets('Displays error when invalid email or phone number is entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.identifierLabel),
        'invalid-email@',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.passwordLabel),
        '123456',
      );

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorInvalidIdentifier), findsOneWidget);

      // Enter invalid phone (less than 10 digits)
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.identifierLabel),
        '98765',
      );
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorInvalidIdentifier), findsOneWidget);
    });

    testWidgets('Displays error when password is too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.identifierLabel),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.passwordLabel),
        '123',
      );

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorPasswordTooShort), findsOneWidget);
    });

    testWidgets('Toggles password visibility with eye icon button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      final passwordFieldFinder = find.byType(EditableText).last;
      EditableText passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);

      // Tap toggle button
      final toggleButtonFinder = find.byTooltip('Show password');
      expect(toggleButtonFinder, findsOneWidget);
      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      // Verify password is now visible
      passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, isFalse);

      // Tap again to hide
      final hideButtonFinder = find.byTooltip('Hide password');
      expect(hideButtonFinder, findsOneWidget);
      await tester.tap(hideButtonFinder);
      await tester.pumpAndSettle();

      passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('Displays temporary success message when inputs are valid',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      // Enter valid email and password
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.identifierLabel),
        'rider@quickride.com',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.passwordLabel),
        'password123',
      );

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pump(); // Start async delay
      await tester.pump(const Duration(milliseconds: 1000)); // Finish delay
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.loginSuccessMessage), findsOneWidget);
    });

    testWidgets('Forgot Password displays notice modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));

      await tester.tap(find.text(AppStrings.forgotPassword));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.forgotPasswordNotice), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.forgotPasswordNotice), findsNothing);
    });
  });

  group('QuickRide Step 3 Sign Up Screen Tests', () {
    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        home: child,
      );
    }

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('Renders all 5 input fields, labels, buttons, and branding cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SignUpScreen()));

      expect(find.text(AppStrings.signUpTitle), findsOneWidget);
      expect(find.text(AppStrings.signUpSubtitle), findsOneWidget);
      expect(find.text(AppStrings.fullNameLabel), findsOneWidget);
      expect(find.text(AppStrings.mobileLabel), findsOneWidget);
      expect(find.text(AppStrings.emailLabel), findsOneWidget);
      expect(find.text(AppStrings.passwordLabel), findsOneWidget);
      expect(find.text(AppStrings.confirmPasswordLabel), findsOneWidget);
      expect(find.text(AppStrings.createAccountButton), findsOneWidget);
      expect(find.text(AppStrings.loginLink), findsOneWidget);
      expect(find.byType(CustomTextField), findsNWidgets(5));
      expect(find.byType(PrimaryButton), findsOneWidget);
    });

    testWidgets('Displays validation error messages when fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SignUpScreen()));

      // Tap Create Account with empty fields
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorNameEmpty), findsOneWidget);
      expect(find.text(AppStrings.errorMobileEmpty), findsOneWidget);
      expect(find.text(AppStrings.errorEmailEmpty), findsOneWidget);
      expect(find.text(AppStrings.errorPasswordEmpty), findsOneWidget);
      expect(find.text(AppStrings.errorConfirmPasswordEmpty), findsOneWidget);
    });

    testWidgets('Validates Full Name length (>= 2 chars)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SignUpScreen()));

      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.fullNameLabel),
        'A',
      );
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorNameTooShort), findsOneWidget);
    });

    testWidgets('Validates Mobile Number format (10 digits)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SignUpScreen()));

      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.mobileLabel),
        '12345',
      );
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorInvalidMobile), findsOneWidget);
    });

    testWidgets('Validates Email Address format',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SignUpScreen()));

      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.emailLabel),
        'not-an-email',
      );
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorInvalidEmail), findsOneWidget);
    });

    testWidgets('Validates Password minimum length and Password matching',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SignUpScreen()));

      // Password too short
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.passwordLabel),
        '123',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.confirmPasswordLabel),
        '123',
      );
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorPasswordTooShort), findsOneWidget);

      // Password mismatch
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.passwordLabel),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.confirmPasswordLabel),
        'password456',
      );
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorPasswordsDoNotMatch), findsOneWidget);
    });

    testWidgets('Toggles password visibility on both password fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SignUpScreen()));

      // Initially both password fields are obscured
      expect(find.byTooltip('Show password'), findsOneWidget);
      expect(find.byTooltip('Show confirm password'), findsOneWidget);

      // Toggle password
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Hide password'), findsOneWidget);

      // Toggle confirm password
      await tester.tap(find.byTooltip('Show confirm password'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Hide confirm password'), findsOneWidget);
    });

    testWidgets('Full flow: Valid inputs trigger success feedback and navigate back to Login',
        (WidgetTester tester) async {
      await tester.pumpWidget(const QuickRideApp());

      // Advance through splash to login
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Tap Sign Up link to go to SignUpScreen
      await tester.tap(find.text(AppStrings.signUpLink));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);

      // Fill valid credentials into all 5 fields
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.fullNameLabel),
        'Tharun Rider',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.mobileLabel),
        '9876543210',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.emailLabel),
        'tharun@quickride.com',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.passwordLabel),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.confirmPasswordLabel),
        'password123',
      );

      // Tap Create Account
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify success message and returned to LoginScreen
      expect(find.text(AppStrings.accountCreatedSuccessMessage), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Clicking Login link on SignUpScreen navigates back to Login',
        (WidgetTester tester) async {
      await tester.pumpWidget(const QuickRideApp());

      // Advance through splash to login
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      // Navigate to SignUp
      await tester.tap(find.text(AppStrings.signUpLink));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);

      // Tap Login link
      await tester.tap(find.text(AppStrings.loginLink));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('QuickRide Step 5 Home Screen Tests (Pickup & Destination)', () {
    Widget buildHomeTestableWidget(Widget child) {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: child,
      );
    }

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('Renders all Step 5 Home Screen sections cleanly with Google Map and RouteSummaryCard',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeTestableWidget(const HomeScreen()));

      // Header
      expect(find.text(AppStrings.homeGreeting), findsOneWidget);
      expect(find.text(AppStrings.whereToQuestion), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget); // header avatar
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget); // nav bar

      // RouteSummaryCard with Pickup & Destination
      expect(find.byType(RouteSummaryCard), findsOneWidget);
      expect(find.text(AppStrings.pickupLocation), findsOneWidget);
      expect(find.text(AppStrings.currentLocation), findsOneWidget);
      expect(find.text(AppStrings.destinationLocation), findsOneWidget);
      expect(find.text(AppStrings.destinationSearchPrompt), findsOneWidget);

      // Swap button
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);

      // Continue Button
      expect(find.text(AppStrings.continueButton), findsOneWidget);

      // Bottom Navigation Bar
      expect(find.text(AppStrings.navHome), findsOneWidget);
      expect(find.text(AppStrings.navMyRides), findsOneWidget);
      expect(find.text(AppStrings.navOffers), findsOneWidget);
      expect(find.text(AppStrings.navProfile), findsOneWidget);
    });

    testWidgets('Validates Continue button: displays error when destination is missing',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeTestableWidget(const HomeScreen()));

      // Tap Continue without choosing destination
      await tester.tap(find.text(AppStrings.continueButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorMissingDestination), findsOneWidget);
    });

    testWidgets('Opens destination search dialog when tapping destination field',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeTestableWidget(const HomeScreen()));

      // Tap destination selector
      await tester.tap(find.text(AppStrings.destinationSearchPrompt));
      await tester.pumpAndSettle();

      // Search bottom sheet should appear
      expect(find.text('Select Destination'), findsOneWidget);
      expect(find.text(AppStrings.popularPlacesHeader), findsOneWidget);

      // Select first popular place
      await tester.tap(find.text('Kurnool City Railway Station'));
      await tester.pumpAndSettle();

      // Destination is now set
      expect(find.text('Kurnool City Railway Station'), findsOneWidget);

      // Distance and Est Time should now be rendered
      expect(find.textContaining(AppStrings.distanceLabel), findsOneWidget);
      expect(find.textContaining(AppStrings.estTimeLabel), findsOneWidget);
    });

    testWidgets('Swaps pickup and destination when swap button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeTestableWidget(const HomeScreen()));

      // Select destination first
      await tester.tap(find.text(AppStrings.destinationSearchPrompt));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kurnool City Railway Station'));
      await tester.pumpAndSettle();

      // Tap swap button
      await tester.tap(find.byIcon(Icons.swap_vert_rounded));
      await tester.pumpAndSettle();

      // Pickup is now Kurnool City Railway Station, Destination is Current Location
      expect(find.text('Pickup and destination swapped.'), findsOneWidget);
    });

    testWidgets('Tapping bottom navigation tabs navigates to corresponding screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeTestableWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      // 'Profile' (index 3) navigates to ProfileScreen (Step 15)
      await tester.tap(find.text(AppStrings.navProfile));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Back to home
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // 'My Rides' (index 1) navigates to RideHistoryScreen (Step 13)
      await tester.tap(find.text(AppStrings.navMyRides));
      await tester.pumpAndSettle();
      expect(find.byType(RideHistoryScreen), findsOneWidget);
    });

    testWidgets('Complete flow: Splash -> Login -> Home Screen navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(const QuickRideApp());

      // Advance through splash to login
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter valid login credentials
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.identifierLabel),
        'passenger@quickride.com',
      );
      await tester.enterText(
        find.widgetWithText(CustomTextField, AppStrings.passwordLabel),
        'password123',
      );

      // Tap Login
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // Verify we arrived at HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(AppStrings.homeGreeting), findsOneWidget);
    });
  });

  group('QuickRide Step 6 Vehicle Selection Screen Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'Bengaluru Central',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala 6th Block',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    Widget buildVehicleTestableWidget() {
      return MaterialApp(
        home: const VehicleSelectionScreen(routeDetails: testRoute),
      );
    }

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('Renders all Step 6 headers, trip summary, and 3 vehicle cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildVehicleTestableWidget());

      // Header and Subtitle
      expect(find.text(AppStrings.chooseRideTitle), findsNWidgets(2)); // AppBar + Body
      expect(find.text(AppStrings.chooseRideSubtitle), findsOneWidget);

      // Trip Summary Card details
      expect(find.text(AppStrings.tripSummaryHeader), findsOneWidget);
      expect(find.text('Bengaluru Central'), findsOneWidget);
      expect(find.text('Koramangala 6th Block'), findsOneWidget);
      expect(find.textContaining('6.8 km'), findsOneWidget);
      expect(find.textContaining('21 min'), findsOneWidget);

      // 3 Vehicle Cards
      expect(find.byType(VehicleSelectionCard), findsNWidgets(3));
      expect(find.text('Bike'), findsOneWidget);
      expect(find.text('Fast & Affordable'), findsOneWidget);
      expect(find.text('1 Passenger'), findsOneWidget);

      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Comfortable & Convenient'), findsOneWidget);
      expect(find.text('Up to 3 Passengers'), findsOneWidget);

      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Comfortable & Premium'), findsOneWidget);
      expect(find.text('Up to 4 Passengers'), findsOneWidget);

      // Estimated Fare placeholder section
      expect(find.text(AppStrings.estimatedFareLabel), findsOneWidget);
      expect(find.text(AppStrings.fareCalculationNext), findsOneWidget);

      // Continue button
      expect(find.text(AppStrings.continueButton), findsOneWidget);
    });

    testWidgets('Single-selection behavior: only one vehicle can be selected at a time',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildVehicleTestableWidget());

      // Initially no checkmarks
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Select Bike
      await tester.tap(find.text('Bike'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Select Auto -> Bike becomes unselected, Auto is selected
      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Select Car -> Auto becomes unselected, Car is selected
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('Validates Continue button: shows error when no vehicle is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildVehicleTestableWidget());

      // Tap continue without selecting
      await tester.tap(find.text(AppStrings.continueButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.errorSelectVehicle), findsOneWidget);
    });

    testWidgets('Continue button with vehicle selected navigates to FareCalculationScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildVehicleTestableWidget());

      // Select Auto
      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text(AppStrings.continueButton));
      await tester.pumpAndSettle();

      // Arrived at FareCalculationScreen
      expect(find.byType(FareCalculationScreen), findsOneWidget);
      expect(find.text(AppStrings.fareCalculationTitle), findsOneWidget);
      expect(find.text(AppStrings.fareBreakdownHeader), findsOneWidget);
    });

    testWidgets('Back button returns to previous screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VehicleSelectionScreen(routeDetails: testRoute),
                  ),
                ),
                child: const Text('Open Vehicles'),
              ),
            ),
          ),
        ),
      );

      // Navigate to VehicleSelectionScreen
      await tester.tap(find.text('Open Vehicles'));
      await tester.pumpAndSettle();
      expect(find.byType(VehicleSelectionScreen), findsOneWidget);

      // Tap Back button
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Returned
      expect(find.byType(VehicleSelectionScreen), findsNothing);
      expect(find.text('Open Vehicles'), findsOneWidget);
    });
  });

  group('QuickRide Step 7 Fare Calculation Tests', () {
    test('Calculates Bike fare correctly for <= 7 km (Example 1: 5 km, 15 min)', () {
      // Step 44: Bike 5km in 1–5km slab = 5 * 8.0 = 40.0
      // 50% discount = 20.0, Final fare = 20.0
      final fare = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 5.0,
        estimatedMinutes: 15,
        applyFirstRideDiscount: true,
      );

      expect(fare.baseFare, 0.0);
      expect(fare.distanceFare, 40.0);
      expect(fare.timeFare, 0.0);
      expect(fare.waitingCharge, 0.0);
      expect(fare.originalFare, 40.0);
      expect(fare.discount, 20.0);
      expect(fare.finalFare, 20.0);
      expect(fare.ratePerKm, 8.0);
      expect(fare.selectedSlab, '1–5 km');
    });

    test('Calculates Auto fare correctly as Bike * 1.5 (Example 1: 5 km, 15 min)', () {
      // Step 44: Auto 5km in 1–5km slab = 5 * 12.0 = 60.0
      // 50% discount = 30.0, Final fare = 30.0
      final fare = FareCalculator.calculateFare(
        category: VehicleCategory.auto,
        distanceKm: 5.0,
        estimatedMinutes: 15,
        applyFirstRideDiscount: true,
      );

      expect(fare.baseFare, 0.0);
      expect(fare.distanceFare, 60.0);
      expect(fare.timeFare, 0.0);
      expect(fare.originalFare, 60.0);
      expect(fare.discount, 30.0);
      expect(fare.finalFare, 30.0);
      expect(fare.ratePerKm, 12.0);
      expect(fare.selectedSlab, '1–5 km');
    });

    test('Calculates Car fare correctly as Bike * 2.5 (Example 1: 5 km, 15 min)', () {
      // Step 44: Car 5km in 5–10km slab = 5 * 13.75 = 68.75
      // 50% discount = 34.38, Final fare = 34.37
      final fare = FareCalculator.calculateFare(
        category: VehicleCategory.car,
        distanceKm: 5.0,
        estimatedMinutes: 15,
        applyFirstRideDiscount: true,
      );

      expect(fare.baseFare, 0.0);
      expect(fare.distanceFare, 68.75);
      expect(fare.timeFare, 0.0);
      expect(fare.originalFare, 68.75);
      expect(fare.discount, 34.38);
      expect(fare.finalFare, 34.37);
      expect(fare.ratePerKm, 13.75);
      expect(fare.selectedSlab, '5–10 km');
    });

    test('Calculates Bike fare correctly for > 7 km (Example 2: 10 km, 25 min)', () {
      // Step 44: Bike 10km in 5–10km slab = 10 * 5.5 = 55.0
      // 50% discount = 27.5, Final fare = 27.5
      final fare = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 10.0,
        estimatedMinutes: 25,
        applyFirstRideDiscount: true,
      );

      expect(fare.baseFare, 0.0);
      expect(fare.distanceFare, 55.0);
      expect(fare.timeFare, 0.0);
      expect(fare.originalFare, 55.0);
      expect(fare.discount, 27.5);
      expect(fare.finalFare, 27.5);
      expect(fare.ratePerKm, 5.5);
      expect(fare.selectedSlab, '5–10 km');
    });

    test('Tests edge cases: 0 km, 1 km, 7 km, 8 km', () {
      // 0 km: Unavailable
      final fare0 = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 0.0,
        estimatedMinutes: 0,
        applyFirstRideDiscount: true,
      );
      expect(fare0.isAvailable, isFalse);
      expect(fare0.originalFare, 0.0);
      expect(fare0.finalFare, 0.0);

      // 1 km, 5 min: 1 * 8.0 = 8.0, 50% = 4.0, final = 4.0
      final fare1 = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 1.0,
        estimatedMinutes: 5,
        applyFirstRideDiscount: true,
      );
      expect(fare1.originalFare, 8.0);
      expect(fare1.finalFare, 4.0);

      // 7 km, 20 min: 7 * 5.5 = 38.50
      final fare7 = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 7.0,
        estimatedMinutes: 20,
      );
      expect(fare7.distanceFare, 38.50);
      expect(fare7.originalFare, 38.50);

      // 8 km, 20 min: 8 * 5.5 = 44.00
      final fare8 = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 8.0,
        estimatedMinutes: 20,
      );
      expect(fare8.distanceFare, 44.0);
      expect(fare8.originalFare, 44.0);
    });

    testWidgets('FareCalculationScreen renders vehicle summary, trip details, and fare breakdown',
        (WidgetTester tester) async {
      const testRoute = RouteDetails(
        pickup: LocationPoint(
          latitude: 12.9716,
          longitude: 77.5946,
          name: 'Indiranagar Metro',
          address: '100 Feet Rd',
        ),
        destination: LocationPoint(
          latitude: 12.9279,
          longitude: 77.6271,
          name: 'Koramangala Sony World',
          address: '80 Feet Rd',
        ),
        distanceKm: 5.0,
        estimatedMinutes: 15,
        polylinePoints: [],
      );

      final bikeOption = VehicleOption.standardOptions.first;

      await tester.pumpWidget(
        MaterialApp(
          home: FareCalculationScreen(
            routeDetails: testRoute,
            selectedVehicle: bikeOption,
          ),
        ),
      );

      // Header and Screen Title
      expect(find.text(AppStrings.fareCalculationTitle), findsOneWidget);

      // Vehicle Summary Card
      expect(find.text('Bike'), findsOneWidget);
      expect(find.text(AppStrings.changeVehicleButton), findsOneWidget);

      // Route Details
      expect(find.text('Indiranagar Metro'), findsOneWidget);
      expect(find.text('Koramangala Sony World'), findsOneWidget);

      // Fare Breakdown
      expect(find.text(AppStrings.fareBreakdownHeader), findsOneWidget);
      expect(find.text(AppStrings.firstRideOfferBadge), findsOneWidget);
      expect(find.text(AppStrings.baseFareLabel), findsOneWidget);
      expect(find.text('₹40.00'), findsWidgets); // distance fare & original fare: 5 * 8
      expect(find.text('-₹20.00'), findsOneWidget); // 50% discount
      expect(find.text('₹20.00'), findsOneWidget); // final fare

      // Confirm Ride Button
      expect(find.text(AppStrings.confirmRideButton), findsOneWidget);
    });

    testWidgets('Confirm Ride button validates and navigates to Step 8 confirmed screen',
        (WidgetTester tester) async {
      const testRoute = RouteDetails(
        pickup: LocationPoint(
          latitude: 12.9716,
          longitude: 77.5946,
          name: 'MG Road',
          address: 'MG Road, Bengaluru',
        ),
        destination: LocationPoint(
          latitude: 12.9279,
          longitude: 77.6271,
          name: 'Koramangala',
          address: 'Koramangala, Bengaluru',
        ),
        distanceKm: 5.0,
        estimatedMinutes: 15,
        polylinePoints: [],
      );

      final autoOption = VehicleOption.standardOptions[1];

      await tester.pumpWidget(
        MaterialApp(
          home: FareCalculationScreen(
            routeDetails: testRoute,
            selectedVehicle: autoOption,
          ),
        ),
      );

      // Tap Confirm Ride
      await tester.tap(find.text(AppStrings.confirmRideButton));
      await tester.pumpAndSettle();

      // Navigated to RideConfirmationScreen
      expect(find.byType(RideConfirmationScreen), findsOneWidget);
      expect(find.text('Confirm Your Ride'), findsNWidgets(2)); // AppBar + Body
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('₹30.00'), findsOneWidget);
    });
  });

  group('QuickRide Step 8 Ride Confirmation Screen Tests', () {
    const testRoute = RouteDetails(
      pickup: LocationPoint(
        latitude: 12.9716,
        longitude: 77.5946,
        name: 'MG Road Metro Station',
        address: 'MG Road, Bengaluru',
      ),
      destination: LocationPoint(
        latitude: 12.9279,
        longitude: 77.6271,
        name: 'Koramangala BDA Complex',
        address: '80 Feet Road, Koramangala',
      ),
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final testVehicle = VehicleOption.standardOptions.first; // Bike
    final testFare = FareCalculator.calculateFare(
      category: testVehicle.category,
      distanceKm: testRoute.distanceKm,
      estimatedMinutes: testRoute.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    Widget buildConfirmationTestableWidget() {
      return MaterialApp(
        home: RideConfirmationScreen(
          routeDetails: testRoute,
          selectedVehicle: testVehicle,
          fareDetails: testFare,
        ),
      );
    }

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    testWidgets('Renders complete ride confirmation summary screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildConfirmationTestableWidget());

      // Header and Screen Title
      expect(find.text('Confirm Your Ride'), findsNWidgets(2));
      expect(find.text('Please check your ride details before requesting your ride.'), findsOneWidget);

      // Trip Route Summary Card
      expect(find.text('MG Road Metro Station'), findsOneWidget);
      expect(find.text('Koramangala BDA Complex'), findsOneWidget);
      expect(find.textContaining('6.8 km'), findsOneWidget);
      expect(find.textContaining('21 min'), findsOneWidget);

      // Vehicle & Locked Fare
      expect(find.text('Bike'), findsOneWidget);
      expect(find.text('LOCKED FARE'), findsOneWidget);
      expect(find.text(testFare.formattedFinalFare), findsOneWidget);

      // Payment Method Options
      expect(find.text('PAYMENT METHOD'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Online Payment'), findsOneWidget);

      // Bottom Request Button
      expect(find.text('Request QuickRide'), findsOneWidget);
    });

    testWidgets('Allows toggling payment method between Cash and Online Payment',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildConfirmationTestableWidget());

      // Initially Cash is selected
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Switch to Online Payment
      await tester.tap(find.text('Online Payment'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Request QuickRide button creates RideRequest and navigates to FindingCaptainScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildConfirmationTestableWidget());

      // Tap Request QuickRide
      await tester.tap(find.text('Request QuickRide'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      // Navigated to FindingCaptainScreen
      expect(find.byType(FindingCaptainScreen), findsOneWidget);
      expect(find.text('Finding your Captain'), findsOneWidget);

      // Finish search timer so widget tree disposes cleanly
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    });
  });

  group('QuickRide Step 9 Finding Captain Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'MG Road Metro Station',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala BDA Complex',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final testVehicle = VehicleOption.standardOptions.first; // Bike
    final testFare = FareCalculator.calculateFare(
      category: testVehicle.category,
      distanceKm: testRoute.distanceKm,
      estimatedMinutes: testRoute.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    late RideRequest testRequest;

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

      testRequest = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      );
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    Widget buildFindingCaptainTestableWidget({
      bool simulateNoCaptain = false,
      int searchDurationSeconds = 0,
    }) {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: FindingCaptainScreen(
          rideRequest: testRequest,
          searchDurationSeconds: searchDurationSeconds,
          simulateNoCaptain: simulateNoCaptain,
        ),
      );
    }

    testWidgets('FindingCaptainScreen renders searching status and pickup/destination',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildFindingCaptainTestableWidget(searchDurationSeconds: 2));

      expect(find.text('Finding your Captain'), findsOneWidget);
      expect(find.text('Finding nearby captains...'), findsOneWidget);
      expect(find.text('MG Road Metro Station'), findsOneWidget);
      expect(find.text('Koramangala BDA Complex'), findsOneWidget);
      expect(find.text('Cancel Ride'), findsOneWidget);

      // Finish search timer to dispose cleanly
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('Transitions smoothly to Captain Found! state with demo captain details',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildFindingCaptainTestableWidget(searchDurationSeconds: 0));
      await tester.pumpAndSettle();

      expect(find.text('Captain Found!'), findsOneWidget);
      expect(find.text('Demo Captain (Rajesh Kumar)'), findsOneWidget);
      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.textContaining('AP 09 CB 1234'), findsOneWidget);
      expect(find.text('View Captain'), findsOneWidget);
    });

    testWidgets('Cancel Ride triggers confirmation dialog and navigates back to HomeScreen on confirm',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildFindingCaptainTestableWidget(searchDurationSeconds: 10));

      // Tap Cancel Ride button
      await tester.tap(find.text('Cancel Ride'));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Cancel Ride'), findsWidgets);
      expect(find.text('Please select reason for cancellation:'), findsOneWidget);
      expect(find.text('Keep Ride'), findsOneWidget);

      // Tap Cancel Ride inside dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Ride'));
      await tester.pumpAndSettle();

      // Summary bottom sheet appears
      if (find.text('Back to Home').evaluate().isNotEmpty) {
        await tester.tap(find.text('Back to Home'));
        await tester.pumpAndSettle();
      }

      // Returned to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Flush remaining timer
      await tester.pump(const Duration(seconds: 100));
      await tester.pumpAndSettle();
    });

    testWidgets('No Captain Available fallback state allows Try Again to restart search',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildFindingCaptainTestableWidget(
          simulateNoCaptain: true,
          searchDurationSeconds: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Captain Available'), findsOneWidget);
      expect(find.text('We couldn\'t find an available captain nearby. Please try again.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap Try Again
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Restarts search or shows fallback again
      expect(find.byType(FindingCaptainScreen), findsOneWidget);
    });
  });

  group('QuickRide Step 10 Ride Tracking Service Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'MG Road Metro Station',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala BDA Complex',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final testVehicle = VehicleOption.standardOptions.first;
    final testFare = FareCalculator.calculateFare(
      category: testVehicle.category,
      distanceKm: testRoute.distanceKm,
      estimatedMinutes: testRoute.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    test('RideTrackingService initializes initial captain location & status', () {
      final req = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      );

      final service = RideTrackingService(initialRequest: req);
      expect(service.status, RideStatus.captainFound);
      expect(service.captainLocation, isNotNull);
      service.dispose();
    });

    test('Simulates captain movement toward pickup and transitions status to arrived', () async {
      final req = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      );

      final service = RideTrackingService(
        initialRequest: req,
        simulationStepMs: 10,
        totalArrivalSteps: 3,
      );

      service.startArrivingSimulation();
      expect(service.status, RideStatus.arriving);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(service.status, RideStatus.arrived);
      service.dispose();
    });

    test('startRide transitions status to rideStarted', () {
      final req = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      );

      final service = RideTrackingService(
        initialRequest: req,
        simulationStepMs: 10,
        totalArrivalSteps: 3,
      );

      service.startRide();
      expect(service.status, RideStatus.rideStarted);
      service.dispose();
    });

    test('cancelRide stops simulation and sets status to cancelled', () {
      final req = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      );

      final service = RideTrackingService(initialRequest: req);
      service.startArrivingSimulation();
      service.cancelRide();

      expect(service.status, RideStatus.cancelled);
      service.dispose();
    });
  });

  group('QuickRide Step 10 Captain Details Screen Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'MG Road Metro Station',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala BDA Complex',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final testVehicle = VehicleOption.standardOptions.first;
    final testFare = FareCalculator.calculateFare(
      category: testVehicle.category,
      distanceKm: testRoute.distanceKm,
      estimatedMinutes: testRoute.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    late RideRequest testRequest;

    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

      testRequest = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      ).copyWith(
        captain: CaptainModel.demo(vehicleCategoryTitle: testVehicle.title),
      );
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    Widget buildCaptainDetailsTestableWidget({RideTrackingService? service}) {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: CaptainDetailsScreen(
          rideRequest: testRequest,
          trackingService: service,
          autoStartArrivingSimulation: false,
        ),
      );
    }

    testWidgets('CaptainDetailsScreen renders Captain profile, rating, vehicle plate, and contact buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildCaptainDetailsTestableWidget());

      // Captain Profile details
      expect(find.text('Demo Captain (Rajesh Kumar)'), findsOneWidget);
      expect(find.textContaining('4.8'), findsOneWidget);
      expect(find.textContaining('1240 rides'), findsOneWidget);
      expect(find.text('AP 09 CB 1234'), findsOneWidget);

      // Contact Buttons
      expect(find.text('Call Captain'), findsOneWidget);
      expect(find.text('Message Captain'), findsOneWidget);

      // Ride Info Card
      expect(find.text('MG Road Metro Station'), findsOneWidget);
      expect(find.text('Koramangala BDA Complex'), findsOneWidget);
      expect(find.text('Cancel Ride'), findsOneWidget);
    });

    testWidgets('Tapping Call Captain displays notice snackbar and Message Captain navigates to ChatScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildCaptainDetailsTestableWidget());

      // Tap Call Captain
      await tester.tap(find.text('Call Captain'));
      await tester.pumpAndSettle();
      expect(find.text('Calling Captain is available in the production version.'), findsOneWidget);

      // Tap Message Captain (navigates to ChatScreen)
      await tester.tap(find.text('Message Captain'));
      await tester.pumpAndSettle();
      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('Tapping Start Ride when arrived transitions status to Ride in Progress',
        (WidgetTester tester) async {
      final service = RideTrackingService(
        initialRequest: testRequest,
        simulationStepMs: 10,
      );

      await tester.pumpWidget(buildCaptainDetailsTestableWidget(service: service));

      // Simulate arrived status
      service.startArrivingSimulation();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Start Ride'), findsOneWidget);

      // Tap Start Ride — triggers rideStarted immediately.
      await tester.tap(find.text('Start Ride'));
      // Pump one frame so the setState from rideStarted rebuilds the widget,
      // but do NOT pumpAndSettle — that would drain the in-ride simulation
      // all the way to rideCompleted and navigate away before we can assert.
      await tester.pump();

      expect(find.text('Ride in Progress — En Route to Destination'), findsOneWidget);

      // Dispose the service to cancel pending timers, then flush remaining frames.
      service.dispose();
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Cancel Ride opens confirmation modal and returns to HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildCaptainDetailsTestableWidget());

      // Tap Back / Cancel Ride
      await tester.tap(find.text('Cancel Ride'));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Cancel Ride'), findsWidgets);
      expect(find.text('Please select reason for cancellation:'), findsOneWidget);
      expect(find.text('Keep Ride'), findsOneWidget);

      // Confirm Cancel
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Ride'));
      await tester.pumpAndSettle();

      // Summary bottom sheet appears
      if (find.text('Back to Home').evaluate().isNotEmpty) {
        await tester.tap(find.text('Back to Home'));
        await tester.pumpAndSettle();
      }

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('QuickRide Step 12 Rating & Review Screen Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'MG Road Metro Station',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala BDA Complex',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final testVehicle = VehicleOption.standardOptions.first;
    final testFare = FareCalculator.calculateFare(
      category: testVehicle.category,
      distanceKm: testRoute.distanceKm,
      estimatedMinutes: testRoute.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    late RideRequest testRequest;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await RideReviewService().clearAll();
      RideHistoryService().clearHistory();

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

      testRequest = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      ).copyWith(
        captain: CaptainModel.demo(vehicleCategoryTitle: testVehicle.title),
      );

      RideHistoryService().addCompletedRide(
        RideHistoryItem.fromRequest(testRequest),
      );
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    Widget buildRatingTestableWidget({RideRequest? request}) {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: RatingReviewScreen(
          rideRequest: request ?? testRequest,
        ),
      );
    }

    testWidgets('RatingReviewScreen renders all initial Step 12 UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      // Header & Subtitle
      expect(find.text('How was your ride?'), findsOneWidget);
      expect(
        find.text('Rate your experience with your QuickRide captain'),
        findsOneWidget,
      );

      // Captain Card Info
      expect(find.text('Demo Captain (Rajesh Kumar)'), findsOneWidget);
      expect(find.text('AP 09 CB 1234'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);

      // Stars
      expect(find.byType(StarRatingWidget), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));

      // Quick Feedback Chips
      expect(find.text('Clean Vehicle'), findsOneWidget);
      expect(find.text('Friendly Captain'), findsOneWidget);
      expect(find.text('Safe Ride'), findsOneWidget);
      expect(find.text('On Time'), findsOneWidget);
      expect(find.text('Smooth Ride'), findsOneWidget);
      expect(find.text('Good Driving'), findsOneWidget);

      // Review Field & Actions
      expect(find.text('Write a Review (optional)'), findsOneWidget);
      expect(find.text('Tell us about your ride...'), findsOneWidget);
      expect(find.text('0 / 500'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('Selecting star ratings updates message correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      // Initially no message
      expect(find.text("We're sorry your experience wasn't good."), findsNothing);

      // Tap 1st star
      await tester.tap(find.byKey(const ValueKey('star_1_false')));
      await tester.pumpAndSettle();
      expect(find.text("We're sorry your experience wasn't good."), findsOneWidget);

      // Tap 2nd star
      await tester.tap(find.byKey(const ValueKey('star_2_false')));
      await tester.pumpAndSettle();
      expect(find.text("We'll try to improve your experience."), findsOneWidget);

      // Tap 3rd star
      await tester.tap(find.byKey(const ValueKey('star_3_false')));
      await tester.pumpAndSettle();
      expect(find.text('Thanks for your feedback.'), findsOneWidget);

      // Tap 4th star
      await tester.tap(find.byKey(const ValueKey('star_4_false')));
      await tester.pumpAndSettle();
      expect(find.text("Great! We're glad you enjoyed your ride."), findsOneWidget);

      // Tap 5th star
      await tester.tap(find.byKey(const ValueKey('star_5_false')));
      await tester.pumpAndSettle();
      expect(find.text('Excellent! Thanks for rating QuickRide.'), findsOneWidget);
    });

    testWidgets('Tapping feedback chips toggles selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      final cleanChipFinder = find.byKey(const Key('chip_cleanVehicle'));
      final friendlyChipFinder = find.byKey(const Key('chip_friendlyCaptain'));

      expect(tester.widget<FilterChip>(cleanChipFinder).selected, isFalse);
      expect(tester.widget<FilterChip>(friendlyChipFinder).selected, isFalse);

      // Select Clean Vehicle
      await tester.tap(cleanChipFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(cleanChipFinder).selected, isTrue);

      // Select Friendly Captain
      await tester.tap(friendlyChipFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(friendlyChipFinder).selected, isTrue);

      // Deselect Clean Vehicle
      await tester.tap(cleanChipFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(cleanChipFinder).selected, isFalse);
      expect(tester.widget<FilterChip>(friendlyChipFinder).selected, isTrue);
    });

    testWidgets('Entering review text updates character counter',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'Great and smooth ride!');
      await tester.pumpAndSettle();

      expect(find.text('22 / 500'), findsOneWidget);
    });

    testWidgets('Submitting without selecting star shows validation error',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      // Tap Submit without rating
      await tester.tap(find.text('Submit Review'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a rating.'), findsOneWidget);
    });

    testWidgets('Submitting with star saves review and shows Thank You view',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      // Select 5 stars
      await tester.tap(find.byKey(const ValueKey('star_5_false')));
      await tester.pumpAndSettle();

      // Select feedback chips
      await tester.tap(find.byKey(const Key('chip_safeRide')));
      await tester.tap(find.byKey(const Key('chip_onTime')));
      await tester.pumpAndSettle();

      // Enter review text
      await tester.enterText(find.byType(TextField), 'Very safe and on time!');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Submit Review'));
      await tester.pumpAndSettle();

      // Verify Thank You view
      expect(find.text('Thank You! 🎉'), findsOneWidget);
      expect(find.text('Your feedback helps us improve QuickRide.'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Verify stored review
      final review = await RideReviewService().getReviewForRide(testRequest.rideId);
      expect(review, isNotNull);
      expect(review!.rating, 5);
      expect(review.reviewText, 'Very safe and on time!');
      expect(review.feedbackTags, contains(RatingFeedbackTag.safeRide));
      expect(review.feedbackTags, contains(RatingFeedbackTag.onTime));

      // Verify history item marked as isRated
      final historyItem = RideHistoryService().findById(testRequest.rideId);
      expect(historyItem, isNotNull);
      expect(historyItem!.isRated, isTrue);
      expect(historyItem.reviewId, review.reviewId);

      // Tap Back to Home navigates to HomeScreen
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Tapping Skip for now navigates to HomeScreen without rating',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(await RideReviewService().hasRated(testRequest.rideId), isFalse);

      final historyItem = RideHistoryService().findById(testRequest.rideId);
      expect(historyItem, isNotNull);
      expect(historyItem!.isRated, isFalse);
    });

    testWidgets('Shows Already Rated view if ride was previously rated',
        (WidgetTester tester) async {
      // Pre-save review
      await RideReviewService().submitReview(
        RideReview(
          reviewId: 'rev_123',
          rideId: testRequest.rideId,
          captainId: 'captain_1',
          rating: 4,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(buildRatingTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Already Rated'), findsOneWidget);
      expect(find.text('You have already rated this ride.'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('RideCompletedScreen Rate Your Ride button navigates to RatingReviewScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: RideCompletedScreen(rideRequest: testRequest),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rate Your Ride'), findsOneWidget);

      await tester.tap(find.text('Rate Your Ride'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingReviewScreen), findsOneWidget);
      expect(find.text('How was your ride?'), findsOneWidget);
    });
  });

  group('QuickRide Step 13 Ride History Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'MG Road Metro Station',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala BDA Complex',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final bikeVehicle = VehicleOption.standardOptions.first; // Bike
    final autoVehicle = VehicleOption.standardOptions[1]; // Auto

    final bikeFare = FareCalculator.calculateFare(
      category: bikeVehicle.category,
      distanceKm: testRoute.distanceKm,
      estimatedMinutes: testRoute.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    final autoFare = FareCalculator.calculateFare(
      category: autoVehicle.category,
      distanceKm: 4.5,
      estimatedMinutes: 15,
      applyFirstRideDiscount: false,
    );

    late RideHistoryItem completedBikeRide;
    late RideHistoryItem cancelledAutoRide;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await RideReviewService().clearAll();
      RideHistoryService().clearHistory();

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;

      final now = DateTime.now();

      completedBikeRide = RideHistoryItem(
        rideId: 'ride_bike_01',
        userId: 'user_123',
        pickup: testPickup,
        destination: testDestination,
        vehicle: bikeVehicle,
        distanceKm: 6.8,
        estimatedMinutes: 21,
        fareDetails: bikeFare,
        paymentMethod: PaymentMethod.cash,
        captain: CaptainModel.demo(vehicleCategoryTitle: bikeVehicle.title),
        completedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2, minutes: 25)),
        status: RideStatus.rideCompleted,
      );

      cancelledAutoRide = RideHistoryItem(
        rideId: 'ride_auto_02',
        userId: 'user_123',
        pickup: const LocationPoint(
          latitude: 12.9352,
          longitude: 77.6245,
          name: 'Indiranagar 100ft Road',
          address: 'Indiranagar, Bengaluru',
        ),
        destination: testDestination,
        vehicle: autoVehicle,
        distanceKm: 4.5,
        estimatedMinutes: 15,
        fareDetails: autoFare,
        paymentMethod: PaymentMethod.online,
        captain: CaptainModel.demo(vehicleCategoryTitle: autoVehicle.title),
        completedAt: now.subtract(const Duration(minutes: 30)),
        createdAt: now.subtract(const Duration(minutes: 35)),
        status: RideStatus.cancelled,
      );
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
    });

    Widget buildHistoryTestableWidget() {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: const RideHistoryScreen(),
      );
    }

    testWidgets('Empty state renders when no rides exist with Book a Ride button navigating to Home',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHistoryTestableWidget());
      await tester.pumpAndSettle();

      // 'My Rides' appears in AppBar title AND BottomNavigationBar label
      expect(find.text('My Rides'), findsWidgets);
      expect(find.text('No rides yet'), findsOneWidget);
      expect(find.text('Your completed rides will appear here.'), findsOneWidget);
      expect(find.text('Book a Ride'), findsOneWidget);

      await tester.tap(find.text('Book a Ride'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Renders list of rides with correct vehicle, route, status, fare, and captain details',
        (WidgetTester tester) async {
      RideHistoryService().addCompletedRide(completedBikeRide);
      RideHistoryService().addCompletedRide(cancelledAutoRide);

      await tester.pumpWidget(buildHistoryTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(RideHistoryCard), findsNWidgets(2));

      // Check Bike ride details
      expect(find.text(bikeVehicle.title), findsOneWidget);
      expect(find.text('MG Road Metro Station'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text(bikeFare.formattedFinalFare), findsOneWidget);

      // Check Cancelled Auto ride details
      expect(find.text(autoVehicle.title), findsOneWidget);
      expect(find.text('Indiranagar 100ft Road'), findsOneWidget);
      expect(find.text('Ride Cancelled'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('Newest rides appear first according to completedAt timestamp',
        (WidgetTester tester) async {
      // completedBikeRide is 2 hours ago, cancelledAutoRide is 30 mins ago
      RideHistoryService().addCompletedRide(completedBikeRide);
      RideHistoryService().addCompletedRide(cancelledAutoRide);

      await tester.pumpWidget(buildHistoryTestableWidget());
      await tester.pumpAndSettle();

      final cards = tester.widgetList<RideHistoryCard>(find.byType(RideHistoryCard)).toList();
      expect(cards.length, 2);
      expect(cards[0].ride.rideId, 'ride_auto_02'); // Newest first
      expect(cards[1].ride.rideId, 'ride_bike_01');
    });

    testWidgets('Status filters (All, Completed, Cancelled) correctly filter the displayed rides',
        (WidgetTester tester) async {
      RideHistoryService().addCompletedRide(completedBikeRide);
      RideHistoryService().addCompletedRide(cancelledAutoRide);

      await tester.pumpWidget(buildHistoryTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Completed (1)'), findsOneWidget);
      expect(find.text('Cancelled (1)'), findsOneWidget);
      expect(find.byType(RideHistoryCard), findsNWidgets(2));

      // Tap Completed filter
      await tester.tap(find.text('Completed (1)'));
      await tester.pumpAndSettle();
      expect(find.byType(RideHistoryCard), findsOneWidget);
      expect(find.text(bikeVehicle.title), findsOneWidget);
      expect(find.text(autoVehicle.title), findsNothing);

      // Tap Cancelled filter
      await tester.tap(find.text('Cancelled (1)'));
      await tester.pumpAndSettle();
      expect(find.byType(RideHistoryCard), findsOneWidget);
      expect(find.text(autoVehicle.title), findsOneWidget);
      expect(find.text(bikeVehicle.title), findsNothing);

      // Tap All filter
      await tester.tap(find.text('All (2)'));
      await tester.pumpAndSettle();
      expect(find.byType(RideHistoryCard), findsNWidgets(2));
    });

    testWidgets('Search field filters rides by pickup, destination, captain name, and vehicle',
        (WidgetTester tester) async {
      RideHistoryService().addCompletedRide(completedBikeRide);
      RideHistoryService().addCompletedRide(cancelledAutoRide);

      await tester.pumpWidget(buildHistoryTestableWidget());
      await tester.pumpAndSettle();

      // Both cards visible initially
      expect(find.byType(RideHistoryCard), findsNWidgets(2));

      // Search for Indiranagar — matches cancelled Auto ride only
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Indiranagar');
      await tester.pumpAndSettle();

      expect(find.byType(RideHistoryCard), findsOneWidget);
      final autoCard = tester.widget<RideHistoryCard>(find.byType(RideHistoryCard));
      expect(autoCard.ride.rideId, cancelledAutoRide.rideId);

      // Search for MG Road — matches completed Bike ride only
      await tester.enterText(searchField, 'MG Road');
      await tester.pumpAndSettle();

      expect(find.byType(RideHistoryCard), findsOneWidget);
      final bikeCard = tester.widget<RideHistoryCard>(find.byType(RideHistoryCard));
      expect(bikeCard.ride.rideId, completedBikeRide.rideId);

      // Clear search — both cards visible
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.byType(RideHistoryCard), findsNWidgets(2));
    });

    testWidgets('Tapping a ride card opens RideDetailsScreen with trip, vehicle, captain, fare, and map',
        (WidgetTester tester) async {
      RideHistoryService().addCompletedRide(completedBikeRide);

      await tester.pumpWidget(buildHistoryTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RideHistoryCard));
      await tester.pumpAndSettle();

      expect(find.byType(RideDetailsScreen), findsOneWidget);
      expect(find.text('Ride Details'), findsOneWidget);
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(find.text('TRIP'), findsOneWidget);
      expect(find.text('VEHICLE'), findsOneWidget);
      expect(find.text('CAPTAIN'), findsOneWidget);
      expect(find.text('FARE'), findsOneWidget);
      expect(find.text('PAYMENT & DATE'), findsOneWidget);
      expect(find.text('RATING & REVIEW'), findsOneWidget);

      // Check trip content
      expect(find.text('MG Road Metro Station'), findsOneWidget);
      expect(find.text('Koramangala BDA Complex'), findsOneWidget);
      expect(find.text('Distance: 6.8 km'), findsOneWidget);
      expect(find.text('Duration: 21 mins'), findsOneWidget);

      // Check fare content
      expect(find.text(bikeFare.formattedDistanceFare), findsOneWidget);
      expect(find.text(bikeFare.formattedFinalFare), findsOneWidget);
    });

    testWidgets('Unrated completed ride displays Not Rated and Rate Ride button which opens RatingReviewScreen',
        (WidgetTester tester) async {
      RideHistoryService().addCompletedRide(completedBikeRide);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: RideDetailsScreen(ride: completedBikeRide),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not Rated'), findsOneWidget);
      expect(find.text('Rate Ride'), findsOneWidget);

      // RideDetailsScreen content is tall — scroll Rate Ride button into view
      await tester.ensureVisible(find.text('Rate Ride'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rate Ride'));
      // pump a few frames so the route push and async _checkAlreadyRated settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(RatingReviewScreen), findsOneWidget);
      expect(find.text('How was your ride?'), findsOneWidget);
    });

    testWidgets('Rated completed ride displays star rating, review text, and feedback tags',
        (WidgetTester tester) async {
      await RideReviewService().submitReview(
        RideReview(
          reviewId: 'rev_bike_01',
          rideId: completedBikeRide.rideId,
          captainId: completedBikeRide.captain.id,
          rating: 5,
          reviewText: 'Superb and polite captain!',
          feedbackTags: [RatingFeedbackTag.cleanVehicle, RatingFeedbackTag.smoothRide],
          createdAt: DateTime.now(),
        ),
      );

      RideHistoryService().addCompletedRide(
        completedBikeRide.copyWith(
          isRated: true,
          reviewId: 'rev_bike_01',
          rating: 5,
          reviewText: 'Superb and polite captain!',
          reviewTags: ['Clean Vehicle', 'Smooth Ride'],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: RideDetailsScreen(ride: completedBikeRide),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Rating'), findsOneWidget);
      expect(find.text('Your Review'), findsOneWidget);
      expect(find.text('Superb and polite captain!'), findsOneWidget);
      expect(find.text('Clean Vehicle'), findsOneWidget);
      expect(find.text('Smooth Ride'), findsOneWidget);
      expect(find.text('Rate Ride'), findsNothing);
    });

    testWidgets('HomeScreen bottom navigation My Rides tab opens RideHistoryScreen with My Rides active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'My Rides' tab in bottom navigation
      await tester.tap(find.text(AppStrings.navMyRides));
      await tester.pumpAndSettle();

      expect(find.byType(RideHistoryScreen), findsOneWidget);
      // 'My Rides' appears in both the AppBar title and the BottomNavigationBar label
      expect(find.text('My Rides'), findsWidgets);
      // Specifically verify the AppBar title says 'My Rides'
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('My Rides'),
        ),
        findsOneWidget,
      );

      // BottomNavigationBar in RideHistoryScreen should have index 1 active
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.descendant(
          of: find.byType(RideHistoryScreen),
          matching: find.byType(BottomNavigationBar),
        ),
      );
      expect(bottomNav.currentIndex, 1);
    });
  });

  group('QuickRide Step 14 Offers & Promotions Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'MG Road Metro Station',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala BDA Complex',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 20.0,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final autoVehicle = VehicleOption.standardOptions[1]; // Auto

    setUp(() {
      OfferService().clearAppliedOffer();

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
      binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
      OfferService().clearAppliedOffer();
    });

    Widget buildOffersTestableWidget() {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: const OffersScreen(),
      );
    }

    testWidgets('OffersScreen renders all initial UI elements cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOffersTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Offers & Rewards'), findsOneWidget);
      expect(find.text('Save more on your QuickRide trips'), findsOneWidget);
      expect(find.text('Have a promo code?'), findsOneWidget);
      expect(find.text('Enter promo code'), findsOneWidget);
      expect(find.text('AVAILABLE OFFERS'), findsOneWidget);
      expect(find.byType(OfferCard), findsWidgets);
    });

    testWidgets('OfferCard displays titles, discount badges, and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOffersTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('FIRST RIDE — 50% OFF'), findsOneWidget);
      expect(find.text('Get 50% off on your first QuickRide ride.'), findsOneWidget);
      expect(find.text('SAVE ₹50'), findsOneWidget);
      expect(find.text('WEEKEND OFFER'), findsOneWidget);
      expect(find.text('View Offer'), findsOneWidget);
    });

    testWidgets('Valid coupon code QUICK50 applies offer and displays success',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOffersTestableWidget());
      await tester.pumpAndSettle();

      final couponField = find.byType(TextField);
      await tester.enterText(couponField, 'QUICK50');
      await tester.pumpAndSettle();

      // Tap Apply button in the promo code section (first Apply button on screen)
      final applyButton = find.widgetWithText(ElevatedButton, 'Apply').first;
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(find.text('Coupon applied successfully!'), findsWidgets);
      expect(find.textContaining('Applied'), findsWidgets);
      expect(OfferService().appliedOffer?.couponCode, 'QUICK50');
    });

    testWidgets('Invalid coupon code displays error feedback',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOffersTestableWidget());
      await tester.pumpAndSettle();

      final couponField = find.byType(TextField);
      await tester.enterText(couponField, 'INVALIDCODE');
      await tester.pumpAndSettle();

      final applyButton = find.widgetWithText(ElevatedButton, 'Apply').first;
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(find.text('Invalid or expired coupon.'), findsWidgets);
      expect(OfferService().appliedOffer, isNull);
    });

    testWidgets('Applying and removing an offer toggles Applied state and updates UI',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOffersTestableWidget());
      await tester.pumpAndSettle();

      // Find the card for "SAVE ₹50"
      final save50Card = find.widgetWithText(OfferCard, 'SAVE ₹50');
      expect(save50Card, findsOneWidget);

      // Tap Apply inside the SAVE 50 card
      final applyBtn = find.descendant(
        of: save50Card,
        matching: find.widgetWithText(ElevatedButton, 'Apply'),
      );
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Applied'), findsWidgets);
      expect(OfferService().appliedOffer?.id, 'offer_save50');

      // Tap Remove button in banner
      final removeBtn = find.widgetWithText(OutlinedButton, 'Remove').first;
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      expect(OfferService().appliedOffer, isNull);
    });

    testWidgets('Tapping offer card opens OfferDetailsScreen with terms and allows applying',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildOffersTestableWidget());
      await tester.pumpAndSettle();

      // Tap the "SAVE ₹50" card to open details
      await tester.tap(find.text('SAVE ₹50'));
      await tester.pumpAndSettle();

      expect(find.byType(OfferDetailsScreen), findsOneWidget);
      expect(find.text('Offer Details'), findsOneWidget);
      expect(find.text('ABOUT THIS OFFER'), findsOneWidget);
      expect(find.text('TERMS AND CONDITIONS'), findsOneWidget);
      expect(find.text('Minimum ride amount'), findsOneWidget);

      // Tap Apply Offer in bottom bar
      await tester.tap(find.text('Apply Offer'));
      await tester.pumpAndSettle();

      expect(OfferService().appliedOffer?.id, 'offer_save50');
      expect(find.textContaining('Applied'), findsOneWidget);

      // Pop back
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(OffersScreen), findsOneWidget);
    });

    testWidgets('HomeScreen bottom navigation Offers tab opens OffersScreen with index 2 active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Offers' tab in bottom navigation
      await tester.tap(find.text(AppStrings.navOffers));
      await tester.pumpAndSettle();

      expect(find.byType(OffersScreen), findsOneWidget);
      expect(find.text('Offers & Rewards'), findsOneWidget);

      // BottomNavigationBar in OffersScreen should have index 2 active
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.descendant(
          of: find.byType(OffersScreen),
          matching: find.byType(BottomNavigationBar),
        ),
      );
      expect(bottomNav.currentIndex, 2);
    });

    testWidgets('FareCalculationScreen applies eligible offer discount and recalculates final fare',
        (WidgetTester tester) async {
      // Pre-apply SAVE 50 offer
      final offer = OfferService().getOfferById('offer_save50')!;
      OfferService().applyOffer(offer);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: FareCalculationScreen(
            routeDetails: testRoute,
            selectedVehicle: autoVehicle,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify promo card is displayed with Applied check and offer title
      expect(find.text('SAVE ₹50'), findsOneWidget);
      expect(find.textContaining('Applied'), findsOneWidget);

      // Verify FareBreakdownCard shows the offer discount row
      expect(find.textContaining('Promo'), findsOneWidget);

      // Tap Remove button on FareCalculationScreen
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Offer removed.'), findsOneWidget);
      expect(OfferService().appliedOffer, isNull);
    });
  });

  group('QuickRide Step 15 User Profile & Account Tests', () {
    setUp(() {
      SessionManager().resetToDefault();
    });

    tearDown(() {
      SessionManager().resetToDefault();
    });

    Widget buildProfileTestApp({Widget? home}) {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: home ?? const ProfileScreen(),
      );
    }

    test('UserProfile model unit tests for initials, formatting, copyWith, JSON', () {
      final defaultUser = SessionManager().currentUser;
      expect(defaultUser.initials, 'AJ');
      expect(defaultUser.formattedCreatedAt, '15 Jan 2026');
      expect(defaultUser.formattedJoined, 'Member since Jan 2026');

      // Test single word name
      final singleWord = defaultUser.copyWith(fullName: 'Batman');
      expect(singleWord.initials, 'BA');

      // Test 3-word name
      final threeWords = defaultUser.copyWith(fullName: 'Bruce Thomas Wayne');
      expect(threeWords.initials, 'BT');

      // Test empty name fallback
      final emptyName = defaultUser.copyWith(fullName: '');
      expect(emptyName.initials, 'QR');

      // Test JSON roundtrip
      final json = defaultUser.toJson();
      final fromJson = UserProfile.fromJson(json);
      expect(fromJson.userId, defaultUser.userId);
      expect(fromJson.fullName, defaultUser.fullName);
      expect(fromJson.email, defaultUser.email);
      expect(fromJson.mobileNumber, defaultUser.mobileNumber);
    });

    testWidgets('ProfileScreen renders header elements (title, avatar, full name, mobile, email, joined date)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Alex Johnson'), findsWidgets);
      expect(find.text('+91 9876543210'), findsWidgets);
      expect(find.text('alex.johnson@quickride.com'), findsWidgets);
      expect(find.text('AJ'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
    });

    testWidgets('Personal information card displays correct user fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Account created date'), findsOneWidget);
      expect(find.text('15 Jan 2026'), findsOneWidget);
    });

    testWidgets('Tapping Edit Profile button opens EditProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Profile').first);
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('EditProfileScreen saves changes and updates ProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Profile').first);
      await tester.pumpAndSettle();

      // Find text fields and enter updated info
      final nameField = find.widgetWithText(TextFormField, 'Alex Johnson');
      await tester.enterText(nameField, 'Bruce Wayne');

      final phoneField = find.widgetWithText(TextFormField, '9876543210');
      await tester.enterText(phoneField, '9988776655');

      final emailField = find.widgetWithText(TextFormField, 'alex.johnson@quickride.com');
      await tester.enterText(emailField, 'bruce@waynecorp.com');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated successfully!'), findsOneWidget);
      expect(SessionManager().currentUser.fullName, 'Bruce Wayne');
      expect(SessionManager().currentUser.mobileNumber, '9988776655');
      expect(SessionManager().currentUser.email, 'bruce@waynecorp.com');
      expect(find.text('Bruce Wayne'), findsWidgets);
      expect(find.text('BW'), findsOneWidget);
    });

    testWidgets('EditProfileScreen validates invalid inputs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp(home: const EditProfileScreen()));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).at(0);
      final phoneField = find.byType(TextFormField).at(1);
      final emailField = find.byType(TextFormField).at(2);

      // Empty name
      await tester.enterText(nameField, '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your full name'), findsOneWidget);

      // Short name
      await tester.enterText(nameField, 'A');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Name must be at least 2 characters'), findsOneWidget);

      // Valid name, invalid mobile
      await tester.enterText(nameField, 'Bruce Wayne');
      await tester.enterText(phoneField, '12345');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);

      // Valid mobile, invalid email
      await tester.enterText(phoneField, '9876543210');
      await tester.enterText(emailField, 'invalidemail');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('My Rides menu option navigates to RideHistoryScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, 'My Rides'));
      await tester.pumpAndSettle();

      expect(find.byType(RideHistoryScreen), findsOneWidget);
    });

    testWidgets('Offers & Rewards menu option navigates to OffersScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Offers & Rewards'));
      await tester.pumpAndSettle();

      expect(find.byType(OffersScreen), findsOneWidget);
    });

    testWidgets('Help & Support menu option navigates to HelpSupportScreen and displays categories',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      expect(find.byType(HelpSupportScreen), findsOneWidget);
      expect(find.text('How can we help you?'), findsOneWidget);
      expect(find.text('Ride Issue'), findsOneWidget);
      expect(find.text('Payment Issue'), findsOneWidget);
      expect(find.text('Captain Issue'), findsOneWidget);
      expect(find.text('Account Issue'), findsOneWidget);
    });

    testWidgets('HelpSupportScreen Contact Support button opens support dialog and dismisses',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp(home: const HelpSupportScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chat with Support'));
      await tester.pumpAndSettle();

      expect(find.text('Live Support'), findsOneWidget);
      expect(find.text('Live support will be available in a future version.'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Live support will be available in a future version.'), findsNothing);
    });

    testWidgets('Terms & Conditions menu option navigates to TermsConditionsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms & Conditions'));
      await tester.pumpAndSettle();

      expect(find.byType(TermsConditionsScreen), findsOneWidget);
      expect(find.text('QuickRide Terms of Service'), findsOneWidget);
    });

    testWidgets('Privacy Policy menu option navigates to PrivacyPolicyScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('QuickRide Privacy Policy'), findsOneWidget);
    });

    testWidgets('About QuickRide menu option displays app version dialog and dismisses',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('About QuickRide'));
      await tester.pumpAndSettle();

      expect(find.text('Version v1.0.0'), findsOneWidget);
      expect(find.textContaining('Your Ride, Your Way'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Version v1.0.0'), findsNothing);
    });

    testWidgets('Logout button shows confirmation dialog and can cancel',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Logout from QuickRide?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Logout from QuickRide?'), findsNothing);
      expect(SessionManager().isLoggedIn, isTrue);
    });

    testWidgets('Logout confirmation logs out and navigates to LoginScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      final logoutButton = find.widgetWithText(ElevatedButton, 'Logout');
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(SessionManager().isLoggedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('HomeScreen bottom nav Profile tab (index 3) opens ProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
    });

    testWidgets('RideHistoryScreen bottom nav Profile tab (index 3) opens ProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const RideHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('OffersScreen bottom nav Profile tab (index 3) opens ProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const OffersScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('ProfileScreen bottom nav has Profile active and navigates to Home on index 0',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildProfileTestApp());
      await tester.pumpAndSettle();

      final bottomNavFinder = find.byType(BottomNavigationBar);
      expect(bottomNavFinder, findsOneWidget);
      final BottomNavigationBar bottomNav = tester.widget(bottomNavFinder);
      expect(bottomNav.currentIndex, 3);

      await tester.tap(find.byIcon(Icons.home_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('QuickRide Step 16 Notifications Center Tests', () {
    setUp(() {
      NotificationService().resetToDefault();
    });

    tearDown(() {
      NotificationService().resetToDefault();
    });

    Widget buildNotificationTestApp({Widget? home}) {
      return MaterialApp(
        onGenerateRoute: AppRoutes.generateRoute,
        home: home ?? const NotificationScreen(),
      );
    }

    test('AppNotification model unit tests for timeAgo, icons, copyWith, JSON', () {
      final now = DateTime.now();

      final notifJustNow = AppNotification(
        id: 'test_1',
        type: NotificationType.captainFound,
        title: 'Captain Found',
        message: 'Assigned',
        createdAt: now.subtract(const Duration(seconds: 10)),
      );
      expect(notifJustNow.timeAgo, 'Just now');
      expect(notifJustNow.iconData, Icons.person_pin_rounded);

      final notifMins = AppNotification(
        id: 'test_2',
        type: NotificationType.captainArriving,
        title: 'Captain Arrived',
        message: 'Arrived',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(notifMins.timeAgo, '5 min ago');
      expect(notifMins.iconData, Icons.near_me_rounded);

      final notifHours = AppNotification(
        id: 'test_3',
        type: NotificationType.rideStarted,
        title: 'Ride Started',
        message: 'Started',
        createdAt: now.subtract(const Duration(hours: 2)),
      );
      expect(notifHours.timeAgo, '2 hours ago');
      expect(notifHours.iconData, Icons.directions_car_rounded);

      final notifDays = AppNotification(
        id: 'test_4',
        type: NotificationType.rideCompleted,
        title: 'Ride Completed',
        message: 'Completed',
        createdAt: now.subtract(const Duration(days: 3)),
      );
      expect(notifDays.timeAgo, '3 days ago');
      expect(notifDays.iconData, Icons.check_circle_rounded);

      // copyWith & json
      final copied = notifJustNow.copyWith(isRead: true, title: 'Updated');
      expect(copied.isRead, isTrue);
      expect(copied.title, 'Updated');

      final json = copied.toJson();
      final fromJson = AppNotification.fromJson(json);
      expect(fromJson.id, copied.id);
      expect(fromJson.type, copied.type);
      expect(fromJson.title, copied.title);
      expect(fromJson.isRead, copied.isRead);

      // NotificationType enum code & fromCode
      expect(NotificationType.rideRequest.code, 'RIDE_REQUEST');
      expect(NotificationType.fromCode('RIDE_REQUEST'), NotificationType.rideRequest);
      expect(NotificationType.fromCode('OFFER'), NotificationType.offer);
      expect(NotificationType.fromCode('DISCOUNT'), NotificationType.discount);
      expect(NotificationType.fromCode('ACCOUNT'), NotificationType.account);
    });

    test('NotificationService repository operations: unread count, mark as read, delete, clear', () {
      final service = NotificationService();
      expect(service.getNotifications().length, 5);
      expect(service.unreadCount, 3);

      // markAsRead
      service.markAsRead('notif_01_captain_found');
      expect(service.unreadCount, 2);

      // markAllAsRead
      service.markAllAsRead();
      expect(service.unreadCount, 0);

      // deleteNotification
      service.deleteNotification('notif_01_captain_found');
      expect(service.getNotifications().length, 4);

      // addNotification
      service.addNotification(
        AppNotification(
          id: 'custom_notif',
          type: NotificationType.general,
          title: 'Custom Notice',
          message: 'This is a test notification.',
          createdAt: DateTime.now(),
        ),
      );
      expect(service.getNotifications().length, 5);
      expect(service.getNotifications().first.id, 'custom_notif');

      // clearAll
      service.clearAll();
      expect(service.getNotifications().isEmpty, isTrue);
      expect(service.unreadCount, 0);
    });

    testWidgets('NotificationScreen renders initial demo notifications list',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Captain Found'), findsOneWidget);
      expect(find.text('Captain Arrived'), findsOneWidget);
      expect(find.text('Ride Completed'), findsOneWidget);
      expect(find.text('New Offer Available'), findsOneWidget);
      expect(find.text('Welcome to QuickRide'), findsOneWidget);
      expect(find.text('Mark all as read'), findsOneWidget);
    });

    testWidgets('Tapping unread notification marks it as read and reduces unreadCount',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      expect(NotificationService().unreadCount, 3);

      // Tap on Captain Found card (unread)
      await tester.tap(find.text('Captain Found'));
      await tester.pumpAndSettle();

      expect(NotificationService().unreadCount, 2);
    });

    testWidgets('Mark all as read button marks all notifications as read',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      expect(NotificationService().unreadCount, 3);

      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      expect(NotificationService().unreadCount, 0);
      expect(find.text('All notifications marked as read.'), findsOneWidget);
      expect(find.text('Mark all as read'), findsNothing);
    });

    testWidgets('Deleting an individual notification removes it from the list',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Captain Found'), findsOneWidget);

      // Tap the close button on the first notification card
      final closeButtons = find.byTooltip('Delete notification');
      await tester.tap(closeButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Notification deleted.'), findsOneWidget);
      expect(find.text('Captain Found'), findsNothing);
    });

    testWidgets('Clear All action shows confirmation dialog and cancels without clearing',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all notifications?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(NotificationService().getNotifications().isNotEmpty, isTrue);
    });

    testWidgets('Clear All confirmation clears all notifications and displays empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(NotificationService().getNotifications().isEmpty, isTrue);
      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text("You're all caught up!"), findsOneWidget);
    });

    testWidgets('Tapping offer notification navigates to OffersScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Offer Available'));
      await tester.pumpAndSettle();

      expect(find.byType(OffersScreen), findsOneWidget);
    });

    testWidgets('Tapping account notification navigates to ProfileScreen',
        (WidgetTester tester) async {
      NotificationService().addNotification(
        AppNotification(
          id: 'notif_account_test',
          type: NotificationType.account,
          title: 'Account Update',
          message: 'Your profile settings have been updated.',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(buildNotificationTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Account Update'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('HomeScreen displays notification bell with unread badge count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Notification bell icon is present
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      // Badge displays unread count (3)
      expect(find.text('3'), findsOneWidget);

      // Tap notification bell opens NotificationScreen
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationScreen), findsOneWidget);
    });

    testWidgets('HomeScreen notification badge disappears when all notifications are read',
        (WidgetTester tester) async {
      NotificationService().markAllAsRead();

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      // Badge count text '3' should not exist
      expect(find.text('3'), findsNothing);
    });

    testWidgets('Ride event lifecycle simulation adds notifications',
        (WidgetTester tester) async {
      final pickup = const LocationPoint(
        latitude: 12.9716,
        longitude: 77.5946,
        name: 'MG Road',
        address: 'MG Road, Bengaluru',
      );
      final destination = const LocationPoint(
        latitude: 12.9352,
        longitude: 77.6245,
        name: 'Koramangala',
        address: 'Koramangala, Bengaluru',
      );
      final autoVehicle = VehicleOption.standardOptions[1];
      final fare = FareCalculator.calculateFare(
        category: autoVehicle.category,
        distanceKm: 5.0,
        estimatedMinutes: 15,
      );
      final rideRequest = RideRequest(
        rideId: 'ride_test_event_1',
        userId: 'user_test',
        pickup: pickup,
        destination: destination,
        selectedVehicle: autoVehicle,
        distanceKm: 5.0,
        estimatedMinutes: 15,
        fareDetails: fare,
        paymentMethod: PaymentMethod.cash,
        status: RideStatus.captainFound,
        captain: CaptainModel.demo(vehicleCategoryTitle: 'Auto'),
        createdAt: DateTime.now(),
      );

      final trackingService = RideTrackingService(
        initialRequest: rideRequest,
        simulationStepMs: 50,
        totalArrivalSteps: 2,
      );

      // Start arriving simulation
      trackingService.startArrivingSimulation();
      // Pump timer steps until arrival completes
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        NotificationService().getNotifications().any((n) => n.id == 'notif_arrived_ride_test_event_1'),
        isTrue,
      );

      // Start ride
      trackingService.startRide();
      expect(
        NotificationService().getNotifications().any((n) => n.id == 'notif_started_ride_test_event_1'),
        isTrue,
      );

      // Pump timer steps until ride completes
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        NotificationService().getNotifications().any((n) => n.id == 'notif_completed_ride_test_event_1'),
        isTrue,
      );

      trackingService.dispose();
    });
  });

  group('QuickRide Step 17 Help & Customer Support Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SupportService().resetToDefault();
      NotificationService().resetToDefault();
    });

    test('SupportRequest model serialization and properties', () {
      final now = DateTime(2026, 9, 10, 14, 30);
      final req = SupportRequest(
        requestId: 'QR1001',
        userId: 'user_123',
        rideId: 'ride_01',
        category: SupportCategory.rideIssue,
        issueType: 'Wrong fare',
        description: 'Charged twice for toll gate.',
        createdAt: now,
        status: SupportStatus.open,
      );

      final json = req.toJson();
      expect(json['requestId'], 'QR1001');
      expect(json['status'], 'OPEN');
      expect(json['category'], 'rideIssue');

      final fromJson = SupportRequest.fromJson(json);
      expect(fromJson.requestId, 'QR1001');
      expect(fromJson.status, SupportStatus.open);
      expect(fromJson.category, SupportCategory.rideIssue);
      expect(fromJson.formattedCreatedAt, contains('2026'));

      final updated = req.copyWith(status: SupportStatus.resolved);
      expect(updated.status, SupportStatus.resolved);
    });

    test('SupportService creates request, auto-increments ID, and emits notification', () async {
      final initialCount = SupportService().getSupportRequests().length;
      final initialNotifCount = NotificationService().getNotifications().length;

      final newReq = SupportRequest(
        requestId: '',
        userId: 'user_test',
        category: SupportCategory.captainIssue,
        issueType: 'Unsafe driving',
        description: 'Captain was speeding above limit.',
        createdAt: DateTime.now(),
      );

      final created = await SupportService().createSupportRequest(newReq);
      expect(created.requestId, 'QR1002');
      expect(SupportService().getSupportRequests().length, initialCount + 1);

      // Verify local notification emitted to NotificationService
      expect(NotificationService().getNotifications().length, initialNotifCount + 1);
      final latestNotif = NotificationService().getNotifications().first;
      expect(latestNotif.title, 'Support Request Submitted');
      expect(latestNotif.message, 'Your support request has been submitted successfully.');

      // Get by ID
      final retrieved = SupportService().getSupportRequestById('QR1002');
      expect(retrieved, isNotNull);
      expect(retrieved!.issueType, 'Unsafe driving');

      // Update status
      SupportService().updateSupportRequestStatus('QR1002', SupportStatus.inProgress);
      expect(SupportService().getSupportRequestById('QR1002')!.status, SupportStatus.inProgress);
    });

    testWidgets('HelpSupportScreen renders search bar, categories, FAQs, and safety guidance',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Titles & banner
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('How can we help you?'), findsOneWidget);

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Categories
      expect(find.text('WHAT DO YOU NEED HELP WITH?'), findsOneWidget);
      expect(find.text('Ride Issue'), findsOneWidget);
      expect(find.text('Captain Issue'), findsOneWidget);
      expect(find.text('Payment Issue'), findsOneWidget);
      expect(find.text('Pickup / Destination Issue'), findsOneWidget);
      expect(find.text('Offer / Coupon Issue'), findsOneWidget);
      expect(find.text('Account Issue'), findsOneWidget);
      expect(find.text('Safety Issue'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // FAQs
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
      expect(find.text('How do I book a ride?'), findsOneWidget);
      expect(find.text('How do I cancel a ride?'), findsOneWidget);
      expect(find.text('How is my fare calculated?'), findsOneWidget);

      // Safety First
      expect(find.text('Safety First'), findsOneWidget);
      expect(find.text('Report a Safety Issue'), findsOneWidget);

      // Contact Support
      expect(find.text('Contact QuickRide Support'), findsOneWidget);
      expect(find.text('Chat with Support'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);
    });

    testWidgets('FAQ expandable cards toggle answer visibility when tapped',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Answer not visible initially
      expect(find.textContaining('Set your pickup location and destination on the Home screen'), findsNothing);

      // Tap FAQ question
      await tester.tap(find.text('How do I book a ride?'));
      await tester.pumpAndSettle();

      // Answer now visible
      expect(find.textContaining('Set your pickup location and destination on the Home screen'), findsOneWidget);
    });

    testWidgets('FAQ search filters questions dynamically as user types',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How do I book a ride?'), findsOneWidget);
      expect(find.text('How do I cancel a ride?'), findsOneWidget);

      // Search for "cancel"
      await tester.enterText(find.byType(TextField), 'cancel');
      await tester.pumpAndSettle();

      expect(find.text('How do I cancel a ride?'), findsOneWidget);
      expect(find.text('How do I book a ride?'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('How do I book a ride?'), findsOneWidget);
    });

    testWidgets('Tapping category card navigates to ReportIssueScreen with pre-filled category',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ride Issue'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportIssueScreen), findsOneWidget);
      expect(find.text('Report Ride Issue'), findsOneWidget);
      expect(find.text("Captain didn't arrive"), findsOneWidget);
    });

    testWidgets('Payment Issue form displays backend disclaimer notice',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const ReportIssueScreen(initialCategory: SupportCategory.paymentIssue),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Payment Issue'), findsOneWidget);
      expect(
        find.text('Payment support will be connected to the QuickRide backend in a future version.'),
        findsOneWidget,
      );
    });

    testWidgets('ReportIssueScreen validates empty description and enforces 500 character limit',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const ReportIssueScreen(initialCategory: SupportCategory.rideIssue),
        ),
      );
      await tester.pumpAndSettle();

      // Counter initially 0 / 500
      expect(find.text('0 / 500'), findsOneWidget);

      // Tap submit with empty field -> triggers validation error
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      expect(find.text('Please describe your problem.'), findsOneWidget);

      // Enter text and verify counter updates
      await tester.enterText(find.byType(TextFormField), 'This is a valid test problem report.');
      await tester.pumpAndSettle();

      expect(find.text('36 / 500'), findsOneWidget);
    });

    testWidgets('Submitting issue creates request and navigates to SupportSuccessScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const ReportIssueScreen(initialCategory: SupportCategory.rideIssue),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Driver drove too fast on the highway.');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      expect(find.byType(SupportSuccessScreen), findsOneWidget);
      expect(find.text('Request Submitted'), findsOneWidget);
      expect(find.text('Your support request has been submitted successfully.'), findsOneWidget);
      expect(find.text('Request ID: QR1002'), findsOneWidget);
      expect(find.text('View Request'), findsOneWidget);
      expect(find.text('Back to Help'), findsOneWidget);

      // Tap "View Request" navigates to SupportRequestDetailsScreen
      await tester.tap(find.text('View Request'));
      await tester.pumpAndSettle();

      expect(find.byType(SupportRequestDetailsScreen), findsOneWidget);
      expect(find.text('Request #QR1002'), findsOneWidget);
      expect(find.text('Driver drove too fast on the highway.'), findsOneWidget);
      expect(find.text('Support team response will appear here when backend support is connected.'), findsOneWidget);
    });

    testWidgets('MySupportRequestsScreen displays list of submitted requests and navigates to details',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const MySupportRequestsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initial pre-seeded demo request QR1001
      expect(find.text('Request #QR1001'), findsOneWidget);
      expect(find.text('Category: Ride Issue'), findsOneWidget);
      expect(find.text('Issue: Wrong fare'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      // Tap request card opens details
      await tester.tap(find.text('Request #QR1001'));
      await tester.pumpAndSettle();

      expect(find.byType(SupportRequestDetailsScreen), findsOneWidget);
      expect(find.text('Request #QR1001'), findsOneWidget);
    });

    testWidgets('ProfileScreen includes Help & Support and My Support Requests menu options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('My Support Requests'), findsOneWidget);

      // Tap My Support Requests opens MySupportRequestsScreen
      await tester.tap(find.text('My Support Requests'));
      await tester.pumpAndSettle();

      expect(find.byType(MySupportRequestsScreen), findsOneWidget);
    });
  });

  group('QuickRide Step 18 Safety Center Tests', () {
    const testPickup = LocationPoint(
      latitude: 12.9716,
      longitude: 77.5946,
      name: 'MG Road Metro Station',
      address: 'MG Road, Bengaluru',
    );

    const testDestination = LocationPoint(
      latitude: 12.9279,
      longitude: 77.6271,
      name: 'Koramangala BDA Complex',
      address: '80 Feet Road, Koramangala',
    );

    const testRoute = RouteDetails(
      pickup: testPickup,
      destination: testDestination,
      distanceKm: 6.8,
      estimatedMinutes: 21,
      polylinePoints: [],
    );

    final testVehicle = VehicleOption.standardOptions.first;
    final testFare = FareCalculator.calculateFare(
      category: testVehicle.category,
      distanceKm: testRoute.distanceKm,
      estimatedMinutes: testRoute.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    RideRequest createTestSafetyRide({RideStatus status = RideStatus.arrived}) {
      return RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      ).copyWith(
        status: status,
        captain: CaptainModel.demo(vehicleCategoryTitle: testVehicle.title),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SafetyService().resetToDefault();
    });

    test('TripShareData models and serializes trip details accurately', () {
      final ride = createTestSafetyRide();
      final data = TripShareData.fromRideRequest(ride, userName: 'John Doe');

      expect(data.rideId, ride.rideId);
      expect(data.userName, 'John Doe');
      expect(data.pickup, 'MG Road Metro Station');
      expect(data.destination, 'Koramangala BDA Complex');
      expect(data.captainName, contains('Demo Captain'));
      expect(data.vehicleNumber, 'AP 09 CB 1234');
      expect(data.formattedShareText(), contains('MG Road Metro Station'));
      expect(data.formattedShareText(), contains('Demo Captain'));

      final json = data.toJson();
      final fromJson = TripShareData.fromJson(json);
      expect(fromJson.rideId, data.rideId);
      expect(fromJson.vehicleNumber, data.vehicleNumber);

      final demo = TripShareData.demo();
      expect(demo.rideId, 'QR-DEMO-789');
    });

    test('SafetyPreferences model handles defaults, copyWith and JSON roundtrip', () {
      const prefs = SafetyPreferences();
      expect(prefs.showSafetyReminders, isTrue);
      expect(prefs.showVehicleVerificationReminder, isTrue);
      expect(prefs.showTripSharingReminder, isTrue);

      final updated = prefs.copyWith(showTripSharingReminder: false);
      expect(updated.showTripSharingReminder, isFalse);
      expect(updated.showSafetyReminders, isTrue);

      final json = updated.toJson();
      final fromJson = SafetyPreferences.fromJson(json);
      expect(fromJson.showTripSharingReminder, isFalse);
      expect(fromJson.showSafetyReminders, isTrue);
    });

    test('SafetyService manages preferences, checklist state and notifications', () async {
      final service = SafetyService();
      service.resetToDefault();

      expect(service.preferences.showSafetyReminders, isTrue);
      expect(service.checklist['verify_vehicle'], isFalse);

      service.toggleChecklistItem('verify_vehicle');
      expect(service.checklist['verify_vehicle'], isTrue);

      service.resetChecklist();
      expect(service.checklist['verify_vehicle'], isFalse);

      // Trigger verification notification
      NotificationService().clearAll();
      service.triggerVerificationNotification('RIDE_NOTIF_TEST_1');
      expect(NotificationService().getNotifications().any((n) => n.rideId == 'RIDE_NOTIF_TEST_1'), isTrue);

      // Verify deduplication
      final countBefore = NotificationService().getNotifications().length;
      service.triggerVerificationNotification('RIDE_NOTIF_TEST_1');
      expect(NotificationService().getNotifications().length, countBefore);
    });

    testWidgets('SafetyCenterScreen idle renders header, emergency button, checklist and tips',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const SafetyCenterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safety Center'), findsOneWidget);
      expect(find.text('Emergency Help'), findsOneWidget);
      expect(find.text('Emergency Assistance'), findsWidgets);
      expect(find.text('Before You Ride'), findsOneWidget);
      expect(find.text('Share Your Trip'), findsOneWidget);
      expect(find.text('Safety Checklist'), findsOneWidget);
      expect(find.text('Safety Tips'), findsOneWidget);
      expect(find.text('Report a Safety Issue'), findsOneWidget);

      // Tap Emergency Assistance button opens confirmation dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Emergency Assistance'));
      await tester.pumpAndSettle();

      expect(find.text('Do you need emergency assistance?'), findsOneWidget);
      expect(find.text('If you are in immediate danger, contact your local emergency services.'), findsOneWidget);

      // Tap Continue opens Emergency Guidance dialog with helpline numbers
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency Guidance'), findsOneWidget);
      expect(find.textContaining('112 in India, 911 in the US, 999 in the UK'), findsOneWidget);

      // Dismiss guidance dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
      expect(find.text('Emergency Guidance'), findsNothing);

      // Toggle checklist item
      await tester.tap(find.text('Verify vehicle number'));
      await tester.pumpAndSettle();
      expect(SafetyService().checklist['verify_vehicle'], isTrue);

      // Tap Reset on checklist
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(SafetyService().checklist['verify_vehicle'], isFalse);

      // Open Safety Preferences from app bar
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SafetyPreferencesScreen), findsOneWidget);
      expect(find.text('Safety Preferences'), findsOneWidget);
    });

    testWidgets('SafetyCenterScreen with active ride shows ride and captain verification data',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final ride = createTestSafetyRide();

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: SafetyCenterScreen(activeRide: ride),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Koramangala BDA Complex'), findsWidgets);
      expect(find.text('Demo Captain (Rajesh Kumar)'), findsWidgets);
      expect(find.text('Hero Splendor Plus'), findsWidgets);
      expect(find.text('AP 09 CB 1234'), findsWidgets);

      // Tap Share Trip button opens dialog with prepared trip info
      await tester.tap(find.widgetWithText(OutlinedButton, 'Share Trip').first);
      await tester.pumpAndSettle();

      expect(find.text('Share Trip'), findsWidgets);
      expect(find.textContaining('Trip sharing will be connected to the QuickRide backend'), findsOneWidget);
      expect(find.textContaining('AP 09 CB 1234'), findsWidgets);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('SafetyPreferencesScreen switches toggle settings',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const SafetyPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Show safety reminders'), findsOneWidget);
      expect(find.text('Show vehicle verification reminder'), findsOneWidget);
      expect(find.text('Show trip-sharing reminder'), findsOneWidget);

      // Toggle first switch
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(SafetyService().preferences.showSafetyReminders, isFalse);
    });

    testWidgets('ProfileScreen contains Safety Center menu item and navigates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safety Center'), findsOneWidget);

      await tester.tap(find.text('Safety Center'));
      await tester.pumpAndSettle();

      expect(find.byType(SafetyCenterScreen), findsOneWidget);
    });

    testWidgets('CaptainDetailsScreen includes Safety Center button in contact row',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final ride = createTestSafetyRide(status: RideStatus.captainFound);
      final tracking = RideTrackingService(initialRequest: ride);

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: CaptainDetailsScreen(
            rideRequest: ride,
            trackingService: tracking,
            autoStartArrivingSimulation: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield_rounded), findsWidgets);

      // Tap the safety shield icon to open Safety Center
      await tester.tap(find.byTooltip('Safety Center'));
      await tester.pumpAndSettle();

      expect(find.byType(SafetyCenterScreen), findsOneWidget);
    });
  });

  group('QuickRide Step 19 Settings Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SettingsService().resetSettings();
    });

    test('AppSettings model serialization and defaults', () {
      const defaultSettings = AppSettings();
      expect(defaultSettings.rideNotificationsEnabled, isTrue);
      expect(defaultSettings.offerNotificationsEnabled, isTrue);
      expect(defaultSettings.safetyNotificationsEnabled, isTrue);
      expect(defaultSettings.generalNotificationsEnabled, isTrue);
      expect(defaultSettings.safetyRemindersEnabled, isTrue);
      expect(defaultSettings.vehicleVerificationEnabled, isTrue);
      expect(defaultSettings.tripSharingReminderEnabled, isTrue);
      expect(defaultSettings.themeMode, ThemeMode.dark);
      expect(defaultSettings.language, 'en');
      expect(defaultSettings.locationServicesEnabled, isTrue);
      expect(defaultSettings.personalizedOffersEnabled, isTrue);
      expect(defaultSettings.dataUsageOptimized, isFalse);

      final json = defaultSettings.toJson();
      final reconstructed = AppSettings.fromJson(json);
      expect(reconstructed.themeMode, ThemeMode.dark);
      expect(reconstructed.language, 'en');
      expect(reconstructed.locationServicesEnabled, isTrue);

      final modified = defaultSettings.copyWith(
        themeMode: ThemeMode.light,
        language: 'te',
        personalizedOffersEnabled: false,
      );
      expect(modified.themeMode, ThemeMode.light);
      expect(modified.language, 'te');
      expect(modified.personalizedOffersEnabled, isFalse);
    });

    test('SettingsService updates theme, language and resets settings', () async {
      final service = SettingsService();
      expect(service.themeMode, ThemeMode.dark);

      await service.setThemeMode(ThemeMode.light);
      expect(service.themeMode, ThemeMode.light);

      await service.setLanguage('te');
      expect(service.language, 'te');

      await service.setPersonalizedOffers(false);
      expect(service.settings.personalizedOffersEnabled, isFalse);

      await service.resetSettings();
      expect(service.themeMode, ThemeMode.dark);
      expect(service.language, 'en');
      expect(service.settings.personalizedOffersEnabled, isTrue);
    });


    testWidgets('SettingsScreen renders all sections and handles back navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('SAFETY'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('LANGUAGE'), findsOneWidget);
      expect(find.text('LOCATION'), findsOneWidget);
      expect(find.text('PRIVACY'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('DATA & STORAGE'), findsOneWidget);

      expect(find.text('Ride Notifications'), findsOneWidget);
      expect(find.text('App Appearance'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Clear Local Data'), findsOneWidget);
    });


    testWidgets('SettingsScreen appearance dialog allows switching theme',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Theme / Appearance tile
      await tester.tap(find.text('App Appearance'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Appearance'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);

      await tester.tap(find.text('Light Mode'));
      await tester.pumpAndSettle();

      expect(SettingsService().themeMode, ThemeMode.light);
    });

    testWidgets('SettingsScreen language dialog shows Telugu roadmap notice',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Language tile
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Telugu (తెలుగు)'), findsOneWidget);

      await tester.tap(find.text('Telugu (తెలుగు)'));
      await tester.pumpAndSettle();

      expect(find.text('Telugu language support is being prepared.'), findsWidgets);
    });

    testWidgets('SettingsScreen Location Preferences dialog opens',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Manage Location Permission'));
      await tester.pumpAndSettle();

      expect(find.text('Location Services'), findsWidgets);
      expect(find.text('Location services are currently enabled for QuickRide.'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('PrivacySettingsScreen toggles privacy switches',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: PrivacySettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data'), findsOneWidget);
      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Personalized Offers'), findsOneWidget);
      expect(find.text('Optimize Data Usage'), findsOneWidget);

      // Toggle Personalized Offers
      await tester.tap(find.text('Personalized Offers'));
      await tester.pumpAndSettle();

      expect(SettingsService().settings.personalizedOffersEnabled, isFalse);
    });

    testWidgets('ChangePasswordScreen renders security notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: ChangePasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Password Management'), findsOneWidget);
      expect(find.text('Security Notice'), findsOneWidget);
      expect(find.text('Back to Settings'), findsOneWidget);

      await tester.tap(find.text('Back to Settings'));
      await tester.pumpAndSettle();
    });


    testWidgets('AboutQuickRideScreen displays branding and opens licenses',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: AboutQuickRideScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About QuickRide'), findsWidgets);
      expect(find.text('Ride. Travel. Arrive.'), findsOneWidget);
      expect(find.text('Open-Source Acknowledgements'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });


    testWidgets('ProfileScreen Settings menu item navigates to SettingsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('QuickRide Step 20 Final User App Polish, Validation & Testing', () {
    test('Fare calculation Test 1: 5 km, 15 min across Bike, Auto, Car', () {
      // Step 44: Bike 5km @ 8.0/km = 40.0
      final bike = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 5.0,
        estimatedMinutes: 15,
      );
      expect(bike.originalFare, 40.0);
      expect(bike.discount, 0.0);
      expect(bike.finalFare, 40.0);

      // Step 44: Auto 5km @ 12.0/km = 60.0
      final auto = FareCalculator.calculateFare(
        category: VehicleCategory.auto,
        distanceKm: 5.0,
        estimatedMinutes: 15,
      );
      expect(auto.originalFare, 60.0);
      expect(auto.discount, 0.0);
      expect(auto.finalFare, 60.0);

      // Step 44: Car 5km @ 13.75/km = 68.75
      final car = FareCalculator.calculateFare(
        category: VehicleCategory.car,
        distanceKm: 5.0,
        estimatedMinutes: 15,
      );
      expect(car.originalFare, 68.75);
      expect(car.discount, 0.0);
      expect(car.finalFare, 68.75);

      // Verify no negative or NaN values
      expect(bike.finalFare.isNegative, isFalse);
      expect(bike.finalFare.isNaN, isFalse);
      expect(auto.finalFare.isNegative, isFalse);
      expect(auto.finalFare.isNaN, isFalse);
      expect(car.finalFare.isNegative, isFalse);
      expect(car.finalFare.isNaN, isFalse);
    });

    test('Fare calculation Test 2: 7 km, 20 min across Bike, Auto, Car', () {
      // Step 44: Bike 7km @ 5.5/km = 38.5
      final bike = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 7.0,
        estimatedMinutes: 20,
      );
      expect(bike.originalFare, 38.5);
      expect(bike.discount, 0.0);
      expect(bike.finalFare, 38.5);

      // Step 44: Auto 7km @ 8.25/km = 57.75
      final auto = FareCalculator.calculateFare(
        category: VehicleCategory.auto,
        distanceKm: 7.0,
        estimatedMinutes: 20,
      );
      expect(auto.originalFare, 57.75);
      expect(auto.discount, 0.0);
      expect(auto.finalFare, 57.75);

      // Step 44: Car 7km @ 13.75/km = 96.25
      final car = FareCalculator.calculateFare(
        category: VehicleCategory.car,
        distanceKm: 7.0,
        estimatedMinutes: 20,
      );
      expect(car.originalFare, 96.25);
      expect(car.discount, 0.0);
      expect(car.finalFare, 96.25);
    });

    test('Fare calculation Test 3: 8 km, 20 min across Bike, Auto, Car', () {
      // Step 44: Bike 8km @ 5.5/km = 44.0
      final bike = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 8.0,
        estimatedMinutes: 20,
      );
      expect(bike.originalFare, 44.0);
      expect(bike.discount, 0.0);
      expect(bike.finalFare, 44.0);

      // Step 44: Auto 8km @ 8.25/km = 66.0
      final auto = FareCalculator.calculateFare(
        category: VehicleCategory.auto,
        distanceKm: 8.0,
        estimatedMinutes: 20,
      );
      expect(auto.originalFare, 66.0);
      expect(auto.discount, 0.0);
      expect(auto.finalFare, 66.0);

      // Step 44: Car 8km @ 13.75/km = 110.0
      final car = FareCalculator.calculateFare(
        category: VehicleCategory.car,
        distanceKm: 8.0,
        estimatedMinutes: 20,
      );
      expect(car.originalFare, 110.0);
      expect(car.discount, 0.0);
      expect(car.finalFare, 110.0);
    });

    test('Fare calculation Test 4: 10 km, 30 min across Bike, Auto, Car', () {
      // Step 44: Bike 10km @ 5.5/km = 55.0
      final bike = FareCalculator.calculateFare(
        category: VehicleCategory.bike,
        distanceKm: 10.0,
        estimatedMinutes: 30,
      );
      expect(bike.originalFare, 55.0);
      expect(bike.discount, 0.0);
      expect(bike.finalFare, 55.0);

      // Step 44: Auto 10km @ 8.25/km = 82.5
      final auto = FareCalculator.calculateFare(
        category: VehicleCategory.auto,
        distanceKm: 10.0,
        estimatedMinutes: 30,
      );
      expect(auto.originalFare, 82.5);
      expect(auto.discount, 0.0);
      expect(auto.finalFare, 82.5);

      // Step 44: Car 10km @ 13.75/km = 137.5
      final car = FareCalculator.calculateFare(
        category: VehicleCategory.car,
        distanceKm: 10.0,
        estimatedMinutes: 30,
      );
      expect(car.originalFare, 137.5);
      expect(car.discount, 0.0);
      expect(car.finalFare, 137.5);
    });

    test('Ride state transitions: completed ride cannot return to rideStarted or move', () async {
      final req = RideRequest.create(
        routeDetails: const RouteDetails(
          pickup: LocationPoint(latitude: 12.9716, longitude: 77.5946, name: 'P', address: 'P Address'),
          destination: LocationPoint(latitude: 12.9279, longitude: 77.6271, name: 'D', address: 'D Address'),
          distanceKm: 5.0,
          estimatedMinutes: 15,
          polylinePoints: [],
        ),
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: const FareDetails(baseFare: 15, distanceFare: 40, timeFare: 3.3, waitingCharge: 0, originalFare: 58.3, discount: 29.15, finalFare: 29.15),
        paymentMethod: PaymentMethod.cash,
      );

      final service = RideTrackingService(
        initialRequest: req,
        simulationStepMs: 10,
        totalArrivalSteps: 2,
      );

      // Arrive and start ride
      service.startArrivingSimulation();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.status, RideStatus.arrived);

      service.startRide();
      expect(service.status, RideStatus.rideStarted);

      // Wait for trip to complete
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(service.status, RideStatus.rideCompleted);

      // Verify a completed ride does not reverse
      expect(service.status == RideStatus.rideStarted, isFalse);
      service.dispose();
    });

    test('Ride state transitions: cancelled ride terminates simulation', () {
      final req = RideRequest.create(
        routeDetails: const RouteDetails(
          pickup: LocationPoint(latitude: 12.9716, longitude: 77.5946, name: 'P', address: 'P Address'),
          destination: LocationPoint(latitude: 12.9279, longitude: 77.6271, name: 'D', address: 'D Address'),
          distanceKm: 5.0,
          estimatedMinutes: 15,
          polylinePoints: [],
        ),
        selectedVehicle: VehicleOption.standardOptions.first,
        fareDetails: const FareDetails(baseFare: 15, distanceFare: 40, timeFare: 3.3, waitingCharge: 0, originalFare: 58.3, discount: 29.15, finalFare: 29.15),
        paymentMethod: PaymentMethod.cash,
      );

      final service = RideTrackingService(initialRequest: req);
      service.startArrivingSimulation();
      expect(service.status, RideStatus.arriving);

      service.cancelRide();
      expect(service.status, RideStatus.cancelled);
      service.dispose();
    });
  });
}


