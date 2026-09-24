// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import '../../core/constants/app_dimensions.dart';
import '../../models/app_settings_model.dart';
import '../../routes/app_routes.dart';
import '../../services/session_manager.dart';
import '../../services/settings_service.dart';
import '../profile/edit_profile_screen.dart';
import 'about_quickride_screen.dart';
import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';

/// STEP 19: Comprehensive Settings Screen for QuickRide User App.
///
/// Provides centralized configuration for notifications, safety, appearance,
/// language, location, privacy, account management, about information, and local data clearing.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
  }

  // ── Appearance Modal ────────────────────────────────────────────────────────
  void _showThemeModeDialog(ThemeMode currentMode) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Text(
          'Choose Appearance',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeRadioTile(ctx, 'System Default', ThemeMode.system, currentMode),
            _buildThemeRadioTile(ctx, 'Light Mode', ThemeMode.light, currentMode),
            _buildThemeRadioTile(ctx, 'Dark Mode', ThemeMode.dark, currentMode),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeRadioTile(
    BuildContext dialogCtx,
    String label,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    return RadioListTile<ThemeMode>(
      activeColor: AppColors.primary,
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      ),
      value: mode,
      groupValue: currentMode,
      onChanged: (selected) {
        if (selected != null) {
          _settingsService.setThemeMode(selected);
          Navigator.of(dialogCtx).pop();
        }
      },
    );
  }

  // ── Language Modal ──────────────────────────────────────────────────────────
  void _showLanguageDialog(String currentLang) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Text(
          'Select Language',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              activeColor: AppColors.primary,
              title: const Text(
                'English',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              subtitle: const Text(
                'Default application language',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              value: 'en',
              groupValue: currentLang,
              onChanged: (val) {
                if (val != null) {
                  _settingsService.setLanguage(val);
                  Navigator.of(ctx).pop();
                }
              },
            ),
            const Divider(color: AppColors.borderDark, height: 1),
            RadioListTile<String>(
              activeColor: AppColors.primary,
              title: const Text(
                'Telugu (తెలుగు)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              subtitle: const Text(
                'Telugu language support is being prepared.',
                style: TextStyle(fontSize: 12, color: Color(0xFFEAB308), fontWeight: FontWeight.w500),
              ),
              value: 'te',
              groupValue: currentLang,
              onChanged: (val) {
                if (val != null) {
                  _settingsService.setLanguage(val);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Telugu language support is being prepared.'),
                      backgroundColor: AppColors.surfaceDark,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Location Modal ──────────────────────────────────────────────────────────
  void _showLocationPermissionDialog(bool isEnabled) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: Row(
          children: const [
            Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Location Services',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnabled
                  ? 'Location services are currently enabled for QuickRide.'
                  : 'Location services are currently disabled. Real-time pickup accuracy and captain tracking may be limited.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondaryLight,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Text(
                'On supported mobile platforms, tap below to toggle permission simulation or open device settings.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _settingsService.setLocationServicesEnabled(!isEnabled);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    !isEnabled
                        ? 'Location services enabled.'
                        : 'Location services disabled.',
                  ),
                  backgroundColor: AppColors.surfaceDark,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            child: Text(
              isEnabled ? 'Disable Permission' : 'Enable Permission',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout Flow ─────────────────────────────────────────────────────────────
  void _handleLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Text(
          'Logout of QuickRide?',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'You will be returned to the login screen. Your ride history and profile data will remain intact.',
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SessionManager().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete Account Flow ─────────────────────────────────────────────────────
  void _handleDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete your QuickRide account?',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'This action will remove your local account data from this application. Because this is a development version without a live server, no cloud records are affected.',
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _settingsService.deleteAccount();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local account data has been removed.'),
                    backgroundColor: AppColors.surfaceDark,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Clear Local Data Flow ───────────────────────────────────────────────────
  void _handleClearLocalData() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Clear local QuickRide data?',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will remove locally stored demo preferences, session data, notifications, reviews and ride history.\n\nYou will be returned to the login screen.',
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _settingsService.clearAllLocalData();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local QuickRide demo data has been cleared.'),
                    backgroundColor: AppColors.surfaceDark,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            child: const Text(
              'Clear Data',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build Screen ────────────────────────────────────────────────────────────
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
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _settingsService,
          builder: (context, _) {
            final settings = _settingsService.settings;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. NOTIFICATIONS SECTION
                  _buildSectionHeader('NOTIFICATIONS'),
                  _buildNotificationsCard(settings),
                  const SizedBox(height: AppDimensions.space20),

                  // 2. SAFETY SECTION
                  _buildSectionHeader('SAFETY'),
                  _buildSafetyCard(settings),
                  const SizedBox(height: AppDimensions.space20),

                  // 3. APP APPEARANCE
                  _buildSectionHeader('APPEARANCE'),
                  _buildAppearanceCard(settings),
                  const SizedBox(height: AppDimensions.space20),

                  // 4. LANGUAGE
                  _buildSectionHeader('LANGUAGE'),
                  _buildLanguageCard(settings),
                  const SizedBox(height: AppDimensions.space20),

                  // 5. LOCATION
                  _buildSectionHeader('LOCATION'),
                  _buildLocationCard(settings),
                  const SizedBox(height: AppDimensions.space20),

                  // 6. PRIVACY & PERSONALIZATION
                  _buildSectionHeader('PRIVACY'),
                  _buildPrivacyCard(settings),
                  const SizedBox(height: AppDimensions.space20),

                  // 7. ACCOUNT SETTINGS
                  _buildSectionHeader('ACCOUNT'),
                  _buildAccountCard(),
                  const SizedBox(height: AppDimensions.space20),

                  // 8. ABOUT QUICKRIDE
                  _buildSectionHeader('ABOUT'),
                  _buildAboutCard(),
                  const SizedBox(height: AppDimensions.space20),

                  // 9. DATA & STORAGE (DEVELOPER OPTION)
                  _buildSectionHeader('DATA & STORAGE'),
                  _buildDataManagementCard(),
                  const SizedBox(height: AppDimensions.space32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // 1. Notifications Card
  Widget _buildNotificationsCard(AppSettings settings) {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Ride Notifications',
            subtitle: 'Captain updates, arrival alerts, and trip receipts',
            value: settings.rideNotificationsEnabled,
            onChanged: (val) {
              _settingsService.updateSettings(
                settings.copyWith(rideNotificationsEnabled: val),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildSwitchTile(
            title: 'Offer Notifications',
            subtitle: 'Discounts, seasonal rewards, and promo codes',
            value: settings.offerNotificationsEnabled,
            onChanged: (val) {
              _settingsService.updateSettings(
                settings.copyWith(offerNotificationsEnabled: val),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildSwitchTile(
            title: 'Safety Reminders',
            subtitle: 'Verification alerts and nighttime journey safety tips',
            value: settings.safetyNotificationsEnabled,
            onChanged: (val) {
              _settingsService.updateSettings(
                settings.copyWith(safetyNotificationsEnabled: val),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildSwitchTile(
            title: 'General Notifications',
            subtitle: 'Platform updates, terms advisories, and system notices',
            value: settings.generalNotificationsEnabled,
            onChanged: (val) {
              _settingsService.updateSettings(
                settings.copyWith(generalNotificationsEnabled: val),
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. Safety Card
  Widget _buildSafetyCard(AppSettings settings) {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Safety Reminders',
            subtitle: 'Remind you of safe travel practices when booking rides',
            value: settings.safetyRemindersEnabled,
            onChanged: (val) {
              _settingsService.updateSettings(
                settings.copyWith(safetyRemindersEnabled: val),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildSwitchTile(
            title: 'Vehicle Verification Reminder',
            subtitle: 'Check registration number and captain identity upon arrival',
            value: settings.vehicleVerificationEnabled,
            onChanged: (val) {
              _settingsService.updateSettings(
                settings.copyWith(vehicleVerificationEnabled: val),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildSwitchTile(
            title: 'Trip Sharing Reminder',
            subtitle: 'Prompt to share live trip telemetry with your emergency contact',
            value: settings.tripSharingReminderEnabled,
            onChanged: (val) {
              _settingsService.updateSettings(
                settings.copyWith(tripSharingReminderEnabled: val),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Appearance Card
  Widget _buildAppearanceCard(AppSettings settings) {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ListTile(
        leading: const Icon(Icons.palette_outlined, color: AppColors.primary, size: 22),
        title: const Text(
          'App Appearance',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
        ),
        subtitle: Text(
          settings.themeModeName,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
        onTap: () => _showThemeModeDialog(settings.themeMode),
      ),
    );
  }

  // 4. Language Card
  Widget _buildLanguageCard(AppSettings settings) {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ListTile(
        leading: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
        title: const Text(
          'Language',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
        ),
        subtitle: Text(
          settings.languageName,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
        onTap: () => _showLanguageDialog(settings.language),
      ),
    );
  }

  // 5. Location Card
  Widget _buildLocationCard(AppSettings settings) {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 22),
            title: const Text(
              'Location Services',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
            ),
            subtitle: Text(
              settings.locationServicesEnabled ? 'Status: Enabled' : 'Status: Disabled',
              style: TextStyle(
                fontSize: 12.5,
                color: settings.locationServicesEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (settings.locationServicesEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Text(
                settings.locationServicesEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: settings.locationServicesEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          ListTile(
            leading: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
            title: const Text(
              'Manage Location Permission',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
            ),
            subtitle: const Text(
              'Configure permissions and GPS tracking preferences',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
            onTap: () => _showLocationPermissionDialog(settings.locationServicesEnabled),
          ),
        ],
      ),
    );
  }

  // 6. Privacy Card
  Widget _buildPrivacyCard(AppSettings settings) {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 22),
            title: const Text(
              'Privacy Settings',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
            ),
            subtitle: const Text(
              'Permissions, personalized offers, and data optimization',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildSwitchTile(
            title: 'Personalized Offers',
            subtitle: 'Tailored discounts based on ride patterns (evaluated locally)',
            value: settings.personalizedOffersEnabled,
            onChanged: (val) {
              _settingsService.setPersonalizedOffers(val);
            },
          ),
        ],
      ),
    );
  }

  // 7. Account Card
  Widget _buildAccountCard() {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
            title: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
            ),
            subtitle: const Text(
              'Update your name, phone number, and email',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 22),
            title: const Text(
              'Change Password',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
            ),
            subtitle: const Text(
              'Manage your password credentials',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            title: const Text(
              'Logout',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.error),
            ),
            subtitle: const Text(
              'End current session on this device',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
            onTap: _handleLogout,
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
            title: const Text(
              'Delete Account',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
            ),
            subtitle: const Text(
              'Remove your local account data from this application',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
            onTap: _handleDeleteAccount,
          ),
        ],
      ),
    );
  }

  // 8. About Card
  Widget _buildAboutCard() {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ListTile(
        leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
        title: const Text(
          'About QuickRide',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
        ),
        subtitle: const Text(
          'App details, version info, terms & licenses',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AboutQuickRideScreen(),
            ),
          );
        },
      ),
    );
  }

  // 9. Data & Storage Card (Developer Option)
  Widget _buildDataManagementCard() {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ListTile(
        leading: const Icon(Icons.cleaning_services_rounded, color: Color(0xFFEF4444), size: 22),
        title: const Text(
          'Clear Local Data',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
        ),
        subtitle: const Text(
          'Wipe demo preferences, ride history, reviews & notifications',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 20),
        onTap: _handleClearLocalData,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
      inactiveThumbColor: AppColors.textSecondaryLight,
      inactiveTrackColor: AppColors.surfaceElevatedDark,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
