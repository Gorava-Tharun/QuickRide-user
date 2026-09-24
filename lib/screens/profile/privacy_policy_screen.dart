import "package:flutter/material.dart";
import "../../core/constants/app_colors.dart";
import "../../core/constants/app_dimensions.dart";

/// STEP 15: Privacy Policy Screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          "Privacy Policy",
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
                  "QuickRide Privacy Policy",
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
                  "1. Information We Collect\n"
                  "We collect information you provide directly, including your name, mobile number, email address, and pickup/destination preferences.\n\n"
                  "2. Location Data\n"
                  "With your permission, QuickRide accesses precise GPS location data to facilitate accurate pickup matching, route optimization, and live tracking.\n\n"
                  "3. How We Use Information\n"
                  "Your information is used strictly to fulfill ride bookings, process payments, provide customer support, and improve our services.\n\n"
                  "4. Data Protection\n"
                  "We implement industry-standard encryption and security protocols to safeguard your personal data against unauthorized access.\n\n"
                  "5. Your Rights\n"
                  "You can update or delete your profile information at any time from your account settings.",
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
