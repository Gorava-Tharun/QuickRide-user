import "package:flutter/material.dart";
import "../../../core/constants/app_colors.dart";
import "../../../core/constants/app_dimensions.dart";
import "../../../models/notification_model.dart";

/// STEP 16: Modern Material 3 Notification Card.
///
/// Features:
/// - Distinct read/unread visual styling (unread dot, highlighted border, bold title).
/// - Type-specific rounded icon badge.
/// - Relative time label (e.g. "2 min ago").
/// - Swipe-to-dismiss background with delete icon.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.space20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space12),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.surfaceElevatedDark
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.borderDark,
            width: isUnread ? 1.4 : 1.0,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Icon Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: notification.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(
                        color: notification.iconColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      notification.iconData,
                      color: notification.iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),

                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isUnread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: AppColors.textPrimaryLight,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isUnread
                                    ? AppColors.primary
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: isUnread
                                ? AppColors.textPrimaryLight.withValues(alpha: 0.85)
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: onDelete,
                    tooltip: "Delete notification",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
