import "package:flutter/material.dart";
import "../../core/constants/app_colors.dart";
import "../../core/constants/app_dimensions.dart";

/// STEP 15: Terms & Conditions Screen.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Back",
        ),
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.space20),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.borderDark, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "QuickRide Terms of Service",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Last updated: January 2026",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Divider(color: AppColors.borderDark, height: 24),
                Text(
                  "1. Acceptance of Terms\n"
                  "By creating an account and using QuickRide services, you agree to be bound by these Terms and Conditions. If you do not agree, please discontinue use immediately.\n\n"
                  "2. User Account and Security\n"
                  "You must provide accurate and complete information when registering. You are responsible for safeguarding your credentials and any activity occurring under your account.\n\n"
                  "3. Ride Booking and Pricing\n"
                  "Fares are calculated based on base rates, distance, and duration. Promotional discounts and coupons are subject to terms specified at the time of issue.\n\n"
                  "4. Cancellation Policy\n"
                  "Rides may be cancelled before a captain is dispatched or during arrival. Frequent cancellations may incur standard cancellation fees.\n\n"
                  "5. Safety and Conduct\n"
                  "QuickRide prioritizes passenger and captain safety. Harassment, misconduct, or unlawful activities will result in immediate account termination.",
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondaryLight,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
