import "package:flutter/material.dart";

/// Type of discount applied by an offer.
enum DiscountType {
  /// Percentage discount on the original fare (e.g. 50%).
  percentage,

  /// Fixed rupee amount deducted from the fare (e.g. Rs.50).
  fixedAmount,
}

/// Represents a promotional offer or coupon in QuickRide.
class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minimumFare,
    required this.expiryDate,
    required this.termsAndConditions,
    required this.badgeColor,
    required this.iconData,
    this.couponCode,
    this.maximumDiscount,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String? couponCode;
  final DiscountType discountType;
  final double discountValue;
  final double? maximumDiscount;
  final double minimumFare;
  final DateTime expiryDate;
  final bool isActive;
  final String termsAndConditions;
  final Color badgeColor;
  final IconData iconData;

  String get discountLabel {
    if (discountType == DiscountType.percentage) {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    return '₹${discountValue.toStringAsFixed(0)} OFF';
  }

  bool get isValid => isActive && expiryDate.isAfter(DateTime.now());

  String get formattedExpiry {
    final d = expiryDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Valid till ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  double calculateDiscount(double originalFare) {
    if (originalFare < minimumFare) return 0.0;
    if (discountType == DiscountType.fixedAmount) {
      return discountValue.clamp(0.0, originalFare);
    }
    final raw = originalFare * (discountValue / 100.0);
    if (maximumDiscount != null) return raw.clamp(0.0, maximumDiscount!);
    return raw.clamp(0.0, originalFare);
  }

  factory Offer.fromFirestore(dynamic firestoreModel) {
    // Accepts FirestoreOfferModel
    final type = firestoreModel.discountType == 'fixed'
        ? DiscountType.fixedAmount
        : DiscountType.percentage;

    return Offer(
      id: firestoreModel.offerId,
      title: firestoreModel.title,
      subtitle: firestoreModel.description,
      description: firestoreModel.description,
      couponCode: firestoreModel.couponCode.isNotEmpty ? firestoreModel.couponCode : null,
      discountType: type,
      discountValue: firestoreModel.discountValue,
      maximumDiscount: firestoreModel.maxDiscount,
      minimumFare: firestoreModel.minimumFare,
      expiryDate: firestoreModel.validUntil,
      isActive: firestoreModel.active,
      termsAndConditions: '• Valid till ${firestoreModel.validUntil.day}/${firestoreModel.validUntil.month}/${firestoreModel.validUntil.year}\n'
          '• Minimum fare ₹${firestoreModel.minimumFare.toStringAsFixed(0)}\n'
          '• ${firestoreModel.maxDiscount != null ? "Max discount ₹${firestoreModel.maxDiscount!.toStringAsFixed(0)}\n" : ""}'
          '• Applicable once per ride.',
      badgeColor: const Color(0xFF10B981),
      iconData: Icons.local_offer_rounded,
    );
  }
}

/// Demo coupon codes that map to existing offer IDs.
const Map<String, String> kDemoCouponCodes = {
  'QUICK50': 'offer_quick10',
  'RIDE50': 'offer_save50',
};

/// Built-in mock offers shown in the Offers screen.
final List<Offer> kMockOffers = [
  Offer(
    id: 'offer_first50',
    title: 'FIRST RIDE — 50% OFF',
    subtitle: 'Get 50% off on your first QuickRide ride.',
    description:
        'Get 50% off on your very first QuickRide trip! '
        'This exclusive welcome offer is automatically applied to your first ride. '
        'No coupon code needed — just book and save!\n\n'
        '⚠️ Demo offer. First-ride discount is already applied at checkout.',
    couponCode: null,
    discountType: DiscountType.percentage,
    discountValue: 50.0,
    maximumDiscount: null,
    minimumFare: 0.0,
    expiryDate: DateTime(2027, 12, 31),
    isActive: true,
    termsAndConditions:
        '• Valid only on the first QuickRide trip.\n'
        '• Applied automatically — no coupon required.\n'
        '• Cannot be combined with other promotional offers.\n'
        '• QuickRide reserves the right to withdraw this offer at any time.',
    badgeColor: const Color(0xFFFFC700),
    iconData: Icons.celebration_rounded,
  ),
  Offer(
    id: 'offer_save50',
    title: 'SAVE ₹50',
    subtitle: 'Get ₹50 off on your next eligible ride.',
    description:
        'Enjoy a flat ₹50 discount on your next QuickRide trip. '
        'Applicable on rides with a minimum fare of ₹100. '
        'Enter coupon code RIDE50 at checkout.\n\n'
        '⚠️ Demo offer — valid for testing purposes only.',
    couponCode: 'RIDE50',
    discountType: DiscountType.fixedAmount,
    discountValue: 50.0,
    maximumDiscount: null,
    minimumFare: 100.0,
    expiryDate: DateTime(2027, 6, 30),
    isActive: true,
    termsAndConditions:
        '• Valid on rides with a minimum fare of ₹100.\n'
        '• Use coupon code RIDE50 to avail this offer.\n'
        '• One-time use per account per month.\n'
        '• Not applicable on rides below ₹100.',
    badgeColor: const Color(0xFF00E5FF),
    iconData: Icons.savings_rounded,
  ),
  Offer(
    id: 'offer_weekend',
    title: 'WEEKEND OFFER',
    subtitle: 'Enjoy special discounts on weekend rides.',
    description:
        'Make your weekends more affordable! Enjoy 20% off on all QuickRide trips '
        'booked on Saturdays and Sundays. Maximum discount of ₹60 per ride.\n\n'
        '⚠️ Demo offer — discount applied for testing every day.',
    couponCode: 'WEEKEND20',
    discountType: DiscountType.percentage,
    discountValue: 20.0,
    maximumDiscount: 60.0,
    minimumFare: 50.0,
    expiryDate: DateTime(2027, 9, 30),
    isActive: true,
    termsAndConditions:
        '• Valid on Saturday and Sunday rides only (demo: every day).\n'
        '• Maximum discount cap: ₹60 per ride.\n'
        '• Minimum ride fare: ₹50.\n'
        '• Cannot be combined with other promotional offers.',
    badgeColor: const Color(0xFF10B981),
    iconData: Icons.wb_sunny_rounded,
  ),
  Offer(
    id: 'offer_quick10',
    title: '10% OFF — QUICK DEAL',
    subtitle: '10% off via coupon QUICK50 (max ₹30)',
    description:
        'Use promo code QUICK50 to get 10% off on your next ride. '
        'Maximum discount of ₹30 per trip.\n\n'
        '⚠️ Demo offer — valid for development and testing.',
    couponCode: 'QUICK50',
    discountType: DiscountType.percentage,
    discountValue: 10.0,
    maximumDiscount: 30.0,
    minimumFare: 30.0,
    expiryDate: DateTime(2027, 12, 31),
    isActive: true,
    termsAndConditions:
        '• Enter coupon code QUICK50 at checkout.\n'
        '• Maximum discount: ₹30 per ride.\n'
        '• Minimum ride fare: ₹30.\n'
        '• Valid once per user per day.',
    badgeColor: const Color(0xFF8B5CF6),
    iconData: Icons.bolt_rounded,
  ),
];
