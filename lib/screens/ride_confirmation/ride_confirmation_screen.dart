import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/fare_model.dart';
import '../../models/location_model.dart';
import '../../models/ride_details_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/ride_model.dart';
import '../../models/firestore_models.dart';
import '../../services/firebase_service.dart';
import '../../services/fare_calculator.dart';
import '../../services/offer_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/primary_button.dart';
import '../finding_captain/finding_captain_screen.dart';

/// STEP 8: Ride Confirmation Screen.
///
/// Objective:
/// Present complete ride summary before final request submission.
///
/// Features:
/// - AppBar with title "Confirm Your Ride" & Subtitle prompt
/// - Trip Route Summary Card (Pickup, Destination, Distance, ETA)
/// - Selected Vehicle Details (Category icon, name, capacity, arrival)
/// - Locked Fare Summary Card (Original fare, 50% discount savings badge, Final locked fare)
/// - Payment Method Selector (Cash vs Online Payment toggle)
/// - Captain Dispatch Notice & Safety guarantee badge
/// - Bottom fixed "Request QuickRide" action button
/// - Smooth booking trigger & navigation to Finding Captain Screen (Step 9)
class RideConfirmationScreen extends StatefulWidget {
  const RideConfirmationScreen({
    super.key,
    required this.routeDetails,
    required this.selectedVehicle,
    required this.fareDetails,
  });

  final RouteDetails routeDetails;
  final VehicleOption selectedVehicle;
  final FareDetails fareDetails;

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  bool _isRequesting = false;

  void _handleSelectPayment(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  void _handleRequestRide() async {
    if (_isRequesting) return; // Prevent duplicate requests

    setState(() {
      _isRequesting = true;
    });

    // Step 44: Booking Validation
    // 1. Verify Pickup & Destination
    if (widget.routeDetails.pickup.name.trim().isEmpty ||
        widget.routeDetails.destination.name.trim().isEmpty) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid pickup or destination location.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Verify Distance
    if (widget.routeDetails.distanceKm <= 0) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid trip distance.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3. Centralized Fare Verification & Vehicle Availability
    final fareVerification = FareCalculator.calculate(
      vehicleType: widget.selectedVehicle.title,
      distanceKm: widget.routeDetails.distanceKm,
    );

    if (!fareVerification.available) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fareVerification.unavailableReason ?? 'Vehicle is unavailable for this distance.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.fareDetails.effectiveFinalFare < 0) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid calculated fare.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fbService = QuickRideFirebaseService();
    final user = SessionManager().currentUser;

    final rideId = 'RIDE-${DateTime.now().millisecondsSinceEpoch}';
    final appliedOffer = OfferService().appliedOffer;

    // Create SharedRideModel for Firestore with offer details if applied
    final sharedRide = SharedRideModel(
      rideId: rideId,
      userId: user.userId,
      userName: user.fullName,
      captainId: null, // Unassigned at creation; matched via dispatch
      pickup: widget.routeDetails.pickup.name,
      destination: widget.routeDetails.destination.name,
      pickupLocation: {
        'lat': widget.routeDetails.pickup.latitude,
        'lng': widget.routeDetails.pickup.longitude,
      },
      destinationLocation: {
        'lat': widget.routeDetails.destination.latitude,
        'lng': widget.routeDetails.destination.longitude,
      },
      vehicleType: widget.selectedVehicle.title,
      fare: widget.fareDetails.effectiveFinalFare,
      distance: widget.routeDetails.distanceKm,
      estimatedTime: widget.routeDetails.estimatedMinutes,
      status: SharedRideStatus.requested,
      requestedAt: DateTime.now(),
      offerId: appliedOffer?.id,
      couponCode: appliedOffer?.couponCode,
      originalFare: widget.fareDetails.originalFare,
      discountAmount: widget.fareDetails.totalDiscount,
    );

    // Save to Firestore
    await fbService.createRideRequest(sharedRide);

    // Create RideRequest object for UI / Local State
    final rideRequest = RideRequest.create(
      routeDetails: widget.routeDetails,
      selectedVehicle: widget.selectedVehicle,
      fareDetails: widget.fareDetails,
      paymentMethod: _selectedPaymentMethod,
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isRequesting = false;
    });

    // Navigate to Step 9: Finding Captain Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => FindingCaptainScreen(
          rideRequest: rideRequest,
          firestoreRideId: rideId,
        ),
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
          'Confirm Your Ride',
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
                    // Header Section
                    _buildHeaderSection(),
                    const SizedBox(height: AppDimensions.space16),

                    // Trip Summary Card
                    _buildTripSummaryCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Vehicle & Fare Summary Card
                    _buildVehicleAndFareCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Payment Method Selector
                    _buildPaymentMethodSection(),
                    const SizedBox(height: AppDimensions.space16),

                    // Safety & Dispatch Notice Card
                    _buildSafetyNoticeCard(),
                    const SizedBox(height: AppDimensions.space20),
                  ],
                ),
              ),
            ),

            // Bottom Request Button
            _buildBottomBar(),
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
          'Confirm Your Ride',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Please check your ride details before requesting your ride.',
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.route_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'PICKUP & DESTINATION',
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

          // Pickup Location
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
                        fontSize: 13.5,
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

          // Destination Location
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
                        fontSize: 13.5,
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

          // Distance and Duration Metrics
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

  Widget _buildVehicleAndFareCard() {
    final vehicle = widget.selectedVehicle;
    final fare = widget.fareDetails;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.2),
                      ),
                      child: Icon(vehicle.icon, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
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
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'LOCKED FARE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    fare.offerDiscount > 0
                        ? fare.formattedEffectiveFinalFare
                        : fare.formattedFinalFare,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (fare.discount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'FIRST50 applied: Saved ${fare.formattedDiscount}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (fare.offerDiscount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF10B981), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${fare.offerLabel ?? "Offer"}: Saved ${fare.formattedOfferDiscount}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
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

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT METHOD',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Row(
          children: [
            Expanded(
              child: _buildPaymentTile(
                method: PaymentMethod.cash,
                title: 'Cash',
                subtitle: 'Pay driver directly',
                icon: Icons.payments_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPaymentTile(
                method: PaymentMethod.online,
                title: 'Online Payment',
                subtitle: 'UPI / Card / Wallet',
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentTile({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return InkWell(
      onTap: () => _handleSelectPayment(method),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevatedDark : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderDark,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.secondary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Verified nearby Captain will be assigned immediately after requesting.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
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
        text: 'Request QuickRide',
        onPressed: _handleRequestRide,
        isLoading: _isRequesting,
        icon: Icons.local_taxi_rounded,
      ),
    );
  }
}
