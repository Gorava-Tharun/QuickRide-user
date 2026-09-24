import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/ride_history_model.dart';
import '../../../models/vehicle_model.dart';

/// Reusable card widget representing an individual ride history record.
class RideHistoryCard extends StatelessWidget {
  const RideHistoryCard({
    super.key,
    required this.ride,
    required this.onTap,
  });

  final RideHistoryItem ride;
  final VoidCallback onTap;

  IconData _getVehicleIcon(VehicleCategory category) {
    switch (category) {
      case VehicleCategory.bike:
        return Icons.two_wheeler_rounded;
      case VehicleCategory.auto:
        return Icons.electric_rickshaw_rounded;
      case VehicleCategory.car:
        return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = ride.isCancelled;
    final vehicleIcon = _getVehicleIcon(ride.vehicle.category);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isCancelled
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.borderDark,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Vehicle, Name, and Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Icon(
                        vehicleIcon,
                        color: isCancelled
                            ? AppColors.error
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.vehicle.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${ride.formattedDate} • ${ride.formattedTime}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? AppColors.error.withValues(alpha: 0.15)
                            : const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(
                          color: isCancelled
                              ? AppColors.error
                              : const Color(0xFF10B981),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        ride.formattedStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCancelled
                              ? AppColors.error
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.borderDark, height: 1),
                ),

                // Pickup & Destination Route Overview
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.my_location_rounded,
                            color: AppColors.secondary, size: 14),
                        Container(
                          width: 1.5,
                          height: 24,
                          color: AppColors.borderDark,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                        ),
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 14),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.pickup.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            ride.destination.name,
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
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.borderDark, height: 1),
                ),

                // Bottom Metrics Row: Distance, Time, Fare, Captain & Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Distance & Duration
                    Text(
                      '${ride.distanceKm.toStringAsFixed(1)} km • ${ride.estimatedMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),

                    // Fare (Show ₹0 / Cancelled if cancelled)
                    Text(
                      isCancelled
                          ? 'Cancelled'
                          : ride.fareDetails.formattedFinalFare,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isCancelled
                            ? AppColors.textMutedDark
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Captain Name & Rating indicator
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        color: AppColors.textSecondaryLight, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ride.captain.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    if (ride.isRated) ...[
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            '${ride.rating ?? 5}.0',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ] else if (!isCancelled) ...[
                      const Text(
                        'Not Rated',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
