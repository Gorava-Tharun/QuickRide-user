import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/screens/vehicle_selection/vehicle_selection_screen.dart';
import 'package:quickride_user/services/fare_calculator.dart';

void main() {
  group('STEP 44 — Centralized Fare Calculation & Slab Engine Tests', () {
    test('Bike Slabs & Boundaries Verification', () {
      // < 1 km: Unavailable
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 0.5).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 0.99).available, isFalse);

      // 1–5 km: ₹8.00/km
      final bike1 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 1.0);
      expect(bike1.available, isTrue);
      expect(bike1.ratePerKm, 8.00);
      expect(bike1.fare, 8.00);
      expect(bike1.selectedSlab, '1–5 km');

      final bike3 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 3.0);
      expect(bike3.available, isTrue);
      expect(bike3.ratePerKm, 8.00);
      expect(bike3.fare, 24.00);

      final bike5 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 5.0);
      expect(bike5.available, isTrue);
      expect(bike5.ratePerKm, 8.00);
      expect(bike5.fare, 40.00);

      // 5–10 km: ₹5.50/km
      final bike5_01 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 5.01);
      expect(bike5_01.available, isTrue);
      expect(bike5_01.ratePerKm, 5.50);
      expect(bike5_01.selectedSlab, '5–10 km');

      final bike8 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 8.0);
      expect(bike8.available, isTrue);
      expect(bike8.ratePerKm, 5.50);
      expect(bike8.fare, 44.00); // 8 * 5.5 = 44

      final bike10 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 10.0);
      expect(bike10.available, isTrue);
      expect(bike10.ratePerKm, 5.50);
      expect(bike10.fare, 55.00);

      // 10–20 km: ₹4.50/km
      final bike10_01 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 10.01);
      expect(bike10_01.available, isTrue);
      expect(bike10_01.ratePerKm, 4.50);
      expect(bike10_01.selectedSlab, '10–20 km');

      final bike15 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 15.0);
      expect(bike15.available, isTrue);
      expect(bike15.ratePerKm, 4.50);
      expect(bike15.fare, 67.50);

      final bike20 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 20.0);
      expect(bike20.available, isTrue);
      expect(bike20.ratePerKm, 4.50);
      expect(bike20.fare, 90.00);

      // 20–35 km: ₹4.00/km
      final bike20_01 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 20.01);
      expect(bike20_01.available, isTrue);
      expect(bike20_01.ratePerKm, 4.00);
      expect(bike20_01.selectedSlab, '20–35 km');

      final bike25 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 25.0);
      expect(bike25.available, isTrue);
      expect(bike25.ratePerKm, 4.00);
      expect(bike25.fare, 100.00); // 25 * 4.0 = 100

      final bike35 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 35.0);
      expect(bike35.available, isTrue);
      expect(bike35.ratePerKm, 4.00);
      expect(bike35.fare, 140.00);

      // 35–50 km: ₹3.50/km
      final bike35_01 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 35.01);
      expect(bike35_01.available, isTrue);
      expect(bike35_01.ratePerKm, 3.50);
      expect(bike35_01.selectedSlab, '35–50 km');

      final bike40 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 40.0);
      expect(bike40.available, isTrue);
      expect(bike40.ratePerKm, 3.50);
      expect(bike40.fare, 140.00);

      final bike50 = FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 50.0);
      expect(bike50.available, isTrue);
      expect(bike50.ratePerKm, 3.50);
      expect(bike50.fare, 175.00);

      // > 50 km: Unavailable
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 50.01).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 60.0).available, isFalse);
    });

    test('Auto Slabs & Boundaries Verification (Bike × 1.5)', () {
      // < 1 km: Unavailable
      expect(FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 0.5).available, isFalse);

      // 1–5 km: ₹12.00/km (8 * 1.5)
      final auto1 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 1.0);
      expect(auto1.available, isTrue);
      expect(auto1.ratePerKm, 12.00);
      expect(auto1.fare, 12.00);
      expect(auto1.selectedSlab, '1–5 km');

      final auto3 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 3.0);
      expect(auto3.available, isTrue);
      expect(auto3.ratePerKm, 12.00);
      expect(auto3.fare, 36.00);

      final auto5 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 5.0);
      expect(auto5.available, isTrue);
      expect(auto5.ratePerKm, 12.00);
      expect(auto5.fare, 60.00);

      // 5–10 km: ₹8.25/km (5.5 * 1.5)
      final auto8 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 8.0);
      expect(auto8.available, isTrue);
      expect(auto8.ratePerKm, 8.25);
      expect(auto8.fare, 66.00); // 8 * 8.25 = 66

      final auto10 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 10.0);
      expect(auto10.available, isTrue);
      expect(auto10.ratePerKm, 8.25);
      expect(auto10.fare, 82.50);

      // 10–20 km: ₹6.75/km (4.5 * 1.5)
      final auto15 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 15.0);
      expect(auto15.available, isTrue);
      expect(auto15.ratePerKm, 6.75);
      expect(auto15.fare, 101.25);

      final auto20 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 20.0);
      expect(auto20.available, isTrue);
      expect(auto20.ratePerKm, 6.75);
      expect(auto20.fare, 135.00);

      // 20–35 km: ₹6.00/km (4.0 * 1.5)
      final auto25 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 25.0);
      expect(auto25.available, isTrue);
      expect(auto25.ratePerKm, 6.00);
      expect(auto25.fare, 150.00); // 25 * 6.0 = 150

      final auto35 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 35.0);
      expect(auto35.available, isTrue);
      expect(auto35.ratePerKm, 6.00);
      expect(auto35.fare, 210.00);

      // 35–50 km: ₹5.25/km (3.5 * 1.5)
      final auto40 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 40.0);
      expect(auto40.available, isTrue);
      expect(auto40.ratePerKm, 5.25);
      expect(auto40.fare, 210.00);

      final auto50 = FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 50.0);
      expect(auto50.available, isTrue);
      expect(auto50.ratePerKm, 5.25);
      expect(auto50.fare, 262.50);

      // > 50 km: Unavailable
      expect(FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 50.01).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 60.0).available, isFalse);
    });

    test('Car Slabs & Boundaries Verification (Bike × 2.5, min 5km, max 150km)', () {
      // < 5 km: Unavailable
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 0.5).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 1.0).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 3.0).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 4.99).available, isFalse);

      // 5–10 km: ₹13.75/km (5.5 * 2.5)
      final car5 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 5.0);
      expect(car5.available, isTrue);
      expect(car5.ratePerKm, 13.75);
      expect(car5.fare, 68.75); // 5 * 13.75 = 68.75
      expect(car5.selectedSlab, '5–10 km');

      final car8 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 8.0);
      expect(car8.available, isTrue);
      expect(car8.ratePerKm, 13.75);
      expect(car8.fare, 110.00); // 8 * 13.75 = 110

      final car10 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 10.0);
      expect(car10.available, isTrue);
      expect(car10.ratePerKm, 13.75);
      expect(car10.fare, 137.50);

      // 10–20 km: ₹11.25/km (4.5 * 2.5)
      final car15 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 15.0);
      expect(car15.available, isTrue);
      expect(car15.ratePerKm, 11.25);
      expect(car15.fare, 168.75);

      final car20 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 20.0);
      expect(car20.available, isTrue);
      expect(car20.ratePerKm, 11.25);
      expect(car20.fare, 225.00);

      // 20–35 km: ₹10.00/km (4.0 * 2.5)
      final car25 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 25.0);
      expect(car25.available, isTrue);
      expect(car25.ratePerKm, 10.00);
      expect(car25.fare, 250.00); // 25 * 10.0 = 250

      final car35 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 35.0);
      expect(car35.available, isTrue);
      expect(car35.ratePerKm, 10.00);
      expect(car35.fare, 350.00);

      // 35–150 km: ₹8.75/km (3.5 * 2.5)
      final car40 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 40.0);
      expect(car40.available, isTrue);
      expect(car40.ratePerKm, 8.75);
      expect(car40.fare, 350.00);

      final car60 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 60.0);
      expect(car60.available, isTrue);
      expect(car60.ratePerKm, 8.75);
      expect(car60.fare, 525.00); // 60 * 8.75 = 525

      final car100 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 100.0);
      expect(car100.available, isTrue);
      expect(car100.ratePerKm, 8.75);
      expect(car100.fare, 875.00); // 100 * 8.75 = 875

      final car150 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 150.0);
      expect(car150.available, isTrue);
      expect(car150.ratePerKm, 8.75);
      expect(car150.fare, 1312.50);

      // > 150 km: Unavailable
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 150.01).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 160.0).available, isFalse);
    });

    test('Special Scenario Checks (3km, 60km, 160km, 0.5km)', () {
      // 3 km: Bike & Auto available, Car unavailable (<5 km)
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 3.0).available, isTrue);
      expect(FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 3.0).available, isTrue);
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 3.0).available, isFalse);

      // 60 km: Bike & Auto unavailable (>50 km), Car available (₹525)
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 60.0).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 60.0).available, isFalse);
      final car60 = FareCalculator.calculate(vehicleType: 'Car', distanceKm: 60.0);
      expect(car60.available, isTrue);
      expect(car60.fare, 525.00);

      // 160 km: All unavailable
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 160.0).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 160.0).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 160.0).available, isFalse);

      // 0.5 km: All unavailable
      expect(FareCalculator.calculate(vehicleType: 'Bike', distanceKm: 0.5).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Auto', distanceKm: 0.5).available, isFalse);
      expect(FareCalculator.calculate(vehicleType: 'Car', distanceKm: 0.5).available, isFalse);
    });
  });

  group('STEP 44 — Vehicle Selection UI & Availability Tests', () {
    testWidgets('Renders dynamic fares and unavailable reason chips for 3 km route (Car disabled)',
        (WidgetTester tester) async {
      const route3km = RouteDetails(
        pickup: LocationPoint(latitude: 12.9716, longitude: 77.5946, name: 'Pickup', address: 'Pickup Addr'),
        destination: LocationPoint(latitude: 12.9800, longitude: 77.6000, name: 'Dest', address: 'Dest Addr'),
        distanceKm: 3.0,
        estimatedMinutes: 10,
        polylinePoints: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: VehicleSelectionScreen(routeDetails: route3km),
        ),
      );
      await tester.pumpAndSettle();

      // Bike: ₹24, Auto: ₹36
      expect(find.text('₹24'), findsOneWidget);
      expect(find.text('₹36'), findsOneWidget);

      // Car should show "Unavailable" and reason chip
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.textContaining('Distance is below 5 km minimum for Car.'), findsOneWidget);

      // Tap unavailable Car -> shows snackbar
      await tester.tap(find.text('Car'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Distance is below 5 km minimum for Car.'), findsWidgets);
    });

    testWidgets('Shows "No vehicle is available for this distance." banner when distance is 160 km',
        (WidgetTester tester) async {
      const route160km = RouteDetails(
        pickup: LocationPoint(latitude: 12.9716, longitude: 77.5946, name: 'Pickup', address: 'Pickup Addr'),
        destination: LocationPoint(latitude: 14.5000, longitude: 78.5000, name: 'Far Dest', address: 'Far Addr'),
        distanceKm: 160.0,
        estimatedMinutes: 200,
        polylinePoints: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: VehicleSelectionScreen(routeDetails: route160km),
        ),
      );
      await tester.pumpAndSettle();

      // Warning banner displayed
      expect(find.text('No vehicle is available for this distance.'), findsOneWidget);

      // All 3 show Unavailable
      expect(find.text('Unavailable'), findsNWidgets(3));
    });
  });
}
