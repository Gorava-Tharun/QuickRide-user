import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/safety_service.dart';

/// Screen allowing the user to configure safety alerts and reminders.
class SafetyPreferencesScreen extends StatelessWidget {
  const SafetyPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safetyService = SafetyService();

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
          'Safety Preferences',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: safetyService,
          builder: (context, _) {
            final prefs = safetyService.preferences;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Information Header
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
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Customize which safety reminders and prompts you receive during your QuickRide journeys.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  const Text(
                    'REMINDERS & NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Switches Card
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
                            'Show safety reminders',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: const Text(
                            'Receive general safety tips and guidelines when booking rides',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          value: prefs.showSafetyReminders,
                          onChanged: (val) {
                            safetyService.updatePreferences(
                              prefs.copyWith(showSafetyReminders: val),
                            );
                          },
                        ),
                        const Divider(color: AppColors.borderDark, height: 1),

                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                          inactiveThumbColor: AppColors.textSecondaryLight,
                          inactiveTrackColor: AppColors.surfaceElevatedDark,
                          title: const Text(
                            'Show vehicle verification reminder',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: const Text(
                            'Remind you to check license plate and captain details upon arrival',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          value: prefs.showVehicleVerificationReminder,
                          onChanged: (val) {
                            safetyService.updatePreferences(
                              prefs.copyWith(showVehicleVerificationReminder: val),
                            );
                          },
                        ),
                        const Divider(color: AppColors.borderDark, height: 1),

                        SwitchListTile(
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                          inactiveThumbColor: AppColors.textSecondaryLight,
                          inactiveTrackColor: AppColors.surfaceElevatedDark,
                          title: const Text(
                            'Show trip-sharing reminder',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: const Text(
                            'Prompt to share live trip details with trusted contacts once on the way',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                          value: prefs.showTripSharingReminder,
                          onChanged: (val) {
                            safetyService.updatePreferences(
                              prefs.copyWith(showTripSharingReminder: val),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
