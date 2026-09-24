import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';
import '../models/notification_model.dart';
import '../models/support_request_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'support_repository.dart';

/// Singleton in-memory & Firestore implementation of [SupportRepository].
///
/// Extends [ChangeNotifier] for reactive updates across the Help & Support UI.
class SupportService extends ChangeNotifier implements SupportRepository {
  SupportService._internal() {
    _seedDemoRequests();
  }

  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;

  final List<SupportRequest> _requests = [];
  int _nextIdCounter = 1002;
  bool _hasSeeded = false;

  void _seedDemoRequests() {
    if (_hasSeeded) return;
    _hasSeeded = true;

    final now = DateTime.now();

    _requests.addAll([
      SupportRequest(
        requestId: 'QR1001',
        userId: 'user_quickride_01',
        rideId: 'QR_101',
        paymentId: 'PAY_QR_101',
        category: SupportCategory.rideIssue,
        issueType: 'Wrong fare',
        subject: 'Toll charged twice on MG Road trip',
        description: 'I was charged for a toll that was already paid in cash during the trip.',
        createdAt: now.subtract(const Duration(hours: 4)),
        status: SupportStatus.open,
        priority: SupportPriority.normal,
      ),
      SupportRequest(
        requestId: 'QR1002_safety',
        userId: 'user_quickride_01',
        rideId: 'QR_102',
        paymentId: 'PAY_QR_102',
        category: SupportCategory.safetyIssue,
        issueType: 'Unsafe driving',
        subject: 'Captain driving aggressively in traffic',
        description: 'The captain was overtaking dangerously near the Whitefield ITPL flyover.',
        createdAt: now.subtract(const Duration(days: 1)),
        status: SupportStatus.inReview,
        priority: SupportPriority.high,
        adminNotes: 'Assigned to senior trust & safety team.',
      ),
    ]);
  }

  /// Generates the next sequential request ID (e.g. "QR1002", "QR1003").
  String generateNextRequestId() {
    final id = 'QR$_nextIdCounter';
    _nextIdCounter++;
    return id;
  }

  /// Real-time stream of complaints for a user
  Stream<List<SupportRequest>> streamUserComplaints(String userId) {
    return QuickRideFirebaseService().streamUserComplaints(userId).map((models) {
      if (models.isEmpty && _requests.isNotEmpty) {
        return getSupportRequests();
      }
      return models.map((m) => SupportRequest.fromFirestore(m)).toList();
    });
  }

  @override
  Future<SupportRequest> createSupportRequest(SupportRequest request) async {
    final finalRequest = request.requestId.isEmpty
        ? request.copyWith(requestId: generateNextRequestId())
        : request;

    _requests.removeWhere((r) => r.requestId == finalRequest.requestId);
    _requests.insert(0, finalRequest);

    // Sync to Firestore
    await QuickRideFirebaseService().createComplaint(finalRequest.toFirestore());

    // Create local notification when support request is submitted
    NotificationService().addNotification(
      AppNotification(
        id: 'notif_support_${finalRequest.requestId}_${DateTime.now().millisecondsSinceEpoch}',
        type: NotificationType.general,
        title: 'Support Request Submitted',
        message: 'Your support request has been submitted successfully.',
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );

    notifyListeners();
    return finalRequest;
  }

  @override
  List<SupportRequest> getSupportRequests() {
    _requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(_requests);
  }

  @override
  SupportRequest? getSupportRequestById(String id) {
    try {
      return _requests.firstWhere((r) => r.requestId == id);
    } catch (_) {
      return null;
    }
  }

  /// Stream conversation replies for a complaint
  Stream<List<FirestoreComplaintReplyModel>> streamReplies(String complaintId) {
    return QuickRideFirebaseService().streamComplaintReplies(complaintId);
  }

  /// Send a reply to an open complaint
  Future<bool> sendReply({
    required String complaintId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    final reply = FirestoreComplaintReplyModel(
      replyId: 'REP_${DateTime.now().millisecondsSinceEpoch}',
      complaintId: complaintId,
      senderId: senderId,
      senderName: senderName,
      senderRole: 'USER',
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    final success = await QuickRideFirebaseService().addComplaintReply(reply);

    // Update local request updatedAt
    final index = _requests.indexWhere((r) => r.requestId == complaintId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(updatedAt: DateTime.now());
    }

    notifyListeners();
    return success;
  }

  @override
  void updateSupportRequestStatus(String id, SupportStatus status) {
    final index = _requests.indexWhere((r) => r.requestId == id);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: status);
      notifyListeners();
    }
  }

  /// Resets support store to initial demo state for testing.
  void resetToDefault() {
    _requests.clear();
    _nextIdCounter = 1002;
    _hasSeeded = false;
    _seedDemoRequests();
    notifyListeners();
  }
}

