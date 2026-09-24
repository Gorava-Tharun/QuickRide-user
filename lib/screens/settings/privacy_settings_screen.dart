import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/settings_service.dart';
import '../profile/privacy_policy_screen.dart';

/// Screen allowing riders to manage privacy preferences, location permissions,
/// personalized offer recommendations, and data optimization.
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();

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
          'Privacy & Data',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: settingsService,
          builder: (context, _) {
            final settings = settingsService.settings;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Privacy Commitment Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Privacy is Protected',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'QuickRide respects your data rights. No telemetry is sold to advertisers, and all preferences are configured locally on your device.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section: PERMISSIONS & ACCESS
                  const Text(
                    'PERMISSIONS & ACCESS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
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
                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                          inactiveThumbColor: AppColors.textSecondaryLight,
                          inactiveTrackColor: AppColors.surfaceElevatedDark,
                          title: const Text(
                            'Location Access',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: const Text(
                            'Used strictly for real-time pickup accuracy, route navigation, and captain distance calculation',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          value: settings.locationServicesEnabled,
                          onChanged: (val) {
                            settingsService.setLocationServicesEnabled(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section: PREFERENCES & PERSONALIZATION
                  const Text(
                    'PREFERENCES & DATA USAGE',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
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
                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                          inactiveThumbColor: AppColors.textSecondaryLight,
                          inactiveTrackColor: AppColors.surfaceElevatedDark,
                          title: const Text(
                            'Personalized Offers',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: const Text(
                            'Receive tailored discounts and promotional fares based on your ride habits. Evaluated locally on this device.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          value: settings.personalizedOffersEnabled,
                          onChanged: (val) {
                            settingsService.setPersonalizedOffers(val);
                          },
                        ),
                        const Divider(color: AppColors.borderDark, height: 1),
                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                          inactiveThumbColor: AppColors.textSecondaryLight,
                          inactiveTrackColor: AppColors.surfaceElevatedDark,
                          title: const Text(
                            'Optimize Data Usage',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: const Text(
                            'Minimizes background network refresh and caches route visual assets locally.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          value: settings.dataUsageOptimized,
                          onChanged: (val) {
                            settingsService.updateSettings(
                              settings.copyWith(dataUsageOptimized: val),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Section: POLICY
                  const Text(
                    'LEGAL & TRANSPARENCY',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  Material(
                    color: AppColors.cardDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      side: const BorderSide(color: AppColors.borderDark),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.privacy_tip_rounded, color: AppColors.primary, size: 20),
                      title: const Text(
                        'Read QuickRide Privacy Policy',
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
                  ),
                  const SizedBox(height: AppDimensions.space24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
