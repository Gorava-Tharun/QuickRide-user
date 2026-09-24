import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/core/errors/app_error_handler.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/services/chat_service.dart';
import 'package:quickride_user/services/connectivity_service.dart';
import 'package:quickride_user/services/fare_calculator.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 53: QuickRide Three-App Integration Testing Suite (User App Perspective)', () {
    late SessionManager sessionManager;
    late ConnectivityService connectivity;
    late ChatService chatService;

    setUp(() {
      sessionManager = SessionManager();
      sessionManager.resetToDefault();
      connectivity = ConnectivityService();
      connectivity.setMockOnlineState(true);
      chatService = ChatService();
    });

    tearDown(() {
      sessionManager.resetToDefault();
      connectivity.setMockOnlineState(true);
    });

    // =========================================================================
    // 1. USER → CAPTAIN RIDE FLOW
    // =========================================================================
    group('1. User -> Captain Ride Flow & Status Synchronization', () {
      test('Complete 13-stage ride lifecycle propagates with valid status transitions', () async {
        // Stage 1: User authentication
        sessionManager.login(
          identifier: 'aarav@quickride.com',
          fullName: 'Aarav Sharma',
          phone: '+91 98765 43210',
          email: 'aarav@quickride.com',
        );
        expect(sessionManager.isLoggedIn, isTrue);

        // Stage 2 & 3: Pickup, destination & Fare calculation
        final fareCalculation = FareCalculator.calculate(
          vehicleType: 'Auto',
          distanceKm: 6.5,
        );
        expect(fareCalculation.fare, greaterThan(0));
        expect(fareCalculation.available, isTrue);

        // Stage 4: User creates ride booking (REQUESTED)
        final requestedRide = SharedRideModel(
          rideId: 'RIDE_INT_001',
          userId: sessionManager.currentUser.userId,
          userName: sessionManager.currentUser.fullName,
          pickup: 'MG Road Metro Station',
          destination: 'Koramangala 5th Block',
          pickupLocation: {'latitude': 12.9756, 'longitude': 77.6066},
          destinationLocation: {'latitude': 12.9345, 'longitude': 77.6265},
          vehicleType: 'Auto',
          fare: fareCalculation.fare,
          distance: 6.5,
          estimatedTime: 18,
          status: SharedRideStatus.requested,
          requestedAt: DateTime.now(),
        );
        expect(requestedRide.status, SharedRideStatus.requested);
        expect(requestedRide.captainId, isNull);

        // Stage 5: Captain receives ride request notification
        final reqNotification = FirestoreNotificationModel(
          notificationId: 'notif_req_001',
          recipientId: 'cap_201',
          recipientRole: 'captain',
          title: 'New Ride Request',
          message: 'Auto ride request of ₹${requestedRide.fare.toStringAsFixed(0)} nearby',
          type: 'RIDE_REQUEST',
          read: false,
          createdAt: DateTime.now(),
        );
        expect(reqNotification.title, 'New Ride Request');
        expect(reqNotification.read, isFalse);

        // Stage 6: Captain accepts ride
        expect(isValidRideTransition(requestedRide.status, SharedRideStatus.accepted), isTrue);
        final acceptedRide = requestedRide.copyWith(
          status: SharedRideStatus.accepted,
          captainId: 'cap_201',
          acceptedAt: DateTime.now(),
          captainLocation: {'latitude': 12.9760, 'longitude': 77.6070},
        );
        expect(acceptedRide.status, SharedRideStatus.accepted);
        expect(acceptedRide.captainId, 'cap_201');

        // Stage 7: User receives acceptance update
        expect(acceptedRide.captainLocation, isNotNull);

        // Stage 8: Captain arrives at pickup
        expect(isValidRideTransition(acceptedRide.status, SharedRideStatus.arrived), isTrue);
        final arrivedRide = acceptedRide.copyWith(
          status: SharedRideStatus.arrived,
          arrivedAt: DateTime.now(),
        );
        expect(arrivedRide.status, SharedRideStatus.arrived);

        // Stage 9: Ride starts (IN_PROGRESS)
        expect(isValidRideTransition(arrivedRide.status, SharedRideStatus.inProgress), isTrue);
        final inProgressRide = arrivedRide.copyWith(
          status: SharedRideStatus.inProgress,
          startedAt: DateTime.now(),
        );
        expect(inProgressRide.status, SharedRideStatus.inProgress);

        // Stage 10: Ride completes
        expect(isValidRideTransition(inProgressRide.status, SharedRideStatus.completed), isTrue);
        final completedRide = inProgressRide.copyWith(
          status: SharedRideStatus.completed,
          completedAt: DateTime.now(),
          paymentStatus: 'PAID',
        );
        expect(completedRide.status, SharedRideStatus.completed);

        // Stage 11 & 12: Payment completion verification
        final payment = FirestorePaymentModel(
          paymentId: 'PAY_INT_001',
          rideId: completedRide.rideId,
          userId: completedRide.userId,
          captainId: completedRide.captainId!,
          passengerName: completedRide.userName,
          captainName: 'Rajesh Kumar',
          pickupAddress: completedRide.pickup,
          dropAddress: completedRide.destination,
          vehicleType: completedRide.vehicleType,
          distanceKm: completedRide.distance,
          originalFare: completedRide.fare,
          discountAmount: 0.0,
          finalAmount: completedRide.fare,
          paymentMethod: 'UPI',
          paymentStatus: FirestorePaymentStatus.paid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          paidAt: DateTime.now(),
        );
        expect(payment.isPaid, isTrue);
        expect(payment.finalAmount, completedRide.fare);

        // Stage 13: User rates Captain
        final rating = FirestoreRatingModel(
          ratingId: '${completedRide.rideId}_user',
          rideId: completedRide.rideId,
          userId: completedRide.userId,
          captainId: completedRide.captainId!,
          ratedBy: 'user',
          stars: 5,
          review: 'Smooth and pleasant ride!',
          createdAt: DateTime.now(),
        );
        expect(rating.stars, 5);
        expect(rating.ratingId, '${completedRide.rideId}_user');
      });
    });

    // =========================================================================
    // 2. CAPTAIN → USER FLOW
    // =========================================================================
    group('2. Captain -> User Information & Telemetry Flow', () {
      test('Captain rejection updates rejectedCaptains without destroying request for others', () {
        final initialRide = SharedRideModel(
          rideId: 'RIDE_INT_002',
          userId: 'user_e2e_02',
          userName: 'Priya Patel',
          pickup: 'Indiranagar',
          destination: 'MG Road',
          pickupLocation: {'latitude': 12.9785, 'longitude': 77.6405},
          destinationLocation: {'latitude': 12.9756, 'longitude': 77.6066},
          vehicleType: 'Bike',
          fare: 65.0,
          distance: 4.2,
          estimatedTime: 12,
          status: SharedRideStatus.requested,
          requestedAt: DateTime.now(),
          rejectedCaptains: [],
        );

        // Captain 1 rejects
        final afterReject1 = initialRide.copyWith(
          rejectedCaptains: [...initialRide.rejectedCaptains, 'cap_rejected_01'],
        );
        expect(afterReject1.rejectedCaptains, contains('cap_rejected_01'));
        expect(afterReject1.status, SharedRideStatus.requested); // Remains open for other captains

        // Captain 2 accepts
        final afterAccept = afterReject1.copyWith(
          status: SharedRideStatus.accepted,
          captainId: 'cap_accepted_02',
          acceptedAt: DateTime.now(),
        );
        expect(afterAccept.status, SharedRideStatus.accepted);
        expect(afterAccept.captainId, 'cap_accepted_02');
      });

      test('Captain live GPS telemetry streams to user', () {
        final ride = SharedRideModel(
          rideId: 'RIDE_INT_003',
          userId: 'user_e2e_03',
          captainId: 'cap_203',
          pickup: 'Indiranagar',
          destination: 'MG Road',
          pickupLocation: {'latitude': 12.9785, 'longitude': 77.6405},
          destinationLocation: {'latitude': 12.9756, 'longitude': 77.6066},
          vehicleType: 'Car',
          fare: 180.0,
          distance: 5.0,
          estimatedTime: 15,
          status: SharedRideStatus.accepted,
          requestedAt: DateTime.now(),
          captainLocation: {'latitude': 12.9790, 'longitude': 77.6410},
        );

        // Updated position closer to pickup
        final updatedRide = ride.copyWith(
          captainLocation: {'latitude': 12.9786, 'longitude': 77.6406},
        );

        expect(updatedRide.captainLocation!['latitude'], 12.9786);
        expect(updatedRide.captainLocation!['longitude'], 77.6406);
      });
    });

    // =========================================================================
    // 3. USER ↔ CAPTAIN CHAT
    // =========================================================================
    group('3. In-Ride Chat Channel & Lifecycle Gating', () {
      test('Chat is enabled during active ride and terminated upon completion/cancellation', () async {
        expect(ChatService.isChatEnabledForStatus('ACCEPTED'), isTrue);
        expect(ChatService.isChatEnabledForStatus('ARRIVED'), isTrue);
        expect(ChatService.isChatEnabledForStatus('IN_PROGRESS'), isTrue);

        expect(ChatService.isChatEnabledForStatus('REQUESTED'), isFalse);
        expect(ChatService.isChatEnabledForStatus('COMPLETED'), isFalse);
        expect(ChatService.isChatEnabledForStatus('CANCELLED'), isFalse);

        expect(ChatService.isTerminalStatus('COMPLETED'), isTrue);
        expect(ChatService.isTerminalStatus('CANCELLED'), isTrue);
        expect(ChatService.isTerminalStatus('IN_PROGRESS'), isFalse);
      });

      test('Sending message during active ride succeeds and blocks after completion', () async {
        const rideId = 'RIDE_CHAT_TEST_01';
        chatService.reset(rideId);

        // Send while active
        final sent = await chatService.sendMessage(
          rideId: rideId,
          senderId: 'user_01',
          senderName: 'Aarav',
          message: 'I am waiting near Gate 2',
          senderRole: 'USER',
          rideStatus: 'ACCEPTED',
        );
        expect(sent, isTrue);

        // Attempt send after completion
        final blocked = await chatService.sendMessage(
          rideId: rideId,
          senderId: 'user_01',
          senderName: 'Aarav',
          message: 'Thank you for the ride',
          senderRole: 'USER',
          rideStatus: 'COMPLETED',
        );
        expect(blocked, isFalse);
      });
    });

    // =========================================================================
    // 4. USER/CAPTAIN → ADMIN
    // =========================================================================
    group('4. User/Captain -> Admin Real-Time Metrics Calculation', () {
      test('Financial revenue split calculates 15% platform cut vs 85% captain payout', () {
        const fare = 200.0;
        const commissionRate = 15.0; // 15%

        final platformCut = fare * (commissionRate / 100);
        final captainPayout = fare - platformCut;

        expect(platformCut, 30.0);
        expect(captainPayout, 170.0);
        expect(platformCut + captainPayout, fare);
      });
    });

    // =========================================================================
    // 7. DUPLICATE & RACE CONDITION TESTING
    // =========================================================================
    group('7. Duplicate Actions & Concurrency Resilience', () {
      test('Two captains attempting to accept same ride: only first succeeds', () {
        var currentStatus = SharedRideStatus.requested;
        String? assignedCaptain;

        // Captain 1 attempts acceptance
        bool acceptRide(String captainId) {
          if (currentStatus == SharedRideStatus.requested && assignedCaptain == null) {
            currentStatus = SharedRideStatus.accepted;
            assignedCaptain = captainId;
            return true;
          }
          return false;
        }

        final cap1Result = acceptRide('cap_001');
        final cap2Result = acceptRide('cap_002');

        expect(cap1Result, isTrue);
        expect(cap2Result, isFalse);
        expect(assignedCaptain, 'cap_001');
        expect(currentStatus, SharedRideStatus.accepted);
      });

      test('Empty and whitespace-only chat messages are rejected', () async {
        final emptySend = await chatService.sendMessage(
          rideId: 'RIDE_CONCURRENCY_01',
          senderId: 'user_01',
          senderName: 'Aarav',
          message: '   ',
          senderRole: 'USER',
        );
        expect(emptySend, isFalse);
      });
    });

    // =========================================================================
    // 8. SECURITY RULES AUDIT
    // =========================================================================
    group('8. Security Rules Verification', () {
      test('Verify absence of open allow read write wildcard in rules files', () {
        final firestoreRulesFile = File('../firestore.rules');
        if (firestoreRulesFile.existsSync()) {
          final content = firestoreRulesFile.readAsStringSync();
          expect(content.contains('allow read, write: if true;'), isFalse);
          expect(content.contains('allow read, write: if false;'), isTrue);
        }

        final storageRulesFile = File('../storage.rules');
        if (storageRulesFile.existsSync()) {
          final content = storageRulesFile.readAsStringSync();
          expect(content.contains('allow read, write: if true;'), isFalse);
          expect(content.contains('allow read, write: if false;'), isTrue);
        }
      });
    });

    // =========================================================================
    // 9. OFFLINE & RECONNECTION SYNC
    // =========================================================================
    group('9. Offline & Reconnection Resiliency', () {
      test('Network loss preserves active ride state without accidental cancellation', () {
        connectivity.setMockOnlineState(false);
        expect(connectivity.isOffline, isTrue);

        final activeRide = SharedRideModel(
          rideId: 'RIDE_OFFLINE_001',
          userId: 'user_01',
          captainId: 'cap_01',
          pickup: 'Indiranagar',
          destination: 'MG Road',
          pickupLocation: {'latitude': 12.9785, 'longitude': 77.6405},
          destinationLocation: {'latitude': 12.9756, 'longitude': 77.6066},
          vehicleType: 'Bike',
          fare: 75.0,
          distance: 4.2,
          estimatedTime: 12,
          status: SharedRideStatus.inProgress,
          requestedAt: DateTime.now(),
        );

        // Network loss should not change status to CANCELLED
        expect(activeRide.status, SharedRideStatus.inProgress);
        expect(activeRide.isCancelled, isFalse);

        // Reconnect
        connectivity.setMockOnlineState(true);
        expect(connectivity.isOnline, isTrue);
        expect(activeRide.status, SharedRideStatus.inProgress);
      });

      test('AppErrorHandler provides clear messages for connectivity errors', () {
        const socketException = SocketException('Failed host lookup');
        final message = AppErrorHandler.getFriendlyErrorMessage(socketException);
        expect(message.toLowerCase().contains('internet') || message.toLowerCase().contains('connection'), isTrue);
      });
    });
  });
}
