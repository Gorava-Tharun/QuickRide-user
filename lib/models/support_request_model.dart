import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'firestore_models.dart';

/// Categories of customer support issues in QuickRide.
enum SupportCategory {
  rideIssue,
  captainIssue,
  paymentIssue,
  pickupDestinationIssue,
  offerCouponIssue,
  accountIssue,
  safetyIssue,
  lostItem,
  other;

  /// Display title for the category.
  String get title {
    switch (this) {
      case SupportCategory.rideIssue:
        return 'Ride Issue';
      case SupportCategory.captainIssue:
        return 'Captain Issue';
      case SupportCategory.paymentIssue:
        return 'Payment Issue';
      case SupportCategory.pickupDestinationIssue:
        return 'Pickup / Destination Issue';
      case SupportCategory.offerCouponIssue:
        return 'Offer / Coupon Issue';
      case SupportCategory.accountIssue:
        return 'Account Issue';
      case SupportCategory.safetyIssue:
        return 'Safety Issue';
      case SupportCategory.lostItem:
        return 'Lost Item';
      case SupportCategory.other:
        return 'Other';
    }
  }

  /// Icon representing the category.
  IconData get icon {
    switch (this) {
      case SupportCategory.rideIssue:
        return Icons.local_taxi_rounded;
      case SupportCategory.captainIssue:
        return Icons.person_pin_rounded;
      case SupportCategory.paymentIssue:
        return Icons.payment_rounded;
      case SupportCategory.pickupDestinationIssue:
        return Icons.place_rounded;
      case SupportCategory.offerCouponIssue:
        return Icons.local_offer_rounded;
      case SupportCategory.accountIssue:
        return Icons.manage_accounts_rounded;
      case SupportCategory.safetyIssue:
        return Icons.shield_rounded;
      case SupportCategory.lostItem:
        return Icons.inventory_2_rounded;
      case SupportCategory.other:
        return Icons.help_outline_rounded;
    }
  }

  /// Color accent for category icon.
  Color get accentColor {
    switch (this) {
      case SupportCategory.safetyIssue:
        return const Color(0xFFEF4444); // Red
      case SupportCategory.paymentIssue:
        return const Color(0xFF10B981); // Emerald
      case SupportCategory.rideIssue:
        return AppColors.primary; // Gold
      case SupportCategory.captainIssue:
        return const Color(0xFF60A5FA); // Blue
      case SupportCategory.offerCouponIssue:
        return AppColors.secondary; // Cyan
      case SupportCategory.pickupDestinationIssue:
        return const Color(0xFFF59E0B); // Amber
      case SupportCategory.accountIssue:
        return const Color(0xFFA78BFA); // Purple
      case SupportCategory.lostItem:
        return const Color(0xFFFB923C); // Orange
      case SupportCategory.other:
        return AppColors.textSecondaryLight;
    }
  }

  /// Reconstruct from string value.
  static SupportCategory fromString(String? val) {
    if (val == null) return SupportCategory.other;
    final normalized = val.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    return SupportCategory.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.title.toLowerCase() == val.toLowerCase() ||
          e.name.toLowerCase().replaceAll('_', '') == normalized,
      orElse: () => SupportCategory.other,
    );
  }
}

/// Priority level for customer support requests.
enum SupportPriority {
  low,
  normal,
  high,
  urgent;

  String get code {
    switch (this) {
      case SupportPriority.low:
        return 'LOW';
      case SupportPriority.normal:
        return 'NORMAL';
      case SupportPriority.high:
        return 'HIGH';
      case SupportPriority.urgent:
        return 'URGENT';
    }
  }

  String get label {
    switch (this) {
      case SupportPriority.low:
        return 'Low';
      case SupportPriority.normal:
        return 'Normal';
      case SupportPriority.high:
        return 'High';
      case SupportPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case SupportPriority.low:
        return const Color(0xFF9CA3AF);
      case SupportPriority.normal:
        return const Color(0xFF3B82F6);
      case SupportPriority.high:
        return const Color(0xFFF59E0B);
      case SupportPriority.urgent:
        return const Color(0xFFEF4444);
    }
  }

  static SupportPriority fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'LOW':
        return SupportPriority.low;
      case 'HIGH':
        return SupportPriority.high;
      case 'URGENT':
        return SupportPriority.urgent;
      case 'NORMAL':
      default:
        return SupportPriority.normal;
    }
  }
}

/// Lifecycle status for a submitted support request.
enum SupportStatus {
  open,
  inReview,
  inProgress,
  resolved,
  closed;

