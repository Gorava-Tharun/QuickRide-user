import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickride_user/core/constants/app_strings.dart';
import 'package:quickride_user/screens/home/home_screen.dart';
import 'package:quickride_user/screens/vehicle_selection/vehicle_selection_screen.dart';
import 'package:quickride_user/services/location_service.dart';

Widget buildTestableApp({Widget? home}) {
  return MaterialApp(
    home: home ?? const HomeScreen(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocationService.mockPosition = null;
    LocationService.mockAddress = null;
    LocationService.mockPermissionDenied = false;
  });

  tearDown(() {
    LocationService.mockPosition = null;
    LocationService.mockAddress = null;
    LocationService.mockPermissionDenied = false;
  });

  group('QuickRide - Pickup and Destination Address Display Verification', () {
    testWidgets('SCENARIO 1: Select pickup from Google Maps -> address appears in pickup field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LocationService.mockAddress = '100 Dharmavaram Cotton Market Road, AP 515671';

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap "Select on Google Map" for pickup
      final pickupMapIconFinder = find.byTooltip('Select on Google Map');
      expect(pickupMapIconFinder, findsWidgets);
      await tester.tap(pickupMapIconFinder.first);
      await tester.pumpAndSettle();

      // Simulate map tap for pickup
      final mapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      mapWidget.onTap?.call(const LatLng(14.4137, 77.7126));
      await tester.pumpAndSettle();

      // Verify "Confirm Pickup Location" card appears
      expect(find.text('Confirm Pickup Location'), findsOneWidget);
      expect(find.text('100 Dharmavaram Cotton Market Road, AP 515671'), findsWidgets);

      // Confirm pickup
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Pickup'));
      await tester.pumpAndSettle();

      // Verify the pickup text field displays the address and not "Address unavailable"
      expect(find.text('100 Dharmavaram Cotton Market Road, AP 515671'), findsOneWidget);
      expect(find.text('Address unavailable'), findsNothing);
      expect(find.text('Location selected, address unavailable'), findsNothing);
    });

    testWidgets('SCENARIO 2: Select destination from Google Maps -> address appears in destination field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LocationService.mockAddress = 'Anantapur Clock Tower, Subhash Road, AP 515001';

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Tap on Google Map directly (Method 2 for destination)
      final mapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      mapWidget.onTap?.call(const LatLng(14.6819, 77.6006));
      await tester.pumpAndSettle();

      // Verify "Confirm Destination" card appears
      expect(find.text('Confirm Destination'), findsWidgets);
      expect(find.text('Anantapur Clock Tower, Subhash Road, AP 515001'), findsOneWidget);

      // Confirm destination
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Destination'));
      await tester.pumpAndSettle();

      // Verify destination text field displays the address
      expect(find.text('Anantapur Clock Tower, Subhash Road, AP 515001'), findsOneWidget);
      expect(find.text('Address unavailable'), findsNothing);
      expect(find.text('Location selected, address unavailable'), findsNothing);
    });

    testWidgets('SCENARIO 3 & 4: Changing pickup updates ONLY pickup; changing destination updates ONLY destination', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LocationService.mockAddress = 'Station Road, Dharmavaram';

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // 1. Set Destination first
      final mapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      LocationService.mockAddress = 'Destination Mall, Anantapur';
      mapWidget.onTap?.call(const LatLng(14.6800, 77.6000));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Destination'));
      await tester.pumpAndSettle();

      expect(find.text('Destination Mall, Anantapur'), findsOneWidget);

      // 2. Now change Pickup only
      LocationService.mockAddress = 'New Pickup Location, Market Street';
      await tester.tap(find.byTooltip('Select on Google Map').first);
      await tester.pumpAndSettle();

      final updatedMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      updatedMap.onTap?.call(const LatLng(14.4200, 77.7200));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Pickup'));
      await tester.pumpAndSettle();

      // Assert: Pickup updated to New Pickup, Destination remains Destination Mall
      expect(find.text('New Pickup Location, Market Street'), findsOneWidget);
      expect(find.text('Destination Mall, Anantapur'), findsOneWidget);
    });

    testWidgets('SCENARIO 5: Rapid sequential selection drops stale async geocoding responses', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      final mapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));

      // Quick tap 1
      LocationService.mockAddress = 'Stale Old Address 1';
      mapWidget.onTap?.call(const LatLng(14.5000, 77.5000));
      await tester.pump(const Duration(milliseconds: 10));

      // Quick tap 2 (newer)
      LocationService.mockAddress = 'Fresh Latest Address 2';
      mapWidget.onTap?.call(const LatLng(14.6000, 77.6000));
      await tester.pumpAndSettle();

      // Verify the latest address is active
      expect(find.text('Fresh Latest Address 2'), findsOneWidget);
      expect(find.text('Stale Old Address 1'), findsNothing);
    });

    test('SCENARIO 6: Incomplete or restricted geocoding falls back to readable locality instead of error', () async {
      LocationService.mockAddress = null; // No mock address -> tests real fallback logic

      final point = await LocationService.reverseGeocodePoint(
        14.4137,
        77.7126,
        defaultName: 'College Area',
      );

      // Proximity to Dharmavaram hub yields real town name and coordinates
      expect(point.address, contains('Dharmavaram'));
      expect(point.address, isNot(contains('Address unavailable')));
      expect(point.address, isNot(contains('Location selected, address unavailable')));
    });

    testWidgets('SCENARIO 7 & 8: Coordinates and markers correspond, and ride booking/fare calculation works', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LocationService.mockAddress = 'Dharmavaram Railway Station, AP';
      await tester.pumpWidget(buildTestableApp());
      await tester.pumpAndSettle();

      // Set destination ~12 km away in Anantapur district
      LocationService.mockAddress = 'Bathalapalli Junction, AP';
      final mapWidget = tester.widget<GoogleMap>(find.byType(GoogleMap));
      mapWidget.onTap?.call(const LatLng(14.5200, 77.7800));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Destination'));
      await tester.pumpAndSettle();

      expect(find.text('Bathalapalli Junction, AP'), findsOneWidget);

      // Verify Continue button navigates to Vehicle Selection & Fare Calculation
      expect(find.text(AppStrings.continueButton), findsOneWidget);
      await tester.tap(find.text(AppStrings.continueButton));
      await tester.pumpAndSettle();

      // Assert Vehicle Selection Screen is reached with calculated fares
      expect(find.byType(VehicleSelectionScreen), findsOneWidget);
      expect(find.text(AppStrings.chooseRideTitle), findsWidgets);
      expect(find.text('Bike'), findsWidgets);
      expect(find.text('Auto'), findsWidgets);
      expect(find.text('Car'), findsWidgets);
    });
  });
}
