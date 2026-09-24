import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/location_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/fare_calculator.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/vehicle_selection_card.dart';
import '../fare_calculation/fare_calculation_screen.dart';

/// STEP 6 & STEP 44: Vehicle Selection Screen.
///
/// Features:
/// - Top App Bar with back button returning to HomeScreen with state preserved
/// - Header: "Choose your ride" & "Select a vehicle that suits your journey"
/// - Trip Summary Card: Displays Pickup, Destination, Distance, and Estimated Travel Time
/// - Dynamic Vehicle Cards (Bike, Auto, Car) with centralized single-slab pricing, slab details, and availability gating
/// - Unavailable Reason Chips (e.g. min 5km for car, max 50km for bike/auto, max 150km for car)
/// - "No vehicle is available for this distance." banner & disabled booking when all options exceed boundaries
/// - Passes complete trip and vehicle payload to Step 7 Fare Calculation Screen
class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({
    super.key,
    required this.routeDetails,
  });

  final RouteDetails routeDetails;

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  VehicleOption? _selectedVehicle;

  @override
  void initState() {
    super.initState();
  }

  void _handleSelectVehicle(VehicleOption option) {
    final res = FareCalculator.calculate(
      vehicleType: option.title,
      distanceKm: widget.routeDetails.distanceKm,
    );

    if (!res.available) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.unavailableReason ?? 'This vehicle is not available for this distance.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _selectedVehicle = option;
    });
  }

  void _handleContinue() {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            AppStrings.errorSelectVehicle,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final fareCheck = FareCalculator.calculate(
      vehicleType: _selectedVehicle!.title,
      distanceKm: widget.routeDetails.distanceKm,
    );

    if (!fareCheck.available) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fareCheck.unavailableReason ?? 'Selected vehicle is unavailable for this distance.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Navigate to Step 7: Fare Calculation Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => FareCalculationScreen(
          routeDetails: widget.routeDetails,
          selectedVehicle: _selectedVehicle!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = widget.routeDetails.distanceKm;
    final fareResults = <String, FareCalculationResult>{};
    for (final option in VehicleOption.standardOptions) {
      fareResults[option.id] = FareCalculator.calculate(
        vehicleType: option.title,
        distanceKm: distanceKm,
      );
    }

    final hasAnyAvailable = fareResults.values.any((r) => r.available);

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
          AppStrings.chooseRideTitle,
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Subtitle Header
                    _buildHeaderSection(),
                    const SizedBox(height: AppDimensions.space16),

                    // Trip Summary Card (Pickup, Destination, Distance, ETA)
                    _buildTripSummaryCard(),
                    const SizedBox(height: AppDimensions.space20),

                    // No Vehicle Available Warning Banner if all out of range
                    if (!hasAnyAvailable) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.space12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(color: AppColors.error, width: 1.2),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No vehicle is available for this distance.',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),
                    ],

                    // Vehicle Options Section
                    const Text(
                      'AVAILABLE RIDES',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),

                    // Vehicle Cards List (Bike, Auto, Car)
                    ...VehicleOption.standardOptions.map((option) {
                      final result = fareResults[option.id]!;
                      return VehicleSelectionCard(
                        option: option,
                        isSelected: _selectedVehicle?.id == option.id,
                        onTap: () => _handleSelectVehicle(option),
                        isAvailable: result.available,
                        fare: result.available ? result.fare : null,
                        ratePerKm: result.available ? result.ratePerKm : null,
                        selectedSlab: result.available ? result.selectedSlab : null,
                        unavailableReason: result.unavailableReason,
                      );
                    }),
                    const SizedBox(height: AppDimensions.space16),

                    // Estimated Fare Info Section
                    _buildEstimatedFareSection(),
                    const SizedBox(height: AppDimensions.space20),
                  ],
                ),
              ),
            ),

            // Bottom Continue Button
            _buildBottomBar(hasAnyAvailable: hasAnyAvailable),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          AppStrings.chooseRideTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          AppStrings.chooseRideSubtitle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTripSummaryCard() {
    final route = widget.routeDetails;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.route_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                AppStrings.tripSummaryHeader,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pickup Row
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
                      route.pickup.name,
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
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),

          // Destination Row
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
                      route.destination.name,
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
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),

          // Metrics (Distance and Travel Time)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.straighten_rounded, color: AppColors.textSecondaryLight, size: 15),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${AppStrings.distanceLabel}: ${route.formattedDistance}',
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
              Container(width: 1, height: 14, color: AppColors.borderDark),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 15),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${AppStrings.estTimeLabel}: ${route.formattedDuration}',
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
        ],
      ),
    );
  }

  Widget _buildEstimatedFareSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  AppStrings.estimatedFareLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppStrings.fareCalculationNext,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required bool hasAnyAvailable}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 1.0),
        ),
      ),
      child: PrimaryButton(
        text: hasAnyAvailable ? AppStrings.continueButton : 'No Vehicle Available',
        onPressed: hasAnyAvailable ? _handleContinue : null,
        icon: hasAnyAvailable ? Icons.arrow_forward_rounded : Icons.block_rounded,
      ),
    );
  }
}
