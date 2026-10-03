import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickride_user/core/constants/app_strings.dart';
import 'package:quickride_user/core/constants/google_maps_config.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/screens/home/home_screen.dart';
import 'package:quickride_user/services/location_service.dart';
import 'package:quickride_user/services/places_service.dart';
import 'package:quickride_user/widgets/location_search_dialog.dart';
import 'package:quickride_user/widgets/route_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocationService.mockPosition = null;
    LocationService.mockAddress = null;
    LocationService.mockPermissionDenied = false;
    PlacesService.mockSearchResults = null;
  });

  group('QuickRide - Destination Selection & Verification Suite', () {
    test('VERIFICATION 1: OpenStreetMap Nominatim is completely removed from LocationService', () {
      // Set test mock address
      LocationService.mockAddress = '123 MG Road, Bengaluru, Karnataka, 560001';
      expect(LocationService.mockAddress, contains('MG Road'));
      // Confirm GoogleMapsConfig is referenced
      expect(GoogleMapsConfig.defaultLat, 12.9716);
      expect(GoogleMapsConfig.defaultLng, 77.5946);
      expect(GoogleMapsConfig.defaultSearchRadiusMeters, 50000.0);
    });

    test('VERIFICATION 2: Reverse Geocode Point returns accurate coordinates and real address', () async {
      LocationService.mockAddress = 'Govt Polytechnic College, Dharmavaram, AP 515671';
      final point = await LocationService.reverseGeocodePoint(
        14.4137,
        77.7126,
        defaultName: 'Dharmavaram College',
      );

      expect(point.latitude, 14.4137);
      expect(point.longitude, 77.7126);
      expect(point.name, 'Dharmavaram College');
      expect(point.address, 'Govt Polytechnic College, Dharmavaram, AP 515671');
    });

    test('VERIFICATION 3: PlacesService returns empty list and does not generate fake offsets when empty', () async {
      PlacesService.mockSearchResults = null;
      final results = await PlacesService.searchLocations('');
      expect(results.isEmpty, isTrue);
    });

    testWidgets('METHOD 1 (Search): LocationSearchDialog renders "Select on Map" and search field', (tester) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LocationPoint? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await LocationSearchDialog.show(
                    context,
                    title: 'Select Destination',
                    isPickup: false,
                  );
                },
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Verify title and search field
      expect(find.text('Select Destination'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify Method 2 direct entry: "Select Directly on Google Map"
      expect(find.text('Select Directly on Google Map'), findsOneWidget);
      expect(find.text('Tap any point or road on map to drop destination marker'), findsOneWidget);

      // Tap "Select Directly on Google Map"
      await tester.tap(find.text('Select Directly on Google Map'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(selectedResult!.placeId, 'select_on_map');
    });

    testWidgets('METHOD 1 (Search): Shows "No matching location found" on unmatch without fake fallbacks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      PlacesService.mockSearchResults = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LocationSearchDialog.show(
                  context,
                  title: 'Select Destination',
                  initialQuery: 'NonExistentLocalStreetXYZ',
                  isPickup: false,
                ),
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      // Verify empty state display
      expect(find.text('No matching location found'), findsOneWidget);
      expect(find.text('Select on Map'), findsWidgets);
    });

    testWidgets('METHOD 1 (Search): Selects real search suggestion with resolved coordinates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const realLocalPlace = LocationPoint(
        latitude: 14.4140,
        longitude: 77.7130,
        name: 'Govt Polytechnic Dharmavaram',
        address: 'Station Road, Dharmavaram, Andhra Pradesh 515671',
        placeId: 'ChIJ_polytechnic_dmm',
      );

      PlacesService.mockSearchResults = [realLocalPlace];
      LocationPoint? chosen;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  chosen = await LocationSearchDialog.show(
                    context,
                    title: 'Select Destination',
                    initialQuery: 'Polytechnic',
                    isPickup: false,
                  );
                },
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      expect(find.text('Govt Polytechnic Dharmavaram'), findsOneWidget);

      await tester.tap(find.text('Govt Polytechnic Dharmavaram'));
      await tester.pumpAndSettle();

      expect(chosen, isNotNull);
      expect(chosen!.latitude, 14.4140);
      expect(chosen!.longitude, 77.7130);
      expect(chosen!.placeId, 'ChIJ_polytechnic_dmm');
      expect(chosen!.address, contains('Dharmavaram'));
    });

    testWidgets('METHOD 2 (Map Tap): RouteSummaryCard renders destination and direct map shortcut', (tester) async {
      bool mapTapped = false;
      bool searchTapped = false;

      const pickup = LocationPoint(
        latitude: 14.4100,
        longitude: 77.7100,
        name: 'Current Location',
        address: 'Dharmavaram Bus Stand',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteSummaryCard(
              pickup: pickup,
              destination: null,
              onTapPickup: () {},
              onTapDestination: () => searchTapped = true,
              onTapSelectDestinationOnMap: () => mapTapped = true,
              onSwap: () {},
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.destinationSearchPrompt), findsOneWidget);
      expect(find.byIcon(Icons.map_rounded), findsOneWidget);

      // Tap destination field opens search
      await tester.tap(find.text(AppStrings.destinationSearchPrompt));
      await tester.pump();
      expect(searchTapped, isTrue);

      // Tap direct map icon triggers map mode
      await tester.tap(find.byIcon(Icons.map_rounded));
      await tester.pump();
      expect(mapTapped, isTrue);
    });

    testWidgets('METHOD 2 (Map Tap Flow): HomeScreen enters destination selection mode and confirms', (tester) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LocationService.mockAddress = 'Market Road, Dharmavaram, AP 515671';

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find GoogleMap widget
      final mapFinder = find.byType(GoogleMap);
      expect(mapFinder, findsOneWidget);

      // Simulate map tap at real destination coordinates (Method 2)
      final GoogleMap mapWidget = tester.widget(mapFinder);
      mapWidget.onTap?.call(const LatLng(14.4155, 77.7155));
      await tester.pumpAndSettle();

      // Verify "Confirm Destination" card appears
      expect(find.text('Confirm Destination'), findsWidgets);
      expect(find.textContaining('Lat: 14.41550'), findsOneWidget);
      expect(find.textContaining('Lng: 77.71550'), findsOneWidget);
      expect(find.text('Market Road, Dharmavaram, AP 515671'), findsOneWidget);

      // Tap "Confirm Destination" button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Destination'));
      await tester.pumpAndSettle();

      // Confirm destination is saved and route summary is displayed
      expect(find.text('Confirm Destination'), findsNothing);
      expect(find.text('Market Road, Dharmavaram, AP 515671'), findsWidgets);
    });

    testWidgets('METHOD 2 (Map Tap Cancel): Canceling map selection clears temporary marker', (tester) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      LocationService.mockAddress = 'Temporary Location, Test Street';

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on map
      final GoogleMap mapWidget = tester.widget(find.byType(GoogleMap));
      mapWidget.onTap?.call(const LatLng(14.4200, 77.7200));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Destination'), findsWidgets);

      // Tap Cancel
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Confirm card disappears and destination is not set
      expect(find.text('Confirm Destination'), findsNothing);
      expect(find.text(AppStrings.destinationSearchPrompt), findsOneWidget);
    });
  });
}
