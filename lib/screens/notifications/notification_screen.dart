import "package:flutter/material.dart";
import "../../core/constants/app_colors.dart";
import "../../core/constants/app_dimensions.dart";
import "../../models/notification_model.dart";
import "../../services/notification_service.dart";
import "../../services/ride_history_service.dart";
import "../offers/offers_screen.dart";
import "../profile/profile_screen.dart";
import "../ride_history/ride_details_screen.dart";
import "../ride_history/ride_history_screen.dart";
import "../help_support/my_support_requests_screen.dart";
import "../payment/payment_history_screen.dart";
import "../safety/safety_center_screen.dart";
import "widgets/notification_card.dart";

/// STEP 16: Notifications Screen.
///
/// Features:
/// 1. Title "Notifications" with clean Material 3 dark layout.
/// 2. Chronological listing with newest notifications first.
/// 3. Read / unread status distinction.
/// 4. "Mark all as read" action.
/// 5. Swipe-to-delete and delete button on individual notifications.
/// 6. "Clear All" with confirmation dialog ("Clear all notifications?").
/// 7. Empty state: "No notifications" / "You're all caught up!".
/// 8. Type-based navigation (Offers, Profile, Ride History/Details).
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMarkAllAsRead() {
    _notificationService.markAllAsRead();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "All notifications marked as read.",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleClearAll() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Text(
          "Clear all notifications?",
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          "Are you sure you want to clear all notifications? This action cannot be undone.",
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _notificationService.clearAll();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "All notifications cleared.",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.surfaceElevatedDark,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            child: const Text(
              "Clear",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // 1. Mark as read
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // 2. Navigate based on notification context
    switch (notification.type) {
      case NotificationType.offer:
      case NotificationType.discount:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const OffersScreen(),
          ),
        );
        break;

      case NotificationType.account:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ProfileScreen(),
          ),
        );
        break;

      case NotificationType.rideCompleted:
      case NotificationType.rideCancelled:
      case NotificationType.captainFound:
      case NotificationType.captainArriving:
      case NotificationType.rideStarted:
      case NotificationType.rideRequest:
        if (notification.rideId != null) {
          final rideItem = RideHistoryService().findById(notification.rideId!);
          if (rideItem != null) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RideDetailsScreen(ride: rideItem),
              ),
            );
            return;
          }
        }
        // Fallback: if completed rides exist in history, open RideHistoryScreen
        final history = RideHistoryService().getHistory();
        if (history.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const RideHistoryScreen(),
            ),
          );
        }
        break;

      case NotificationType.chatMessage:
        final history = RideHistoryService().getHistory();
        if (history.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const RideHistoryScreen(),
            ),
          );
        }
        break;

      case NotificationType.paymentSuccess:
      case NotificationType.paymentRefunded:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PaymentHistoryScreen(),
          ),
        );
        break;

      case NotificationType.supportUpdate:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MySupportRequestsScreen(),
          ),
        );
        break;

      case NotificationType.emergency:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SafetyCenterScreen(),
          ),
        );
        break;

      case NotificationType.general:
        // No specific screen, already marked read
        break;
    }
  }

  void _handleDeleteNotification(AppNotification notification) {
    _notificationService.deleteNotification(notification.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Notification deleted.",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surfaceElevatedDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.getNotifications();
    final unreadCount = _notificationService.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Back",
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _handleMarkAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text("Mark all as read"),
            ),
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondaryLight,
              ),
              color: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                side: const BorderSide(color: AppColors.borderDark),
              ),
              onSelected: (value) {
                if (value == "clear_all") {
                  _handleClearAll();
                } else if (value == "mark_read") {
                  _handleMarkAllAsRead();
                }
              },
              itemBuilder: (context) => [
                if (unreadCount > 0)
                  const PopupMenuItem(
                    value: "mark_read",
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text("Mark all as read", style: TextStyle(color: AppColors.textPrimaryLight)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: "clear_all",
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text("Clear All", style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? _buildEmptyState()
            : _buildNotificationList(notifications),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
                border: Border.all(
                  color: AppColors.borderDark,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 38,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.space20),
            const Text(
              "No notifications",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
          onDelete: () => _handleDeleteNotification(notification),
        );
      },
    );
  }
}
