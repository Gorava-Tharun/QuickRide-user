import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../profile/privacy_policy_screen.dart';
import '../profile/terms_conditions_screen.dart';

/// About screen for QuickRide displaying brand identity, application versions,
/// legal links, and open-source acknowledgements.
class AboutQuickRideScreen extends StatelessWidget {
  const AboutQuickRideScreen({super.key});

  static const String devVersion = 'v1.0.0-dev (Step 19)';

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
          tooltip: 'Back',
        ),
        title: const Text(
          'About QuickRide',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimensions.space16),

              // Brand Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.directions_car_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'QuickRide',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ride. Travel. Arrive.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Text(
                        'Version ${AppStrings.appVersion} • $devVersion',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space20),

              // About Section Header
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ABOUT QUICKRIDE',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space12),

              // Description Card
              Material(
                color: AppColors.cardDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  side: const BorderSide(color: AppColors.borderDark),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppDimensions.space16),
                  child: Text(
                    'QuickRide is an on-demand urban mobility platform engineered for speed, safety, and reliability. Whether commuting across the city on a bike, traveling with family in a car, or taking an auto for a quick errand, QuickRide connects riders with verified captains in real-time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space20),

              // Legal & Information Links
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LEGAL & LICENSES',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space12),

              Material(
                color: AppColors.cardDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  side: const BorderSide(color: AppColors.borderDark),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                      title: const Text(
                        'Terms & Conditions',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TermsConditionsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: AppColors.borderDark, height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_rounded, color: AppColors.primary, size: 20),
                      title: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: AppColors.borderDark, height: 1),
                    ListTile(
                      leading: const Icon(Icons.code_rounded, color: AppColors.primary, size: 20),
                      title: const Text(
                        'Open-Source Acknowledgements',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'QuickRide',
                          applicationVersion: AppStrings.appVersion,
                          applicationLegalese: 'QuickRide Mobility Solutions — Development Version',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space24),

              Text(
                '© 2026 QuickRide. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
            ],
          ),
        ),
      ),
    );
  }
}
