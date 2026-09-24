import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/location_model.dart';
import '../../widgets/primary_button.dart';

/// Step 5 -> Step 6 transition placeholder screen.
/// Receives and displays all captured trip parameters (pickup, destination, distance, ETA).
class RideOptionsPlaceholderScreen extends StatelessWidget {
  const RideOptionsPlaceholderScreen({
    super.key,
    required this.routeDetails,
  });

  final RouteDetails routeDetails;

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
        ),
        title: const Text(
          'Confirm Trip Route',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ready indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Route Confirmed!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pickup & Destination locked in successfully.',
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

              const SizedBox(height: AppDimensions.space24),

              // Trip details card
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
                    const Text(
                      'TRIP SUMMARY',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pickup
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 12),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                routeDetails.pickup.address,
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
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: AppColors.borderDark),
                    ),

                    // Destination
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                routeDetails.destination.address,
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
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: AppColors.borderDark),
                    ),

                    // Distance & Duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStrings.distanceLabel,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              routeDetails.formattedDistance,
                              style: const TextStyle(
                                fontSize: 16,
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
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            Text(
                              routeDetails.formattedDuration,
                              style: const TextStyle(
                                fontSize: 16,
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

              // Notice for Step 6
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'STEP 6 will integrate vehicle selection (Bike, Auto, Car) and dynamic fare calculation based on this distance.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              PrimaryButton(
                text: 'Back to Home',
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
