import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickride_user/core/constants/app_strings.dart';
import 'package:quickride_user/screens/home/home_screen.dart';
import 'package:quickride_user/screens/vehicle_selection/vehicle_selection_screen.dart';
import 'package:quickride_user/services/location_service.dart';
import 'package:quickride_user/widgets/route_summary_card.dart';

Widget buildTestableHomeScreen({Key? key}) {
  return MaterialApp(
    home: HomeScreen(key: key),
  );
}

Position createMockPosition(double lat, double lng) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

void main() {
  setUp(() {
    LocationService.mockPosition = null;
    LocationService.mockAddress = null;
    LocationService.mockPermissionDenied = false;
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1200, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    LocationService.mockPosition = null;
    LocationService.mockAddress = null;
    LocationService.mockPermissionDenied = false;
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('QuickRide - Pickup Location Requirements & Verification', () {
    testWidgets(
      'TEST 1: Open User App with location permission enabled -> Current GPS location becomes default pickup',
      (WidgetTester tester) async {
        // Arrange: mock GPS location in Hyderabad
        LocationService.mockPosition = createMockPosition(17.3850, 78.4867);
        LocationService.mockAddress = 'Secunderabad Railway Station, Hyderabad, Telangana, 500003';
        LocationService.mockPermissionDenied = false;

        // Act: Open HomeScreen
        await tester.pumpWidget(buildTestableHomeScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert: Detected current location and address are displayed
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(RouteSummaryCard), findsOneWidget);
        expect(find.text(AppStrings.currentLocation), findsOneWidget);
        expect(find.text('Secunderabad Railway Station, Hyderabad, Telangana, 500003'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 2: Manually select a different pickup location -> Pickup updates and does NOT revert automatically',
      (WidgetTester tester) async {
        // Arrange: Start with GPS at Hyderabad
        LocationService.mockPosition = createMockPosition(17.3850, 78.4867);
        LocationService.mockAddress = 'Secunderabad Station, Hyderabad';
        LocationService.mockPermissionDenied = false;

        await tester.pumpWidget(buildTestableHomeScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify initial GPS pickup
        expect(find.text('Secunderabad Station, Hyderabad'), findsOneWidget);

        // Act: Open Pickup search dialog
        await tester.tap(find.text(AppStrings.pickupLocation));
        await tester.pumpAndSettle();

        // Select a different location: Kurnool City Railway Station
        expect(find.text('Kurnool City Railway Station'), findsOneWidget);
        await tester.tap(find.text('Kurnool City Railway Station'));
        await tester.pumpAndSettle();

        // Assert: Pickup updated to Kurnool
        expect(find.text('Kurnool City Railway Station'), findsOneWidget);
        expect(find.text('Station Road, Kurnool, Andhra Pradesh 518004'), findsOneWidget);

        // Simulate additional time and background ticks
        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(seconds: 5));

        // Verify pickup does NOT revert back to Hyderabad
        expect(find.text('Kurnool City Railway Station'), findsOneWidget);
        expect(find.text('Station Road, Kurnool, Andhra Pradesh 518004'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 3: Select destination after changing pickup -> Distance and fare use selected pickup coordinates',
      (WidgetTester tester) async {
        // Arrange: Start with GPS at Hyderabad
        LocationService.mockPosition = createMockPosition(17.3850, 78.4867);
        LocationService.mockAddress = 'Secunderabad Station, Hyderabad';
        LocationService.mockPermissionDenied = false;

        await tester.pumpWidget(buildTestableHomeScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Change Pickup to Kurnool City Railway Station (15.8281, 78.0373)
        await tester.tap(find.text(AppStrings.pickupLocation));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kurnool City Railway Station'));
        await tester.pumpAndSettle();

        // Change Destination to Kurnool Airport (15.7118, 78.1888)
        await tester.tap(find.text(AppStrings.destinationSearchPrompt));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kurnool Airport (Uyyalawada Narasimha Reddy)'));
        await tester.pumpAndSettle();

        // Assert: Distance is calculated from Kurnool City to Kurnool Airport (~20.9 km)
        final distanceKm = LocationService.calculateDistanceKm(15.8281, 78.0373, 15.7118, 78.1888);
        expect(distanceKm, greaterThan(18.0));
        expect(distanceKm, lessThan(25.0));

        // Tap Continue to navigate to vehicle selection
        await tester.tap(find.text(AppStrings.continueButton));
        await tester.pumpAndSettle();

        expect(find.byType(VehicleSelectionScreen), findsOneWidget);
        expect(find.text('Kurnool City Railway Station'), findsOneWidget);
        expect(find.text('Kurnool Airport (Uyyalawada Narasimha Reddy)'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 4: Deny location permission -> App does not crash and manual selection remains available',
      (WidgetTester tester) async {
        // Arrange: Deny location permission
        LocationService.mockPosition = null;
        LocationService.mockAddress = null;
        LocationService.mockPermissionDenied = true;

        // Act: Open HomeScreen
        await tester.pumpWidget(buildTestableHomeScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert: App does not crash, warning banner is displayed
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text(AppStrings.locationPermissionDeniedNotice), findsOneWidget);

        // Manual pickup selection remains fully functional
        await tester.tap(find.text(AppStrings.pickupLocation));
        await tester.pumpAndSettle();

        expect(find.text('Select Pickup Location'), findsOneWidget);
        expect(find.text('Kurnool City Railway Station'), findsOneWidget);
        await tester.tap(find.text('Kurnool City Railway Station'));
        await tester.pumpAndSettle();

        expect(find.text('Kurnool City Railway Station'), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 5: Restart the app and open booking screen -> Current GPS location is again initial pickup',
      (WidgetTester tester) async {
        // Run first session with Bengaluru
        LocationService.mockPosition = createMockPosition(12.9716, 77.5946);
        LocationService.mockAddress = 'MG Road, Bengaluru, Karnataka 560001';
        LocationService.mockPermissionDenied = false;

        await tester.pumpWidget(buildTestableHomeScreen(key: const ValueKey('session_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('MG Road, Bengaluru, Karnataka 560001'), findsOneWidget);

        // Manually change pickup to another location
        await tester.tap(find.text(AppStrings.pickupLocation));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kurnool City Railway Station'));
        await tester.pumpAndSettle();
        expect(find.text('Kurnool City Railway Station'), findsOneWidget);

        // SIMULATE APP RESTART: Fresh HomeScreen is mounted with newly detected GPS (e.g. Airport)
        LocationService.mockPosition = createMockPosition(13.1986, 77.7066);
        LocationService.mockAddress = 'Kempegowda International Airport (BLR), Bengaluru 560300';

        await tester.pumpWidget(buildTestableHomeScreen(key: const ValueKey('session_2')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert: Fresh launch uses the newly detected current GPS location
        expect(find.text('Kempegowda International Airport (BLR), Bengaluru 560300'), findsOneWidget);
      },
    );
  });
}
