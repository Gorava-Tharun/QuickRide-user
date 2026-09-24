import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/fare_model.dart';
import '../../models/location_model.dart';
import '../../models/vehicle_model.dart';
import '../../widgets/primary_button.dart';

/// Step 7 -> Step 8 transition placeholder screen.
/// Displays confirmed ride with locked-in fare and awaits driver matching in Step 8.
class Step8RideConfirmedScreen extends StatelessWidget {
  const Step8RideConfirmedScreen({
    super.key,
    required this.routeDetails,
    required this.selectedVehicle,
    required this.fareDetails,
  });

  final RouteDetails routeDetails;
  final VehicleOption selectedVehicle;
  final FareDetails fareDetails;

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
          'Ride Confirmed (Step 8)',
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
              // Confirmation Banner
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
                            'Ride Details Confirmed!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fare locked in. Ready for Captain Matching in Step 8.',
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

              // Summary Card
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
                    // Vehicle & Fare Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedVehicle.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  selectedVehicle.capacity,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              AppStrings.finalFareLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              fareDetails.formattedFinalFare,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.borderDark),
                    ),

                    // Locations
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            routeDetails.pickup.name,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            routeDetails.destination.name,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
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
                        Text(
                          'Distance: ${routeDetails.formattedDistance}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                        Text(
                          'Time: ${routeDetails.formattedDuration}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
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
                    Icon(Icons.near_me_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'STEP 8 will initiate real-time Captain Matching and dispatching for this trip.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              PrimaryButton(
                text: 'Back to Fare Calculation',
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
