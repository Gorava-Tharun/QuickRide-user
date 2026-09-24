import "package:flutter/material.dart";
import "../../../core/constants/app_colors.dart";
import "../../../core/constants/app_dimensions.dart";
import "../../../models/offer_model.dart";

/// Reusable promotional card widget for an [Offer].
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.isApplied,
    required this.onApply,
    required this.onRemove,
    required this.onTapDetails,
  });

  final Offer offer;
  final bool isApplied;
  final VoidCallback onApply;
  final VoidCallback onRemove;
  final VoidCallback onTapDetails;

  @override
  Widget build(BuildContext context) {
    final isViewOfferOnly = offer.id == "offer_weekend";

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isApplied ? AppColors.primary : AppColors.borderDark,
          width: isApplied ? 2.0 : 1.2,
        ),
        boxShadow: [
          if (isApplied)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: InkWell(
          onTap: onTapDetails,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Badge + Demo Tag
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: offer.badgeColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: offer.badgeColor.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        offer.iconData,
                        color: offer.badgeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: offer.badgeColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                  border: Border.all(
                                    color: offer.badgeColor.withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  offer.discountLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: offer.badgeColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceDark,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.borderDark,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  "DEMO",
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondaryLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),

                // Subtitle
                Text(
                  offer.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                // Coupon code & validity info
                Row(
                  children: [
                    if (offer.couponCode != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevatedDark,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          border: Border.all(
                            color: AppColors.borderDark,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              offer.couponCode!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        offer.formattedExpiry,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: AppColors.borderDark, height: 1),
                ),

                // Actions / Applied status bar
                if (isApplied)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Applied \u2713",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: onRemove,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                        ),
                        child: const Text(
                          "Remove",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: onTapDetails,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          children: const [
                            Text(
                              "View Details",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isViewOfferOnly ? onTapDetails : onApply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isViewOfferOnly
                              ? AppColors.surfaceElevatedDark
                              : AppColors.primary,
                          foregroundColor: isViewOfferOnly
                              ? AppColors.textPrimaryLight
                              : Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            side: isViewOfferOnly
                                ? const BorderSide(color: AppColors.borderDark)
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          isViewOfferOnly ? "View Offer" : "Apply",
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
