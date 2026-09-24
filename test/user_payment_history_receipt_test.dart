import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/screens/payment/digital_receipt_screen.dart';
import 'package:quickride_user/screens/payment/payment_history_screen.dart';
import 'package:quickride_user/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockPayment = FirestorePaymentModel(
    paymentId: 'PAY_QR_TEST_101',
    rideId: 'QR_TEST_101',
    userId: 'user_quickride_01',
    captainId: 'CAP_MOCK_1',
    passengerName: 'Aarav Sharma',
    captainName: 'Rajesh Kumar',
    pickupAddress: 'MG Road Metro Station',
    dropAddress: 'Koramangala 5th Block',
    vehicleType: 'Auto',
    distanceKm: 6.5,
    originalFare: 150.0,
    discountAmount: 30.0,
    finalAmount: 120.0,
    couponCode: 'SAVE30',
    currency: 'INR',
    paymentMethod: 'upi',
    paymentStatus: FirestorePaymentStatus.paid,
    gatewayOrderId: 'order_test_101',
    gatewayPaymentId: 'pay_test_101',
    gatewaySignature: 'sig_test_hmac',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 58)),
    paidAt: DateTime.now().subtract(const Duration(minutes: 58)),
  );

  group('Step 38: User App Payment History & Digital Receipt Tests', () {
    testWidgets('DigitalReceiptScreen renders full tax invoice slip and itemized breakdown',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DigitalReceiptScreen(payment: mockPayment),
        ),
      );
      await tester.pumpAndSettle();

      // Check header branding & slip title
      expect(find.text('QuickRide'), findsOneWidget);
      expect(find.text('Tax Invoice & Verified Receipt'), findsOneWidget);

      // Check Ride & Payment ID
      expect(find.text('QR_TEST_101'), findsOneWidget);
      expect(find.text('PAY_QR_TEST_101'), findsOneWidget);

      // Check route and passengers
      expect(find.text('MG Road Metro Station'), findsOneWidget);
      expect(find.text('Koramangala 5th Block'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);

      // Check Itemized Fare breakdown
      expect(find.text('₹150.00'), findsOneWidget); // Original fare
      expect(find.text('-₹30.00'), findsOneWidget); // Discount
      expect(find.text('₹120.00'), findsWidgets); // Verified final amount

      // Check share and print actions
      final shareFinder = find.text('Share Receipt');
      final printFinder = find.text('Print Slip');
      expect(shareFinder, findsOneWidget);
      expect(printFinder, findsOneWidget);

      // Test clipboard copy
      await tester.ensureVisible(shareFinder);
      await tester.tap(shareFinder);
      await tester.pumpAndSettle();
      expect(find.text('Digital receipt copied to clipboard for sharing!'), findsOneWidget);
    });

    testWidgets('PaymentHistoryScreen renders filter chips and payment cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check screen title and filter chips
      expect(find.text('Payment History'), findsOneWidget);
      expect(find.text('All Payments'), findsOneWidget);
      expect(find.text('PAID'), findsWidgets);
      expect(find.text('FAILED'), findsOneWidget);
      expect(find.text('REFUNDED'), findsOneWidget);

      // Verify payment list items rendered from seeded cache
      expect(find.byType(ListView), findsOneWidget);
      expect(find.textContaining('₹'), findsWidgets);
    });

    test('QuickRideFirebaseService provides offline fallback payments when Firestore is disconnected',
        () async {
      final payments = await QuickRideFirebaseService().fetchUserPayments('user_quickride_01');
      expect(payments, isNotEmpty);
      expect(payments.first.finalAmount, greaterThan(0));
    });
  });
}
