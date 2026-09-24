import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/models/notification_model.dart';
import 'package:quickride_user/services/notification_service.dart';
import 'package:quickride_user/services/push_notification_service.dart';
import 'package:quickride_user/screens/notifications/notification_screen.dart';

void main() {
  group('Step 46: Advanced Notifications Model & Deduplication Tests', () {
    test('NotificationType fromCode mapping for all Step 46 events', () {
      expect(NotificationType.fromCode('RIDE_ACCEPTED'), NotificationType.captainFound);
      expect(NotificationType.fromCode('CAPTAIN_FOUND'), NotificationType.captainFound);
      expect(NotificationType.fromCode('CAPTAIN_ARRIVED'), NotificationType.captainArriving);
      expect(NotificationType.fromCode('RIDE_STARTED'), NotificationType.rideStarted);
      expect(NotificationType.fromCode('IN_PROGRESS'), NotificationType.rideStarted);
      expect(NotificationType.fromCode('RIDE_COMPLETED'), NotificationType.rideCompleted);
      expect(NotificationType.fromCode('RIDE_CANCELLED'), NotificationType.rideCancelled);
      expect(NotificationType.fromCode('CANCELLED'), NotificationType.rideCancelled);
      expect(NotificationType.fromCode('CHAT_MESSAGE'), NotificationType.chatMessage);
      expect(NotificationType.fromCode('PAYMENT_SUCCESS'), NotificationType.paymentSuccess);
      expect(NotificationType.fromCode('PAYMENT_RECEIVED'), NotificationType.paymentSuccess);
      expect(NotificationType.fromCode('PAYMENT_REFUNDED'), NotificationType.paymentRefunded);
      expect(NotificationType.fromCode('COMPLAINT_STATUS_UPDATE'), NotificationType.supportUpdate);
      expect(NotificationType.fromCode('COMPLAINT_REPLY'), NotificationType.supportUpdate);
      expect(NotificationType.fromCode('EMERGENCY_ALERT'), NotificationType.emergency);
      expect(NotificationType.fromCode('UNKNOWN_CODE'), NotificationType.general);
    });

    test('PushNotificationService event deduplication works reliably', () {
      final service = PushNotificationService();
      const rideId = 'RIDE_TEST_101';
      const eventType = 'RIDE_ACCEPTED';

      // First trigger should be allowed
      final first = service.shouldProcessRideEvent(rideId, eventType);
      expect(first, isTrue);

      // Duplicate immediate trigger should be blocked
      final second = service.shouldProcessRideEvent(rideId, eventType);
      expect(second, isFalse);

      // Different event on same ride should be allowed
      final third = service.shouldProcessRideEvent(rideId, 'CAPTAIN_ARRIVED');
      expect(third, isTrue);

      // Different ride with same event should be allowed
      final fourth = service.shouldProcessRideEvent('RIDE_TEST_102', eventType);
      expect(fourth, isTrue);
    });

    test('PushNotificationService handles tap deep link payload correctly', () {
      final service = PushNotificationService();
      String? tappedRideId;
      String? tappedType;
      Map<String, dynamic>? tappedData;

      service.initialize(
        onNotificationTap: (rideId, type, [data]) {
          tappedRideId = rideId;
          tappedType = type;
          tappedData = data;
        },
      );

      // Invoke internal notification tap
      service.onNotificationTap?.call('RIDE-999', 'CHAT_MESSAGE', {'rideId': 'RIDE-999', 'type': 'CHAT_MESSAGE'});

      expect(tappedRideId, 'RIDE-999');
      expect(tappedType, 'CHAT_MESSAGE');
      expect(tappedData?['rideId'], 'RIDE-999');
    });

    test('NotificationService manages in-app notifications and unread count', () {
      final notifService = NotificationService();
      notifService.resetToDefault();

      final initialCount = notifService.unreadCount;
      expect(initialCount, greaterThan(0));

      final testNotif = AppNotification(
        id: 'test_step46_notif',
        type: NotificationType.chatMessage,
        title: 'New Message from Captain',
        message: 'You have a new message from your captain.',
        createdAt: DateTime.now(),
        isRead: false,
      );

      notifService.addNotification(testNotif);
      expect(notifService.unreadCount, initialCount + 1);

      notifService.markAsRead('test_step46_notif');
      expect(notifService.unreadCount, initialCount);

      notifService.markAllAsRead();
      expect(notifService.unreadCount, 0);
    });
  });

  group('Step 46: User Notification Screen Widget Tests', () {
    testWidgets('NotificationScreen renders title, action buttons, and notification list', (tester) async {
      NotificationService().resetToDefault();

      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsWidgets);
      expect(find.byType(NotificationScreen), findsOneWidget);
      expect(find.text('Mark all as read'), findsOneWidget);
    });

    testWidgets('Tapping Mark all as read updates notification badges', (tester) async {
      NotificationService().resetToDefault();

      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final markAllBtn = find.text('Mark all as read');
      expect(markAllBtn, findsOneWidget);

      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      expect(NotificationService().unreadCount, 0);
    });
  });
}
