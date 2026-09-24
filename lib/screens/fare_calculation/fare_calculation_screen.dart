import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/fare_model.dart';
import '../../models/location_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/fare_calculator.dart';
import '../../services/offer_service.dart';
import '../../widgets/fare_breakdown_card.dart';
import '../../widgets/primary_button.dart';
import '../offers/offers_screen.dart';
import '../ride_confirmation/ride_confirmation_screen.dart';

/// STEP 7: Fare Calculation Screen.
///
/// Features:
/// - Top App Bar with back button
/// - Selected Vehicle Summary with icon, capacity, arrival time, and "Change Vehicle" action
/// - Trip Details Card (Pickup, Destination, Distance, Estimated Time)
/// - Promotional Offers & Coupon Card with Apply/Remove actions
/// - Fare Breakdown Card (Base Fare, Distance Fare, Time Fare, Waiting Charge, Original Fare, 50% First Ride Discount, Additional Offer Discount, Final Fare)
/// - Bottom fixed "Confirm Ride" button with validation and navigation to Step 8 Ride Confirmation Screen
class FareCalculationScreen extends StatefulWidget {
  const FareCalculationScreen({
    super.key,
    required this.routeDetails,
    required this.selectedVehicle,
  });

  final RouteDetails routeDetails;
  final VehicleOption selectedVehicle;

  @override
  State<FareCalculationScreen> createState() => _FareCalculationScreenState();
}

class _FareCalculationScreenState extends State<FareCalculationScreen> {
  final OfferService _offerService = OfferService();
  late FareDetails _fareDetails;

  @override
  void initState() {
    super.initState();
    _calculateFare();
  }

  void _calculateFare() {
    final baseFare = FareCalculator.calculateFare(
      category: widget.selectedVehicle.category,
      distanceKm: widget.routeDetails.distanceKm,
      estimatedMinutes: widget.routeDetails.estimatedMinutes,
      applyFirstRideDiscount: true,
    );

    final appliedOffer = _offerService.appliedOffer;
    if (appliedOffer != null && appliedOffer.id != 'offer_first50') {
      if (baseFare.originalFare >= appliedOffer.minimumFare) {
        final offerDiscount = appliedOffer.calculateDiscount(baseFare.originalFare);
        final cappedDiscount = offerDiscount.clamp(0.0, baseFare.finalFare);
        _fareDetails = baseFare.withOffer(
          offerDiscount: cappedDiscount,
          offerLabel: '${appliedOffer.title} Promo',
        );
      } else {
        _fareDetails = baseFare;
      }
    } else {
      _fareDetails = baseFare;
    }
  }

  void _handleRemoveOffer() {
    setState(() {
      _offerService.removeOffer();
      _calculateFare();
    });
    _showNotice('Offer removed.');
  }

  void _navigateToOffers() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => const OffersScreen(),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() {
          _calculateFare();
        });
      }
    });
  }

  void _handleConfirmRide() {
    // 1. Validate Pickup & Destination
    if (widget.routeDetails.pickup.name.isEmpty ||
        widget.routeDetails.destination.name.isEmpty) {
      _showNotice(AppStrings.errorInvalidTripData, isError: true);
      return;
    }

    // 2. Validate Fare
    if (_fareDetails.finalFare <= 0) {
      _showNotice(AppStrings.errorInvalidTripData, isError: true);
      return;
    }

    _showNotice(AppStrings.rideConfirmedNotice, isError: false);

    // Navigate to Step 8: Ride Confirmation Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => RideConfirmationScreen(
          routeDetails: widget.routeDetails,
          selectedVehicle: widget.selectedVehicle,
          fareDetails: _fareDetails,
        ),
      ),
    );
  }

  void _showNotice(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
          AppStrings.fareCalculationTitle,
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
                    // Vehicle Summary Card with Change Vehicle action
                    _buildVehicleSummaryCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Trip Details Card
                    _buildTripDetailsCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Promotional Offers Card
                    _buildOffersCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Fare Breakdown Card with 50% First Ride Discount
                    FareBreakdownCard(fareDetails: _fareDetails),
                    const SizedBox(height: AppDimensions.space20),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Bar with Confirm Ride Button
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSummaryCard() {
    final vehicle = widget.selectedVehicle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Row(
        children: [
          // Vehicle Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Icon(vehicle.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppDimensions.space12),

          // Vehicle Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${vehicle.capacity} • ${vehicle.estimatedArrival}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Change Vehicle Button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: AppColors.surfaceElevatedDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                side: const BorderSide(color: AppColors.borderDark),
              ),
            ),
            child: const Text(
              AppStrings.changeVehicleButton,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard() {
    final route = widget.routeDetails;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.navigation_rounded, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'ROUTE DETAILS',
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.pickupLocation,
                      style: TextStyle(
                        fontSize: 10.5,
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

          // Destination
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.destinationLocation,
                      style: TextStyle(
                        fontSize: 10.5,
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

          // Distance & ETA metrics
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.straighten_rounded, color: AppColors.textSecondaryLight, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      '${AppStrings.distanceLabel}: ',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      route.formattedDistance,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
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
                    Text(
                      '${AppStrings.estTimeLabel}: ',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      route.formattedDuration,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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

  Widget _buildOffersCard() {
    final appliedOffer = _offerService.appliedOffer;
    final hasActiveOffer = appliedOffer != null &&
        appliedOffer.id != 'offer_first50' &&
        _fareDetails.offerDiscount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: hasActiveOffer
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: hasActiveOffer
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : AppColors.borderDark,
          width: 1.2,
        ),
      ),
      child: hasActiveOffer
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 14),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Applied \u2713',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _fareDetails.formattedOfferDiscount,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appliedOffer.title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _handleRemoveOffer,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
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
                        'Offers & Promo Code',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Apply coupon to save extra',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _navigateToOffers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevatedDark,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      side: const BorderSide(color: AppColors.borderDark),
                    ),
                  ),
                  child: const Text(
                    'View Offers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.0)),
      ),
      child: PrimaryButton(
        text: AppStrings.confirmRideButton,
        onPressed: _handleConfirmRide,
        icon: Icons.check_circle_outline_rounded,
      ),
    );
  }
}
