import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/models/offer_model.dart';
import 'package:quickride_user/services/firebase_service.dart';
import 'package:quickride_user/services/offer_service.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase & Firestore Models Roundtrip Tests', () {
    test('FirestoreUserModel toMap and fromMap serialization', () {
      final user = FirestoreUserModel(
        userId: 'usr-001',
        name: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul@example.com',
        profileImage: 'https://example.com/avatar.png',
        status: 'ACTIVE',
        createdAt: DateTime(2026, 3, 10, 14, 30),
      );

      final map = user.toMap();
      expect(map['userId'], 'usr-001');
      expect(map['name'], 'Rahul Sharma');
      expect(map['phone'], '9876543210');
      expect(map['status'], 'ACTIVE');

      final deserialized = FirestoreUserModel.fromMap(map, id: 'usr-001');
      expect(deserialized.userId, 'usr-001');
      expect(deserialized.name, 'Rahul Sharma');
      expect(deserialized.email, 'rahul@example.com');
      expect(deserialized.createdAt.year, 2026);
    });

    test('SharedRideModel supports all 6 standardized statuses', () {
      final statuses = [
        SharedRideStatus.requested,
        SharedRideStatus.accepted,
        SharedRideStatus.arrived,
        SharedRideStatus.inProgress,
        SharedRideStatus.completed,
        SharedRideStatus.cancelled,
      ];

      for (final status in statuses) {
        final ride = SharedRideModel(
          rideId: 'RD-${status.name}',
          userId: 'usr-123',
          captainId: 'cpt-456',
          pickup: 'MG Road',
          destination: 'Airport',
          pickupLocation: {'lat': 12.9716, 'lng': 77.5946},
          destinationLocation: {'lat': 13.1986, 'lng': 77.7066},
          vehicleType: 'Car',
          fare: 550.0,
          distance: 32.5,
          estimatedTime: 45,
          status: status,
          requestedAt: DateTime(2026, 3, 10, 10, 0),
        );

        final map = ride.toMap();
        expect(map['status'], status.firestoreValue);

        final parsed = SharedRideModel.fromMap(map, id: ride.rideId);
        expect(parsed.status, status);
        expect(parsed.fare, 550.0);
      }
    });

    test('FirestoreComplaintModel and RatingModel serialization', () {
      final complaint = FirestoreComplaintModel(
        complaintId: 'CMP-101',
        userId: 'usr-1',
        captainId: 'cpt-1',
        rideId: 'RD-1',
        subject: 'Overcharging',
        description: 'Captain charged extra cash',
        status: 'OPEN',
        createdAt: DateTime(2026, 3, 12),
      );

      final cMap = complaint.toMap();
      final cParsed = FirestoreComplaintModel.fromMap(cMap);
      expect(cParsed.complaintId, 'CMP-101');
      expect(cParsed.status, 'OPEN');

      final rating = FirestoreRatingModel(
        ratingId: 'RAT-201',
        rideId: 'RD-1',
        userId: 'usr-1',
        captainId: 'cpt-1',
        rating: 4.5,
        review: 'Great clean vehicle',
        createdAt: DateTime(2026, 3, 12),
      );

      final rMap = rating.toMap();
      final rParsed = FirestoreRatingModel.fromMap(rMap);
      expect(rParsed.rating, 4.5);
      expect(rParsed.review, 'Great clean vehicle');
    });

    test('QuickRideFirebaseService gracefully handles offline initialization without crashing', () async {
      final service = QuickRideFirebaseService();
      // Should not throw exception even without google-services.json
      final result = await service.initialize();
      expect(result, isA<bool>());
      // Even if false (in unit test environment), service remains valid and in fallback mode
      expect(service.statusMessage.isNotEmpty, isTrue);

      final diag = await service.testConnection();
      expect(diag.containsKey('isFirebaseAvailable'), isTrue);
      expect(diag['appId'], 'com.quickride.user');
    });

    test('SessionManager integrates with user profile and sync', () {
      final session = SessionManager();
      session.login(fullName: 'Test User', email: 'test@quickride.com', phone: '9999988888');
      expect(session.currentUser.fullName, 'Test User');
      expect(session.currentUser.email, 'test@quickride.com');
      expect(session.isLoggedIn, isTrue);
    });

    test('FirestoreOfferModel percentage discount calculation and caps', () {
      final now = DateTime.now();
      final offer = FirestoreOfferModel(
        offerId: 'OFFER_TEST_1',
        title: '50% Off First Ride',
        description: 'Get 50% discount up to Rs 100',
        couponCode: 'QUICK50',
        discountType: 'percentage',
        discountValue: 50.0,
        maxDiscount: 100.0,
        minimumFare: 150.0,
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 30)),
        usageLimit: 1000,
        perUserLimit: 1,
        usedCount: 10,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(offer.isValid, isTrue);

      // Under minimum fare: 0 discount
      expect(offer.calculateDiscount(100.0), 0.0);

      // Above minimum fare: 50% of 160 = 80 (< 100 cap)
      expect(offer.calculateDiscount(160.0), 80.0);

      // Above cap: 50% of 300 = 150 -> capped at 100
      expect(offer.calculateDiscount(300.0), 100.0);
    });

    test('FirestoreOfferModel fixed amount discount calculation', () {
      final now = DateTime.now();
      final offer = FirestoreOfferModel(
        offerId: 'OFFER_TEST_2',
        title: 'Flat Rs 75 Off',
        description: 'Flat Rs 75 off on rides over Rs 200',
        couponCode: 'FLAT75',
        discountType: 'fixed',
        discountValue: 75.0,
        minimumFare: 200.0,
        validFrom: now.subtract(const Duration(days: 2)),
        validUntil: now.add(const Duration(days: 10)),
        usageLimit: 500,
        perUserLimit: 2,
        usedCount: 50,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      // Under minimum fare: 0 discount
      expect(offer.calculateDiscount(150.0), 0.0);

      // Over minimum fare: exactly 75
      expect(offer.calculateDiscount(250.0), 75.0);

      // Discount cannot exceed fare itself
      final smallFareOffer = offer.copyWith(minimumFare: 50.0);
      expect(smallFareOffer.calculateDiscount(60.0), 60.0);
    });

    test('SharedRideModel serializes offerId, couponCode, originalFare, and discountAmount', () {
      final ride = SharedRideModel(
        rideId: 'RD-OFFER-1',
        userId: 'usr-10',
        captainId: 'cpt-20',
        pickup: 'Forum Mall',
        destination: 'Indiranagar',
        pickupLocation: {'lat': 12.9352, 'lng': 77.6101},
        destinationLocation: {'lat': 12.9784, 'lng': 77.6408},
        vehicleType: 'Car',
        fare: 250.0, // Discounted final fare
        originalFare: 350.0,
        discountAmount: 100.0,
        offerId: 'OFFER_QUICK50',
        couponCode: 'QUICK50',
        distance: 8.5,
        estimatedTime: 25,
        status: SharedRideStatus.requested,
        requestedAt: DateTime(2026, 3, 14, 15, 0),
      );

      final map = ride.toMap();
      expect(map['fare'], 250.0);
      expect(map['originalFare'], 350.0);
      expect(map['discountAmount'], 100.0);
      expect(map['offerId'], 'OFFER_QUICK50');
      expect(map['couponCode'], 'QUICK50');

      final deserialized = SharedRideModel.fromMap(map, id: 'RD-OFFER-1');
      expect(deserialized.fare, 250.0);
      expect(deserialized.originalFare, 350.0);
      expect(deserialized.discountAmount, 100.0);
      expect(deserialized.offerId, 'OFFER_QUICK50');
      expect(deserialized.couponCode, 'QUICK50');
    });

    test('OfferService validates coupons and handles apply / remove', () {
      final service = OfferService();

      // Clear any prior state
      service.removeOffer();
      expect(service.hasAppliedOffer, isFalse);

      // Test valid demo coupon QUICK50
      final offer = service.validateCoupon('QUICK50');
      expect(offer, isNotNull);
      expect(offer!.couponCode, 'QUICK50');

      service.applyOffer(offer);
      expect(service.hasAppliedOffer, isTrue);
      expect(service.appliedOffer?.couponCode, 'QUICK50');

      // Test invalid coupon
      final invalidOffer = service.validateCoupon('NONEXISTENT_PROMO');
      expect(invalidOffer, isNull);

      // Remove offer
      service.removeOffer();
      expect(service.hasAppliedOffer, isFalse);
      expect(service.appliedOffer, isNull);
    });

    test('Offer.fromFirestore maps FirestoreOfferModel correctly', () {
      final now = DateTime.now();
      final firestoreModel = FirestoreOfferModel(
        offerId: 'OFF_999',
        title: 'Special Holi Discount',
        description: 'Enjoy festive rides',
        couponCode: 'HOLI2026',
        discountType: 'percentage',
        discountValue: 25.0,
        maxDiscount: 150.0,
        minimumFare: 250.0,
        validFrom: now.subtract(const Duration(days: 1)),
        validUntil: DateTime(2026, 3, 25),
        usageLimit: 200,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      final offer = Offer.fromFirestore(firestoreModel);
      expect(offer.id, 'OFF_999');
      expect(offer.title, 'Special Holi Discount');
      expect(offer.couponCode, 'HOLI2026');
      expect(offer.discountValue, 25.0);
      expect(offer.maximumDiscount, 150.0);
      expect(offer.minimumFare, 250.0);
      expect(offer.discountType, DiscountType.percentage);
    });

    test('FirestorePaymentModel roundtrip serialization and helpers', () {
      final now = DateTime(2026, 9, 15, 12, 0);
      final payment = FirestorePaymentModel(
        paymentId: 'PAY_QR_9901',
        rideId: 'QR_9901',
        userId: 'USER_1001',
        captainId: 'CPT_9981',
        originalFare: 150.0,
        discountAmount: 30.0,
        finalAmount: 120.0,
        currency: 'INR',
        paymentMethod: 'upi',
        paymentStatus: FirestorePaymentStatus.paid,
        gatewayOrderId: 'order_123456',
        gatewayPaymentId: 'pay_123456',
        gatewaySignature: 'sig_abcdef',
        createdAt: now,
        updatedAt: now,
        paidAt: now,
      );

      final map = payment.toMap();
      expect(map['paymentId'], 'PAY_QR_9901');
      expect(map['finalAmount'], 120.0);
      expect(map['paymentStatus'], 'PAID');
      expect(map['paymentMethod'], 'upi');
      expect(map['gatewayOrderId'], 'order_123456');

      final deserialized = FirestorePaymentModel.fromMap(map, id: 'PAY_QR_9901');
      expect(deserialized.paymentId, 'PAY_QR_9901');
      expect(deserialized.finalAmount, 120.0);
      expect(deserialized.paymentStatus, FirestorePaymentStatus.paid);
      expect(deserialized.isPaid, isTrue);
      expect(deserialized.isFailed, isFalse);
      expect(deserialized.isPending, isFalse);
    });

    test('SharedRideModel handles paymentMethod and paymentStatus', () {
      final now = DateTime(2026, 9, 15, 12, 0);
      final ride = SharedRideModel(
        rideId: 'RD-PAY-01',
        userId: 'usr-1',
        captainId: 'cpt-1',
        pickup: 'Koramangala',
        destination: 'Indiranagar',
        pickupLocation: {'lat': 12.9352, 'lng': 77.6245},
        destinationLocation: {'lat': 12.9784, 'lng': 77.6408},
        vehicleType: 'Auto',
        fare: 120.0,
        originalFare: 150.0,
        discountAmount: 30.0,
        paymentMethod: 'online',
        paymentStatus: 'PAID',
        paymentId: 'PAY_RD-PAY-01',
        distance: 6.2,
        estimatedTime: 20,
        status: SharedRideStatus.completed,
        requestedAt: now,
      );

      final map = ride.toMap();
      expect(map['paymentMethod'], 'online');
      expect(map['paymentStatus'], 'PAID');
      expect(map['paymentId'], 'PAY_RD-PAY-01');

      final deserialized = SharedRideModel.fromMap(map, id: 'RD-PAY-01');
      expect(deserialized.paymentMethod, 'online');
      expect(deserialized.paymentStatus, 'PAID');
      expect(deserialized.paymentId, 'PAY_RD-PAY-01');
    });
  });
}
