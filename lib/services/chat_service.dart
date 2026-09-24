import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';
import 'firebase_service.dart';

/// Real-time chat service managing message delivery, read receipts, and lifecycle checks.
class ChatService extends ChangeNotifier {
  ChatService._internal();

  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  /// Validates whether chat is active for the current ride lifecycle status.
  /// Allowed during: ACCEPTED, ARRIVED, IN_PROGRESS.
  /// Blocked during: REQUESTED, COMPLETED, CANCELLED.
  static bool isChatEnabledForStatus(String? status) {
    if (status == null) return false;
    final s = status.toUpperCase().replaceAll(' ', '_');
    return s == 'ACCEPTED' || s == 'ARRIVED' || s == 'IN_PROGRESS';
  }

  /// Check if ride is in terminal state
  static bool isTerminalStatus(String? status) {
    if (status == null) return false;
    final s = status.toUpperCase().replaceAll(' ', '_');
    return s == 'COMPLETED' || s == 'CANCELLED';
  }

  /// Streams real-time chat messages for a ride ordered by timestamp ascending
  Stream<List<FirestoreChatMessageModel>> streamMessages(String rideId) {
    return QuickRideFirebaseService().streamChatMessages(rideId);
  }

  /// Fetches one-time list of messages
  Future<List<FirestoreChatMessageModel>> fetchMessages(String rideId) {
    return QuickRideFirebaseService().fetchChatMessages(rideId);
  }

  /// Sends a new message in the ride chat conversation
  Future<bool> sendMessage({
    required String rideId,
    required String senderId,
    required String senderName,
    required String message,
    String senderRole = 'USER',
    String? rideStatus,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      debugPrint('[ChatService] Cannot send empty message');
      return false;
    }

    if (trimmed.length > 500) {
      debugPrint('[ChatService] Message exceeds 500 character limit');
      return false;
    }

    // Gating: If rideStatus provided and terminal, prevent sending
    if (rideStatus != null && isTerminalStatus(rideStatus)) {
      debugPrint('[ChatService] Chat is closed for status $rideStatus');
      return false;
    }

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${senderId.hashCode.abs().toString().padLeft(4, '0')}';
    final chatMessage = FirestoreChatMessageModel(
      messageId: messageId,
      rideId: rideId,
      senderId: senderId,
      senderRole: senderRole.toUpperCase(),
      senderName: senderName,
      message: trimmed,
      createdAt: DateTime.now(),
      read: false,
    );

    final success = await QuickRideFirebaseService().sendChatMessage(chatMessage);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Marks a specific message as read
  Future<bool> markAsRead(String rideId, String messageId) async {
    return QuickRideFirebaseService().markChatMessageAsRead(rideId, messageId);
  }

  /// Marks all unread messages from opposite party as read
  Future<void> markAllReceivedAsRead({
    required String rideId,
    required String currentUserId,
    required List<FirestoreChatMessageModel> messages,
  }) async {
    for (final msg in messages) {
      if (!msg.read && msg.senderId != currentUserId) {
        await markAsRead(rideId, msg.messageId);
      }
    }
  }

  /// Resets mock/in-memory messages (for testing)
  void reset([String? rideId]) {
    QuickRideFirebaseService().clearLocalChatMessages(rideId);
    notifyListeners();
  }
}
