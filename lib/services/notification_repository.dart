import "../models/notification_model.dart";

/// Abstract contract for notification management in QuickRide.
///
/// Keeps the storage layer decoupled from the UI, allowing easy replacement
/// with Firebase Cloud Messaging, WebSockets, or a backend API later.
abstract class NotificationRepository {
  /// Returns unmodifiable list of notifications, newest first.
  List<AppNotification> getNotifications();

  /// Adds a new notification to the store.
  void addNotification(AppNotification notification);

  /// Marks a specific notification as read.
  void markAsRead(String id);

  /// Marks all notifications as read.
  void markAllAsRead();

  /// Deletes a specific notification from the store.
  void deleteNotification(String id);

  /// Clears all notifications.
  void clearAll();

  /// Returns the current count of unread notifications.
  int get unreadCount;
}