  /// String code matching prompt specs (OPEN, IN_REVIEW, RESOLVED, CLOSED).
  String get code {
    switch (this) {
      case SupportStatus.open:
        return 'OPEN';
      case SupportStatus.inReview:
        return 'IN_REVIEW';
      case SupportStatus.inProgress:
        return 'IN_PROGRESS';
      case SupportStatus.resolved:
        return 'RESOLVED';
      case SupportStatus.closed:
        return 'CLOSED';
    }
  }

  /// Human-friendly display label.
  String get label {
    switch (this) {
      case SupportStatus.open:
        return 'Open';
      case SupportStatus.inReview:
      case SupportStatus.inProgress:
        return 'In Review';
      case SupportStatus.resolved:
        return 'Resolved';
      case SupportStatus.closed:
        return 'Closed';
    }
  }

  /// Badge background color.
  Color get badgeColor {
    switch (this) {
      case SupportStatus.open:
        return AppColors.primary;
      case SupportStatus.inReview:
      case SupportStatus.inProgress:
        return const Color(0xFF3B82F6); // Blue
      case SupportStatus.resolved:
        return const Color(0xFF10B981); // Green
      case SupportStatus.closed:
        return const Color(0xFF6B7280); // Gray
    }
  }

  /// Reconstruct from code string.
  static SupportStatus fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'IN_REVIEW':
      case 'IN_PROGRESS':
        return SupportStatus.inReview;
      case 'RESOLVED':
        return SupportStatus.resolved;
      case 'CLOSED':
        return SupportStatus.closed;
      case 'OPEN':
      default:
        return SupportStatus.open;
    }
  }
}

/// Represents a customer support inquiry or reported issue.
class SupportRequest {
  const SupportRequest({
    required this.requestId,
    required this.userId,
    this.rideId,
    this.paymentId,
    this.attachmentUrl,
    required this.category,
    required this.issueType,
    String? subject,
    required this.description,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.status = SupportStatus.open,
    this.priority = SupportPriority.normal,
    this.resolutionSummary,
    this.adminNotes,
  }) : subject = subject ?? issueType;

  final String requestId;
  final String userId;
  final String? rideId;
  final String? paymentId;
  final String? attachmentUrl;
  final SupportCategory category;
  final String issueType;
  final String subject;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final SupportStatus status;
  final SupportPriority priority;
  final String? resolutionSummary;
  final String? adminNotes;

  /// Formatted date string (e.g. "10 Sep 2026, 04:30 PM").
  String get formattedCreatedAt {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = months[createdAt.month - 1];
    final year = createdAt.year;
    final hour = createdAt.hour > 12 ? createdAt.hour - 12 : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour:$minute $period';
  }

  SupportRequest copyWith({
    String? requestId,
    String? userId,
    String? rideId,
    String? paymentId,
    String? attachmentUrl,
    SupportCategory? category,
    String? issueType,
    String? subject,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    SupportStatus? status,
    SupportPriority? priority,
    String? resolutionSummary,
    String? adminNotes,
  }) {
    return SupportRequest(
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      rideId: rideId ?? this.rideId,
      paymentId: paymentId ?? this.paymentId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      category: category ?? this.category,
      issueType: issueType ?? this.issueType,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      resolutionSummary: resolutionSummary ?? this.resolutionSummary,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'userId': userId,
      'rideId': rideId,
      'paymentId': paymentId,
      'attachmentUrl': attachmentUrl,
      'category': category.name,
      'issueType': issueType,
      'subject': subject,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'status': status.code,
      'priority': priority.code,
      'resolutionSummary': resolutionSummary,
      'adminNotes': adminNotes,
    };
  }

