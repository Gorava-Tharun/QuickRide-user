import "package:flutter/material.dart";
import "../core/constants/app_colors.dart";

/// Reusable types of notifications supported in QuickRide.
enum NotificationType {
  rideRequest,
  captainFound,
  captainArriving,
  rideStarted,
  rideCompleted,
  rideCancelled,
  chatMessage,
  paymentSuccess,
  paymentRefunded,
  supportUpdate,
  emergency,
  offer,
  discount,
  account,
  general;

  /// String code representation (e.g. 'RIDE_REQUEST', 'CAPTAIN_FOUND').
  String get code {
    switch (this) {
      case NotificationType.rideRequest:
        return "RIDE_REQUEST";
      case NotificationType.captainFound:
        return "CAPTAIN_FOUND";
      case NotificationType.captainArriving:
        return "CAPTAIN_ARRIVING";
      case NotificationType.rideStarted:
        return "RIDE_STARTED";
      case NotificationType.rideCompleted:
        return "RIDE_COMPLETED";
      case NotificationType.rideCancelled:
        return "RIDE_CANCELLED";
      case NotificationType.chatMessage:
        return "CHAT_MESSAGE";
      case NotificationType.paymentSuccess:
        return "PAYMENT_SUCCESS";
      case NotificationType.paymentRefunded:
        return "PAYMENT_REFUNDED";
      case NotificationType.supportUpdate:
        return "SUPPORT_UPDATE";
      case NotificationType.emergency:
        return "EMERGENCY_ALERT";
      case NotificationType.offer:
        return "OFFER";
      case NotificationType.discount:
        return "DISCOUNT";
      case NotificationType.account:
        return "ACCOUNT";
      case NotificationType.general:
        return "GENERAL";
    }
  }

  /// Reconstruct from code string.
  static NotificationType fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case "RIDE_REQUEST":
      case "NEW_RIDE_REQUEST":
        return NotificationType.rideRequest;
      case "CAPTAIN_FOUND":
      case "RIDE_ACCEPTED":
        return NotificationType.captainFound;
      case "CAPTAIN_ARRIVING":
      case "CAPTAIN_ARRIVED":
        return NotificationType.captainArriving;
      case "RIDE_STARTED":
      case "IN_PROGRESS":
        return NotificationType.rideStarted;
      case "RIDE_COMPLETED":
        return NotificationType.rideCompleted;
      case "RIDE_CANCELLED":
      case "CANCELLED":
        return NotificationType.rideCancelled;
      case "CHAT_MESSAGE":
        return NotificationType.chatMessage;
      case "PAYMENT_SUCCESS":
      case "PAYMENT_RECEIVED":
        return NotificationType.paymentSuccess;
      case "PAYMENT_REFUNDED":
        return NotificationType.paymentRefunded;
      case "COMPLAINT_STATUS_UPDATE":
      case "COMPLAINT_REPLY":
      case "NEW_COMPLAINT":
      case "SUPPORT_UPDATE":
        return NotificationType.supportUpdate;
      case "EMERGENCY_ALERT":
      case "EMERGENCY_STATUS":
        return NotificationType.emergency;
      case "OFFER":
        return NotificationType.offer;
      case "DISCOUNT":
        return NotificationType.discount;
      case "ACCOUNT":
        return NotificationType.account;
      default:
        return NotificationType.general;
    }
  }
}

/// Represents an in-app notification in QuickRide.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.rideId,
    this.offerId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? rideId;
  final String? offerId;

  /// Human-friendly relative or formatted time string.
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return "Just now";
    } else if (difference.inMinutes < 60) {
      final min = difference.inMinutes;
      return "$min ${min == 1 ? 'min' : 'min'} ago";
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return "$hrs ${hrs == 1 ? 'hour' : 'hours'} ago";
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return "$days ${days == 1 ? 'day' : 'days'} ago";
    } else {
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${createdAt.day} ${months[createdAt.month - 1]}";
    }
  }

  /// Context-aware icon based on notification type.
  IconData get iconData {
    switch (type) {
      case NotificationType.rideRequest:
        return Icons.local_taxi_rounded;
      case NotificationType.captainFound:
        return Icons.person_pin_rounded;
      case NotificationType.captainArriving:
        return Icons.near_me_rounded;
      case NotificationType.rideStarted:
        return Icons.directions_car_rounded;
      case NotificationType.rideCompleted:
        return Icons.check_circle_rounded;
      case NotificationType.rideCancelled:
        return Icons.cancel_rounded;
      case NotificationType.chatMessage:
        return Icons.chat_bubble_rounded;
      case NotificationType.paymentSuccess:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.paymentRefunded:
        return Icons.currency_exchange_rounded;
      case NotificationType.supportUpdate:
        return Icons.support_agent_rounded;
      case NotificationType.emergency:
        return Icons.warning_amber_rounded;
      case NotificationType.offer:
        return Icons.local_offer_rounded;
      case NotificationType.discount:
        return Icons.percent_rounded;
      case NotificationType.account:
        return Icons.manage_accounts_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  /// Context-aware accent color based on notification type.
  Color get iconColor {
    switch (type) {
      case NotificationType.rideCompleted:
      case NotificationType.paymentSuccess:
        return const Color(0xFF10B981); // Emerald Green
      case NotificationType.rideCancelled:
      case NotificationType.emergency:
        return const Color(0xFFEF4444); // Red
      case NotificationType.chatMessage:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.paymentRefunded:
      case NotificationType.supportUpdate:
        return const Color(0xFF8B5CF6); // Purple
      case NotificationType.captainFound:
      case NotificationType.captainArriving:
      case NotificationType.rideStarted:
        return AppColors.primary; // Gold/Amber
      case NotificationType.offer:
      case NotificationType.discount:
        return AppColors.secondary; // Cyan/Teal
      case NotificationType.account:
        return const Color(0xFF60A5FA); // Blue
      case NotificationType.rideRequest:
        return AppColors.primary;
      case NotificationType.general:
        return AppColors.textPrimaryLight;
    }
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? rideId,
    String? offerId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      rideId: rideId ?? this.rideId,
      offerId: offerId ?? this.offerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type.code,
      "title": title,
      "message": message,
      "createdAt": createdAt.toIso8601String(),
      "isRead": isRead,
      "rideId": rideId,
      "offerId": offerId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json["id"] as String? ?? "notif_unknown",
      type: NotificationType.fromCode(json["type"] as String?),
      title: json["title"] as String? ?? "Notification",
      message: json["message"] as String? ?? "",
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: json["isRead"] as bool? ?? false,
      rideId: json["rideId"] as String?,
      offerId: json["offerId"] as String?,
    );
  }
}
