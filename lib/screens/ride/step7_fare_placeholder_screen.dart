import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/location_model.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/primary_button.dart';

/// Step 6 -> Step 7 transition placeholder screen.
///
/// Receives all trip details and selected vehicle:
/// - Selected Vehicle (Category, Title, Capacity)
/// - Pickup Address, Latitude, Longitude
/// - Destination Address, Latitude, Longitude
/// - Distance (km)
/// - Estimated Travel Time
class Step7FarePlaceholderScreen extends StatelessWidget {
  const Step7FarePlaceholderScreen({
    super.key,
    required this.routeDetails,
    required this.selectedVehicle,
  });

  final RouteDetails routeDetails;
  final VehicleOption selectedVehicle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Trip Summary (Step 7)',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Vehicle Selected!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Trip & vehicle ready for Fare Calculation in Step 7.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Trip & Vehicle Data Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Vehicle
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(selectedVehicle.icon, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ride: ${selectedVehicle.title}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                '${selectedVehicle.subtitle} • ${selectedVehicle.capacity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.borderDark),
                    ),

                    // Pickup Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.pickupLocation,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                routeDetails.pickup.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                '${routeDetails.pickup.latitude.toStringAsFixed(4)}, ${routeDetails.pickup.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Destination Details
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.destinationLocation,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                routeDetails.destination.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                '${routeDetails.destination.latitude.toStringAsFixed(4)}, ${routeDetails.destination.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.borderDark),
                    ),

                    // Metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.distanceLabel,
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              routeDetails.formattedDistance,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              AppStrings.estTimeLabel,
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              routeDetails.formattedDuration,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'STEP 7 will calculate exact base fares, per-km rates, and discounts for the selected ride.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              PrimaryButton(
                text: 'Back to Vehicles',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.arrow_back_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
