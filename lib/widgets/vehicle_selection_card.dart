import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../models/vehicle_model.dart';

/// Reusable vehicle selection card with selection animation, fare preview, availability gating, and details.
class VehicleSelectionCard extends StatelessWidget {
  const VehicleSelectionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.isAvailable = true,
    this.fare,
    this.ratePerKm,
    this.selectedSlab,
    this.unavailableReason,
  });

  final VehicleOption option;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isAvailable;
  final double? fare;
  final double? ratePerKm;
  final String? selectedSlab;
  final String? unavailableReason;

  String _formatFare(double val) {
    if (val == val.roundToDouble()) {
      return '₹${val.toStringAsFixed(0)}';
    }
    return '₹${val.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isAvailable
        ? (isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceDark)
        : AppColors.surfaceDark.withValues(alpha: 0.6);

    final borderColor = isAvailable
        ? (isSelected ? AppColors.primary : AppColors.borderDark)
        : AppColors.borderDark.withValues(alpha: 0.5);

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.62,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: AppDimensions.space12),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: borderColor,
            width: isSelected && isAvailable ? 2.0 : 1.2,
          ),
          boxShadow: isSelected && isAvailable
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAvailable ? onTap : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Row(
                children: [
                  // Vehicle Icon Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected && isAvailable
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.backgroundDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected && isAvailable
                            ? AppColors.primary
                            : AppColors.borderDark,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        option.icon,
                        color: isSelected && isAvailable
                            ? AppColors.primary
                            : (isAvailable ? AppColors.textPrimaryLight : AppColors.textSecondaryLight),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space16),

                  // Vehicle Details (Title, Subtitle, Capacity / Unavailable reason / Fare)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              option.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isAvailable
                                    ? AppColors.textPrimaryLight
                                    : AppColors.textSecondaryLight,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevatedDark,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                border: Border.all(color: AppColors.borderDark, width: 0.8),
                              ),
                              child: Text(
                                option.capacity,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (isAvailable) ...[
                          Text(
                            option.subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                option.estimatedArrival,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                              if (ratePerKm != null && selectedSlab != null) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '• ₹${ratePerKm!.toStringAsFixed(2)}/km',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.block_rounded,
                                size: 13,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  unavailableReason ?? 'Unavailable for this distance',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: AppDimensions.space8),

                  // Fare & Selection Radio Indicator
                  if (isAvailable && fare != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatFare(fare!),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.borderDark,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: AppColors.backgroundDark,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ] else if (!isAvailable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Unavailable',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
