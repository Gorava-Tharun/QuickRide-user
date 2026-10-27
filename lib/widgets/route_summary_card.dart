import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_strings.dart';
import '../models/location_model.dart';

/// Card showing selected pickup & destination with swap button, editable text controllers, and route metrics.
class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.pickup,
    required this.destination,
    required this.onTapPickup,
    required this.onTapDestination,
    required this.onSwap,
    this.routeDetails,
    this.onTapSelectDestinationOnMap,
    this.onTapSelectPickupOnMap,
    this.pickupController,
    this.destinationController,
    this.onPickupChanged,
    this.onDestinationChanged,
    this.isSelectingPickupOnMap = false,
    this.isSelectingDestinationOnMap = false,
  });

  final LocationPoint pickup;
  final LocationPoint? destination;
  final VoidCallback onTapPickup;
  final VoidCallback onTapDestination;
  final VoidCallback onSwap;
  final RouteDetails? routeDetails;
  final VoidCallback? onTapSelectDestinationOnMap;
  final VoidCallback? onTapSelectPickupOnMap;
  final TextEditingController? pickupController;
  final TextEditingController? destinationController;
  final ValueChanged<String>? onPickupChanged;
  final ValueChanged<String>? onDestinationChanged;
  final bool isSelectingPickupOnMap;
  final bool isSelectingDestinationOnMap;

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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isSelectingPickupOnMap ? AppColors.secondary : AppColors.borderDark,
                          width: isSelectingPickupOnMap ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: onTapPickup,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
                                  if (pickup.name.isNotEmpty && pickup.name != pickup.address) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      pickup.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  pickupController != null
                                      ? TextField(
                                          controller: pickupController,
                                          onChanged: onPickupChanged,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimaryLight,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 2),
                                            border: InputBorder.none,
                                            hintText: 'Enter or select pickup address',
                                            hintStyle: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          pickup.address.isNotEmpty ? pickup.address : pickup.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimaryLight,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                          if (onTapSelectPickupOnMap != null) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Select on Google Map',
                              child: InkWell(
                                onTap: onTapSelectPickupOnMap,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelectingPickupOnMap
                                        ? AppColors.secondary.withValues(alpha: 0.25)
                                        : AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    border: Border.all(
                                      color: isSelectingPickupOnMap ? AppColors.secondary : AppColors.borderDark,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.pin_drop_rounded,
                                    size: 16,
                                    color: isSelectingPickupOnMap ? AppColors.secondary : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Destination Selector
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(
                          color: isSelectingDestinationOnMap
                              ? AppColors.primary
                              : (destination != null ? AppColors.primary : AppColors.borderDark),
                          width: (isSelectingDestinationOnMap || destination != null) ? 1.2 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: onTapDestination,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
                                  if (destination != null &&
                                      destination!.name.isNotEmpty &&
                                      destination!.name != destination!.address) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      destination!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  destination == null
                                      ? const Text(
                                          AppStrings.destinationSearchPrompt,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                        )
                                      : destinationController != null
                                          ? TextField(
                                              controller: destinationController,
                                              onChanged: onDestinationChanged,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimaryLight,
                                              ),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 2),
                                                border: InputBorder.none,
                                                hintText: AppStrings.destinationSearchPrompt,
                                                hintStyle: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              destination!.address.isNotEmpty
                                                  ? destination!.address
                                                  : destination!.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimaryLight,
                                              ),
                                            ),
                                ],
                              ),
                            ),
                          ),
                          if (onTapSelectDestinationOnMap != null) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Select on Google Map',
                              child: InkWell(
                                onTap: onTapSelectDestinationOnMap,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelectingDestinationOnMap
                                        ? AppColors.primary.withValues(alpha: 0.25)
                                        : AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    border: Border.all(
                                      color: isSelectingDestinationOnMap ? AppColors.primary : AppColors.borderDark,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.map_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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
