import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_strings.dart';
import '../models/location_model.dart';

/// Card showing selected pickup & destination with swap button and route metrics.
class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.onTapPickup,
    required this.onTapDestination,
    required this.onSwap,
    this.routeDetails,
  });

  final LocationPoint pickup;
  final LocationPoint? destination;
  final VoidCallback onTapPickup;
  final VoidCallback onTapDestination;
  final VoidCallback onSwap;
  final RouteDetails? routeDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing fields and swap button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual indicators line
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 38,
                    color: AppColors.borderDark,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppDimensions.space12),

              // Inputs column
              Expanded(
                child: Column(
                  children: [
                    // Pickup Selector
                    InkWell(
                      onTap: onTapPickup,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.pickupLocation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pickup.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            if (pickup.address.isNotEmpty && pickup.address != pickup.name) ...[
                              const SizedBox(height: 2),
                              Text(
                                pickup.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Destination Selector
                    InkWell(
                      onTap: onTapDestination,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(
                            color: destination != null ? AppColors.primary : AppColors.borderDark,
                            width: destination != null ? 1.2 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.destinationLocation,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              destination?.name ?? AppStrings.destinationSearchPrompt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: destination != null ? FontWeight.w700 : FontWeight.w500,
                                color: destination != null
                                    ? AppColors.textPrimaryLight
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (destination != null &&
                                destination!.address.isNotEmpty &&
                                destination!.address != destination!.name) ...[
                              const SizedBox(height: 2),
                              Text(
                                destination!.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.space12),

              // Swap Button
              Material(
                color: AppColors.surfaceDark,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.borderDark, width: 1),
                ),
                child: IconButton(
                  icon: const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 22),
                  tooltip: AppStrings.swapLocationsTooltip,
                  onPressed: onSwap,
                ),
              ),
            ],
          ),

          // Route Details Banner (if destination selected)
          if (routeDetails != null) ...[
            const SizedBox(height: AppDimensions.space12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${AppStrings.distanceLabel}: ${routeDetails!.formattedDistance}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 16, color: AppColors.borderDark),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${AppStrings.estTimeLabel}: ${routeDetails!.formattedDuration}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
