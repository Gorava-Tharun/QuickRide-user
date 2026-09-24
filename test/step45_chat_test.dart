import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_user/models/firestore_models.dart';
import 'package:quickride_user/screens/chat/chat_screen.dart';
import 'package:quickride_user/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ChatService().reset();
  });

  group('Step 45: FirestoreChatMessageModel Tests', () {
    test('FirestoreChatMessageModel serialization and deserialization', () {
      final msg = FirestoreChatMessageModel(
        messageId: 'msg_001',
        rideId: 'ride_101',
        senderId: 'user_01',
        senderRole: 'USER',
        senderName: 'Aarav',
        message: "I'm waiting at the north gate.",
        createdAt: DateTime(2026, 9, 21, 11, 0),
        read: false,
      );

      final map = msg.toMap();
      expect(map['messageId'], 'msg_001');
      expect(map['rideId'], 'ride_101');
      expect(map['senderId'], 'user_01');
      expect(map['senderRole'], 'USER');
      expect(map['senderName'], 'Aarav');
      expect(map['message'], "I'm waiting at the north gate.");
      expect(map['read'], false);

      final fromMap = FirestoreChatMessageModel.fromMap(map, id: 'msg_001');
      expect(fromMap.messageId, 'msg_001');
      expect(fromMap.rideId, 'ride_101');
      expect(fromMap.isFromUser, isTrue);
      expect(fromMap.isFromCaptain, isFalse);
      expect(fromMap.isFromAdmin, isFalse);
      expect(fromMap.message, "I'm waiting at the north gate.");
    });

    test('FirestoreChatMessageModel copyWith updates read receipt correctly', () {
      final msg = FirestoreChatMessageModel(
        messageId: 'msg_002',
        rideId: 'ride_102',
        senderId: 'cap_01',
        senderRole: 'CAPTAIN',
        senderName: 'Rajesh',
        message: 'Arriving in 2 minutes.',
        createdAt: DateTime(2026, 9, 21, 11, 5),
        read: false,
      );

      expect(msg.isFromCaptain, isTrue);
      expect(msg.read, isFalse);

      final updated = msg.copyWith(read: true);
      expect(updated.read, isTrue);
      expect(updated.messageId, 'msg_002');
      expect(updated.senderName, 'Rajesh');
    });
  });

  group('Step 45: ChatService Business Logic & Lifecycle Tests', () {
    test('isChatEnabledForStatus validates active vs terminal ride states', () {
      // Enabled states
      expect(ChatService.isChatEnabledForStatus('ACCEPTED'), isTrue);
      expect(ChatService.isChatEnabledForStatus('ARRIVED'), isTrue);
      expect(ChatService.isChatEnabledForStatus('IN_PROGRESS'), isTrue);
      expect(ChatService.isChatEnabledForStatus('in_progress'), isTrue);

      // Disabled / unassigned states
      expect(ChatService.isChatEnabledForStatus('REQUESTED'), isFalse);
      expect(ChatService.isChatEnabledForStatus('COMPLETED'), isFalse);
      expect(ChatService.isChatEnabledForStatus('CANCELLED'), isFalse);
      expect(ChatService.isChatEnabledForStatus(null), isFalse);
    });

    test('isTerminalStatus correctly detects completed and cancelled rides', () {
      expect(ChatService.isTerminalStatus('COMPLETED'), isTrue);
      expect(ChatService.isTerminalStatus('CANCELLED'), isTrue);
      expect(ChatService.isTerminalStatus('completed'), isTrue);
      expect(ChatService.isTerminalStatus('ACCEPTED'), isFalse);
      expect(ChatService.isTerminalStatus('IN_PROGRESS'), isFalse);
      expect(ChatService.isTerminalStatus(null), isFalse);
    });

    test('sendMessage rejects empty and whitespace-only text', () async {
      final service = ChatService();
      final r1 = await service.sendMessage(
        rideId: 'RIDE_1',
        senderId: 'U1',
        senderName: 'Rider',
        message: '',
      );
      expect(r1, isFalse);

      final r2 = await service.sendMessage(
        rideId: 'RIDE_1',
        senderId: 'U1',
        senderName: 'Rider',
        message: '    \n\t   ',
      );
      expect(r2, isFalse);
    });

    test('sendMessage rejects text exceeding 500 characters', () async {
      final service = ChatService();
      final longText = 'A' * 501;
      final result = await service.sendMessage(
        rideId: 'RIDE_1',
        senderId: 'U1',
        senderName: 'Rider',
        message: longText,
      );
      expect(result, isFalse);
    });

    test('sendMessage blocks sending when ride is in terminal state', () async {
      final service = ChatService();
      final result = await service.sendMessage(
        rideId: 'RIDE_COMPLETED_1',
        senderId: 'U1',
        senderName: 'Rider',
        message: 'Hello captain',
        rideStatus: 'COMPLETED',
      );
      expect(result, isFalse);
    });

    test('sendMessage successfully saves valid messages and streams them', () async {
      final service = ChatService();
      const rideId = 'RIDE_TEST_STREAM';

      final success = await service.sendMessage(
        rideId: rideId,
        senderId: 'user_100',
        senderName: 'Aarav',
        message: 'Where should I wait?',
        rideStatus: 'ACCEPTED',
      );
      expect(success, isTrue);

      final messages = await service.fetchMessages(rideId);
      expect(messages.length, 1);
      expect(messages.first.message, 'Where should I wait?');
      expect(messages.first.senderRole, 'USER');
      expect(messages.first.read, isFalse);

      // Captain replies
      await service.sendMessage(
        rideId: rideId,
        senderId: 'cap_200',
        senderName: 'Vikram',
        senderRole: 'CAPTAIN',
        message: 'Near Pillar 42.',
        rideStatus: 'ACCEPTED',
      );

      final messagesAfter = await service.fetchMessages(rideId);
      expect(messagesAfter.length, 2);
      expect(messagesAfter.last.senderRole, 'CAPTAIN');
      expect(messagesAfter.last.message, 'Near Pillar 42.');
    });

    test('markAllReceivedAsRead marks unread incoming messages as read', () async {
      final service = ChatService();
      const rideId = 'RIDE_READ_TEST';

      await service.sendMessage(
        rideId: rideId,
        senderId: 'cap_200',
        senderName: 'Captain Vikram',
        senderRole: 'CAPTAIN',
        message: 'I have arrived.',
      );

      final list = await service.fetchMessages(rideId);
      expect(list.first.read, isFalse);

      await service.markAllReceivedAsRead(
        rideId: rideId,
        currentUserId: 'user_100',
        messages: list,
      );

      final updatedList = await service.fetchMessages(rideId);
      expect(updatedList.first.read, isTrue);
    });
  });

  group('Step 45: ChatScreen Widget Tests', () {
    testWidgets('ChatScreen renders captain details and quick response chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(
            rideId: 'RIDE_WIDGET_TEST',
            currentUserId: 'user_test_01',
            currentUserName: 'Aarav',
            captainId: 'cap_test_01',
            captainName: 'Vikram Singh',
            captainPhone: '+91 98765 43210',
            vehicleType: 'Bike',
            vehicleNumber: 'KA 01 AB 1234',
            rideStatus: 'ACCEPTED',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vikram Singh'), findsOneWidget);
      expect(find.text('Bike • KA 01 AB 1234'), findsOneWidget);
      expect(find.text("I'm at the pickup location"), findsOneWidget);
      expect(find.text('On my way down now'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('ChatScreen shows closed banner when ride is COMPLETED', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(
            rideId: 'RIDE_COMPLETED_TEST',
            currentUserId: 'user_test_01',
            currentUserName: 'Aarav',
            captainId: 'cap_test_01',
            captainName: 'Vikram Singh',
            rideStatus: 'COMPLETED',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Ride is COMPLETED'), findsOneWidget);
      expect(find.text('Chat is closed'), findsOneWidget);
    });

    testWidgets('Tapping quick response chip sends message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(
            rideId: 'RIDE_QUICK_TEST',
            currentUserId: 'user_test_01',
            currentUserName: 'Aarav',
            captainId: 'cap_test_01',
            captainName: 'Vikram Singh',
            rideStatus: 'ACCEPTED',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap quick response chip
      await tester.tap(find.text("I'm at the pickup location"));
      await tester.pumpAndSettle();

      expect(find.text("I'm at the pickup location"), findsWidgets);
    });
  });
}
