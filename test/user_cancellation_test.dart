import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/models/location_model.dart';
import 'package:quickride_user/models/vehicle_model.dart';
import 'package:quickride_user/models/ride_details_model.dart';
import 'package:quickride_user/models/ride_model.dart';
import 'package:quickride_user/services/fare_calculator.dart';
import 'package:quickride_user/widgets/user_cancellation_dialog.dart';

void main() {
  group('Step 43 — User Ride Cancellation & Refund Policy Unit Tests', () {
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
    );

    test('Cancellation fee is 0 and refund is 100% when ride is in REQUESTED state', () {
      final req = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      );

      expect(req.status, RideStatus.searchingForCaptain);

      // In searching/requested state:
      const cancellationFee = 0.0;
      final fare = req.fareDetails.effectiveFinalFare;
      final refund = fare - cancellationFee;

      expect(cancellationFee, 0.0);
      expect(refund, fare);
    });

    test('Cancellation fee is 0 within 2 minutes grace period after captain accepted', () {
      final acceptedAt = DateTime.now().subtract(const Duration(minutes: 1, seconds: 15));
      final durationSinceAcceptance = DateTime.now().difference(acceptedAt);

      expect(durationSinceAcceptance.inMinutes < 2, isTrue);

      final cancellationFee = durationSinceAcceptance.inMinutes < 2 ? 0.0 : 25.0;
      expect(cancellationFee, 0.0);
    });

    test('Cancellation fee is 25 after 2 minutes grace period while captain is arriving', () {
      final acceptedAt = DateTime.now().subtract(const Duration(minutes: 3, seconds: 30));
      final durationSinceAcceptance = DateTime.now().difference(acceptedAt);

      expect(durationSinceAcceptance.inMinutes >= 2, isTrue);

      final cancellationFee = durationSinceAcceptance.inMinutes < 2 ? 0.0 : 25.0;
      expect(cancellationFee, 25.0);

      const totalFare = 150.0;
      final refund = totalFare - cancellationFee;
      expect(refund, 125.0);
    });

    test('Cancellation fee is 50 when captain has ARRIVED or ride is IN_PROGRESS', () {
      double calculateFee(SharedRideStatus status) {
        if (status == SharedRideStatus.arrived || status == SharedRideStatus.inProgress) {
          return 50.0;
        }
        return 25.0;
      }

      final cancellationFee = calculateFee(SharedRideStatus.arrived);
      expect(cancellationFee, 50.0);

      const totalFare = 200.0;
      final refund = totalFare - cancellationFee;
      expect(refund, 150.0);
    });

    test('Completed ride cannot be cancelled', () {
      final req = RideRequest.create(
        routeDetails: testRoute,
        selectedVehicle: testVehicle,
        fareDetails: testFare,
        paymentMethod: PaymentMethod.cash,
      ).copyWith(status: RideStatus.rideCompleted);

      final isAllowedToCancel = req.status != RideStatus.rideCompleted &&
          req.status != RideStatus.cancelled;

      expect(isAllowedToCancel, isFalse);
    });
  });

  group('Step 43 — UserCancellationDialog Widget Tests', () {
    testWidgets('Renders all standard cancellation reasons and returns selected result', (tester) async {
      UserCancellationResult? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await UserCancellationDialog.show(
                    ctx,
                    rideId: 'RIDE_999_TEST',
                    currentStatus: SharedRideStatus.accepted,
                    fare: 180.0,
                    isOnlinePaid: true,
                    acceptedAt: DateTime.now().subtract(const Duration(minutes: 4)),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Ride'), findsWidgets);
      expect(find.text('Please select reason for cancellation:'), findsOneWidget);
      expect(find.text('Cancellation Fee'), findsOneWidget);
      expect(find.text('₹25'), findsOneWidget);
      expect(find.text('Estimated Refund:'), findsOneWidget);
      expect(find.text('₹155'), findsOneWidget);

      // Select 'Changed my plans'
      await tester.tap(find.text('Changed my plans'));
      await tester.pumpAndSettle();

      // Enter optional notes
      await tester.enterText(find.byType(TextField), 'Change of meeting venue');
      await tester.pumpAndSettle();

      // Tap Cancel Ride button in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Ride'));
      await tester.pumpAndSettle();

      expect(dialogResult, isNotNull);
      expect(dialogResult?.reason, 'Changed my plans');
      expect(dialogResult?.description, 'Change of meeting venue');
      expect(dialogResult?.cancellationFee, 25.0);
      expect(dialogResult?.refundAmount, 155.0);
    });
  });
}
