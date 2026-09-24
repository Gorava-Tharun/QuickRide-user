import "package:flutter/foundation.dart";
import "../models/notification_model.dart";
import "notification_repository.dart";

/// Singleton in-memory implementation of [NotificationRepository].
///
/// Extends [ChangeNotifier] so UI widgets (such as the Home Screen badge)
/// can listen to notification events reactively.
class NotificationService extends ChangeNotifier implements NotificationRepository {
  NotificationService._internal() {
    _seedDemoNotifications();
  }

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final List<AppNotification> _notifications = [];
  bool _hasSeeded = false;

  void _seedDemoNotifications() {
    if (_hasSeeded) return;
    _hasSeeded = true;

    final now = DateTime.now();

    _notifications.addAll([
      AppNotification(
        id: "notif_01_captain_found",
        type: NotificationType.captainFound,
        title: "Captain Found",
        message: "Your QuickRide captain Rajesh Kumar has been assigned.",
        createdAt: now.subtract(const Duration(minutes: 2)),
        isRead: false,
      ),
      AppNotification(
        id: "notif_02_captain_arrived",
        type: NotificationType.captainArriving,
        title: "Captain Arrived",
        message: "Your captain has reached the pickup location.",
        createdAt: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      AppNotification(
        id: "notif_03_ride_completed",
        type: NotificationType.rideCompleted,
        title: "Ride Completed",
        message: "Your ride has been completed successfully. Thank you for riding with QuickRide!",
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      AppNotification(
        id: "notif_04_new_offer",
        type: NotificationType.offer,
        title: "New Offer Available",
        message: "Check out the latest QuickRide offers — Save up to 50% on rides!",
        createdAt: now.subtract(const Duration(hours: 3)),
        offerId: "offer_save50",
        isRead: false,
      ),
      AppNotification(
        id: "notif_05_welcome",
        type: NotificationType.general,
        title: "Welcome to QuickRide",
        message: "Your ride, your way. Enjoy fast, reliable, and comfortable city travel.",
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]);
  }

  @override
  List<AppNotification> getNotifications() {
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(_notifications);
  }

  @override
  void addNotification(AppNotification notification) {
    // Avoid duplicate IDs
    _notifications.removeWhere((n) => n.id == notification.id);
    _notifications.insert(0, notification);
    notifyListeners();
  }

  @override
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  @override
  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  @override
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  @override
  void clearAll() {
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      notifyListeners();
    }
  }

  @override
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Resets notification store to initial demo state (useful in unit/widget tests).
  void resetToDefault() {
    _notifications.clear();
    _hasSeeded = false;
    _seedDemoNotifications();
    notifyListeners();
  }
}