  factory SupportRequest.fromJson(Map<String, dynamic> json) {
    return SupportRequest(
      requestId: json['requestId'] as String? ?? 'QR1001',
      userId: json['userId'] as String? ?? 'user_default',
      rideId: json['rideId'] as String?,
      paymentId: json['paymentId'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      category: SupportCategory.fromString(json['category'] as String?),
      issueType: json['issueType'] as String? ?? 'General Inquiry',
      subject: json['subject'] as String? ?? (json['issueType'] as String? ?? 'General Inquiry'),
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
      status: SupportStatus.fromCode(json['status'] as String?),
      priority: SupportPriority.fromCode(json['priority'] as String?),
      resolutionSummary: json['resolutionSummary'] as String?,
      adminNotes: json['adminNotes'] as String?,
    );
  }

  FirestoreComplaintModel toFirestore() {
    return FirestoreComplaintModel(
      complaintId: requestId,
      userId: userId,
      complainantRole: 'USER',
      category: category.name,
      subject: subject,
      description: description,
      rideId: rideId,
      paymentId: paymentId,
      attachmentUrl: attachmentUrl,
      status: status.code,
      priority: priority.code,
      adminNotes: adminNotes,
      resolutionSummary: resolutionSummary,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolvedAt: resolvedAt,
    );
  }

  factory SupportRequest.fromFirestore(FirestoreComplaintModel model) {
    return SupportRequest(
      requestId: model.complaintId,
      userId: model.userId ?? '',
      rideId: model.rideId,
      paymentId: model.paymentId,
      attachmentUrl: model.attachmentUrl,
      category: SupportCategory.fromString(model.category),
      issueType: model.subject,
      subject: model.subject,
      description: model.description,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      resolvedAt: model.resolvedAt,
      status: SupportStatus.fromCode(model.status),
      priority: SupportPriority.fromCode(model.priority),
      resolutionSummary: model.resolutionSummary,
      adminNotes: model.adminNotes,
    );
  }
}

/// Model representing an FAQ question and answer.
class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.keywords,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final String question;
  final String answer;
  final String category;
  final List<String> keywords;
  final String? actionLabel;
  final String? actionRoute;

  /// Default 8 QuickRide FAQs matching STEP 17 specification.
  static const List<FaqItem> defaultFaqs = [
    FaqItem(
      id: 'faq_book',
      question: 'How do I book a ride?',
      answer:
          'Set your pickup location and destination on the Home screen. Choose your preferred vehicle (Bike, Auto, Economy, Comfort, or Premium), review the upfront fare estimate, pick your payment method, and tap "Confirm Booking". We will match you with the nearest captain immediately.',
      category: 'Ride',
      keywords: ['book', 'ride', 'request', 'start', 'how to'],
    ),
    FaqItem(
      id: 'faq_cancel',
      question: 'How do I cancel a ride?',
      answer:
          'You can cancel your ride before the captain arrives by tapping the "Cancel Ride" button on the Finding Captain or Ride Tracking screen. Please select a cancellation reason to help us improve our service.',
      category: 'Cancellation',
      keywords: ['cancel', 'cancellation', 'stop', 'abort', 'ride'],
    ),
    FaqItem(
      id: 'faq_fare',
      question: 'How is my fare calculated?',
      answer:
          'QuickRide fares are calculated transparently based on your selected vehicle category base fare, per-kilometer distance, estimated trip duration, and any applicable promotional discounts or coupons.',
      category: 'Payment',
      keywords: ['fare', 'price', 'cost', 'calculate', 'money', 'payment'],
    ),
    FaqItem(
      id: 'faq_pickup',
      question: 'How do I change my pickup location?',
      answer:
          'Tap on the pickup location bar on the Home screen to search for a new landmark or move the pin on the interactive map. For safety, pickup locations cannot be modified after the captain has started heading to you.',
      category: 'Ride',
      keywords: ['pickup', 'location', 'change', 'address', 'pin'],
    ),
    FaqItem(
      id: 'faq_destination',
      question: 'How do I change my destination?',
      answer:
          'You can change your destination on the Home screen before confirming your ride by tapping the destination input bar. To update during an ongoing trip, kindly inform your captain.',
      category: 'Ride',
      keywords: ['destination', 'drop', 'change', 'location', 'address'],
    ),
    FaqItem(
      id: 'faq_rating',
      question: 'How can I rate my captain?',
      answer:
          'Once your ride is completed, a rating screen will appear allowing you to award 1 to 5 stars, select quick feedback tags (e.g., Clean Vehicle, Friendly Captain), and leave an optional review comment.',
      category: 'Captain',
      keywords: ['rate', 'rating', 'captain', 'review', 'stars', 'feedback'],
    ),
    FaqItem(
      id: 'faq_history',
      question: 'Where can I see my previous rides?',
      answer:
          'Navigate to "My Rides" from the bottom navigation bar or from your Profile screen to see a full chronological history of all your completed and cancelled trips, along with invoices and route maps.',
      category: 'Account',
      keywords: ['history', 'previous', 'past', 'trips', 'rides', 'receipt'],
      actionLabel: 'View My Rides',
      actionRoute: '/ride-history',
    ),
    FaqItem(
      id: 'faq_coupon',
      question: 'How do I apply a coupon?',
      answer:
          'Visit the "Offers & Rewards" section from the bottom navigation bar or Profile. Browse available promotions like "FIRST RIDE - 50% OFF" and tap "Apply" to save on your eligible trips.',
      category: 'Offers',
      keywords: ['coupon', 'offer', 'discount', 'promo', 'apply', 'reward'],
      actionLabel: 'Browse Offers',
      actionRoute: '/offers',
    ),
  ];
}
