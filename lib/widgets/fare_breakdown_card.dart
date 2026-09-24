import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_strings.dart';
import '../models/fare_model.dart';

/// Card showing line-item fare breakdown and prominent final fare.
class FareBreakdownCard extends StatelessWidget {
  const FareBreakdownCard({
    super.key,
    required this.fareDetails,
  });

  final FareDetails fareDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & 50% Off Offer Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.fareBreakdownHeader,
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_rounded, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      AppStrings.firstRideOfferBadge,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),

          // Line Items
          _buildFareRow(AppStrings.baseFareLabel, fareDetails.formattedBaseFare),
          const SizedBox(height: 8),
          _buildFareRow(AppStrings.distanceFareLabel, fareDetails.formattedDistanceFare),
          const SizedBox(height: 8),
          _buildFareRow(AppStrings.timeFareLabel, fareDetails.formattedTimeFare),
          const SizedBox(height: 8),
          _buildFareRow(AppStrings.waitingChargeLabel, fareDetails.formattedWaitingCharge),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),

          // Original Fare
          _buildFareRow(
            AppStrings.originalFareLabel,
            fareDetails.formattedOriginalFare,
            valueStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.lineThrough,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),

          // 50% First Ride Discount
          _buildFareRow(
            AppStrings.firstRideDiscountLabel,
            fareDetails.formattedDiscount,
            valueStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),

          // Additional Offer Discount (if applied)
          if (fareDetails.offerDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildFareRow(
              fareDetails.offerLabel ?? 'Offer Discount',
              fareDetails.formattedOfferDiscount,
              valueStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.primary, height: 1.5),
          ),

          // Prominent Final Fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      AppStrings.finalFareLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Inclusive of all taxes & fees',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                fareDetails.offerDiscount > 0
                    ? fareDetails.formattedEffectiveFinalFare
                    : fareDetails.formattedFinalFare,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(
    String label,
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
        ),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
        ),
      ],
    );
  }
}
