import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/ride_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/fare_breakdown_card.dart';
import '../../widgets/primary_button.dart';
import '../rating_review/rating_review_screen.dart';

/// STEP 11: Ride Completed Screen.
///
/// Features:
/// 1. Celebration Header: "Ride Completed 🎉" with success checkmark visual.
/// 2. Trip Summary Card (Pickup, Destination, Vehicle, Distance, Duration).
/// 3. Final Fare Breakdown Card (Base, Distance, Time, Discount, Total Paid).
/// 4. Payment Method Indicator (Cash vs Online Payment).
/// 5. Captain Summary Card (Name, 4.8 ★ Rating, Vehicle Model, Plate number).
/// 6. Action Control: "Rate Your Ride" (Step 12 placeholder) & "Back to Home" (returns to HomeScreen while preserving history).
class RideCompletedScreen extends StatelessWidget {
  const RideCompletedScreen({
    super.key,
    required this.rideRequest,
  });

  final RideRequest rideRequest;

  void _handleRateRide(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RatingReviewScreen(rideRequest: rideRequest),
      ),
    );
  }

  void _handlePayNow(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.payment,
      arguments: rideRequest,
    );
  }

  void _handleBackToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final captain = rideRequest.captain ??
        CaptainModel.demo(vehicleCategoryTitle: rideRequest.selectedVehicle.title);
    final fare = rideRequest.fareDetails;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space16,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Success Checkmark Badge
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space16),

                    const Text(
                      'Ride Completed 🎉',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Thank you for riding with QuickRide!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space20),

                    // Trip Summary Card
                    _buildTripSummaryCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Final Fare Breakdown Card
                    FareBreakdownCard(fareDetails: fare),
                    const SizedBox(height: AppDimensions.space16),

                    // Payment Method Card
                    _buildPaymentMethodCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Captain Summary Card
                    _buildCaptainSummaryCard(captain),
                    const SizedBox(height: AppDimensions.space24),
                  ],
                ),
              ),
            ),

            // Bottom Fixed Action Bar
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRIP SUMMARY',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Pickup Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rideRequest.pickup.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
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
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rideRequest.destination.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),

          // Metrics: Vehicle, Distance & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle: ${rideRequest.selectedVehicle.title}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
              ),
              Text(
                '${rideRequest.distanceKm.toStringAsFixed(1)} km • ${rideRequest.estimatedMinutes} min',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),

          // Completion Time Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Completed At:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
              ),
              Text(
                _formatCompletionTime(DateTime.now()),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatCompletionTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Widget _buildPaymentMethodCard() {
    final isPaid = rideRequest.paymentStatus == 'PAID';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isPaid ? const Color(0xFF10B981) : AppColors.borderDark,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Payment Method:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              Text(
                rideRequest.paymentMethodTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Status:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                      size: 14,
                      color: isPaid ? const Color(0xFF10B981) : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPaid ? 'PAID' : 'PENDING PAYMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isPaid ? const Color(0xFF10B981) : Colors.orange,
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

  Widget _buildCaptainSummaryCard(CaptainModel captain) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR CAPTAIN',
            style: TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      captain.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${captain.vehicleType} • ${captain.vehicleModel} (${captain.vehicleNumber})',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    captain.formattedRating,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isPaid = rideRequest.paymentStatus == 'PAID';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPaid) ...[
            PrimaryButton(
              text: 'Pay Now • ₹${rideRequest.fareDetails.finalFare.toStringAsFixed(0)}',
              onPressed: () => _handlePayNow(context),
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 8),
          ],
          if (isPaid)
            PrimaryButton(
              text: 'Rate Your Ride',
              onPressed: () => _handleRateRide(context),
              icon: Icons.star_rate_rounded,
            )
          else
            OutlinedButton.icon(
              onPressed: () => _handleRateRide(context),
              icon: const Icon(Icons.star_rate_rounded, size: 18),
              label: const Text('Rate Your Ride'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _handleBackToHome(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.borderDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
