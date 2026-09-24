import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../models/ride_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/primary_button.dart';
import '../rating_review/rating_review_screen.dart';
import 'digital_receipt_screen.dart';

/// STEP 37: Payment Success Screen.
///
/// Features:
/// 1. Prominent checkmark badge, "Payment Successful" confirmation.
/// 2. Receipt Summary: Amount paid, Ride ID, Payment ID, Date/Time, Payment Method.
/// 3. Direct navigation to "Rate Your Ride", "View Digital Receipt", and "Home".
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.rideRequest,
    required this.payment,
  });

  final RideRequest rideRequest;
  final FirestorePaymentModel payment;

  void _handleRateRide(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RatingReviewScreen(rideRequest: rideRequest),
      ),
    );
  }

  void _handleViewReceipt(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DigitalReceiptScreen(
          payment: payment,
          rideRequest: rideRequest,
        ),
      ),
    );
  }

  void _handleGoHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paidDate = payment.paidAt ?? DateTime.now();
    final formattedTime =
        '${paidDate.day.toString().padLeft(2, '0')}/${paidDate.month.toString().padLeft(2, '0')}/${paidDate.year} at ${paidDate.hour.toString().padLeft(2, '0')}:${paidDate.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20, vertical: AppDimensions.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Icon Badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF10B981),
                  size: 52,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),

              // Title & Subtitle
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment of ₹${payment.finalAmount.toStringAsFixed(0)} was verified successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),

              // Receipt Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.borderDark, width: 1.2),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Ride ID', rideRequest.rideId),
                    const Divider(color: AppColors.borderDark, height: 16),
                    _buildReceiptRow('Payment ID', payment.paymentId),
                    const Divider(color: AppColors.borderDark, height: 16),
                    _buildReceiptRow('Payment Method', payment.paymentMethod.toUpperCase()),
                    const Divider(color: AppColors.borderDark, height: 16),
                    _buildReceiptRow('Date & Time', formattedTime),
                    const Divider(color: AppColors.borderDark, height: 16),
                    _buildReceiptRow(
                      'Amount Paid',
                      '₹${payment.finalAmount.toStringAsFixed(0)}',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              OutlinedButton.icon(
                onPressed: () => _handleViewReceipt(context),
                icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                label: const Text(
                  'View Digital Receipt & Invoice',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'Rate Your Ride',
                icon: Icons.star_rate_rounded,
                onPressed: () => _handleRateRide(context),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _handleGoHome(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
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
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 12.5,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
            color: isHighlight ? const Color(0xFF10B981) : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
