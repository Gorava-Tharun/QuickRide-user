import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';
import '../models/safety_preferences_model.dart';
import 'notification_service.dart';
import 'ride_history_service.dart';
import 'ride_review_service.dart';
import 'safety_service.dart';
import 'session_manager.dart';
import 'settings_repository.dart';
import 'support_service.dart';

/// Centralized service managing application settings, theme mode, language,
/// notifications, safety preferences, and local data clearing.
class SettingsService extends ChangeNotifier implements SettingsRepository {
  SettingsService._internal() {
    _loadSettings();
  }

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  static const String _settingsKey = 'quickride_app_settings';

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  ThemeMode get themeMode => _settings.themeMode;
  String get language => _settings.language;
  Locale get locale => Locale(_settings.language);
  bool get locationServicesEnabled => _settings.locationServicesEnabled;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(map);
      } else {
        // Sync with existing SafetyService preferences if available
        final safetyPrefs = SafetyService().preferences;
        _settings = _settings.copyWith(
          safetyRemindersEnabled: safetyPrefs.showSafetyReminders,
          vehicleVerificationEnabled: safetyPrefs.showVehicleVerificationReminder,
          tripSharingReminderEnabled: safetyPrefs.showTripSharingReminder,
        );
      }
      notifyListeners();
    } catch (_) {
      // In testing or environments without SharedPreferences
    }
  }

  @override
  Future<AppSettings> getSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(AppSettings newSettings) async {
    await updateSettings(newSettings);
  }

  @override
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    // Synchronize safety preferences with Step 18 SafetyService
    SafetyService().updatePreferences(
      SafetyPreferences(
        showSafetyReminders: newSettings.safetyRemindersEnabled,
        showVehicleVerificationReminder: newSettings.vehicleVerificationEnabled,
        showTripSharingReminder: newSettings.tripSharingReminderEnabled,
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(newSettings.toJson()));
    } catch (_) {}
  }

  /// Sets global theme mode (System, Light, or Dark).
  Future<void> setThemeMode(ThemeMode mode) async {
    await updateSettings(_settings.copyWith(themeMode: mode));
  }

  /// Sets active language ('en' or 'te').
  Future<void> setLanguage(String lang) async {
    await updateSettings(_settings.copyWith(language: lang));
  }

  /// Toggles location services preference.
  Future<void> setLocationServicesEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(locationServicesEnabled: enabled));
  }

  /// Toggles personalized offers preference.
  Future<void> setPersonalizedOffers(bool enabled) async {
    await updateSettings(_settings.copyWith(personalizedOffersEnabled: enabled));
  }

  @override
  Future<void> resetSettings() async {
    _settings = const AppSettings();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
    } catch (_) {}

    SafetyService().resetToDefault();
  }

  /// Clears demo account credentials and session data.
  Future<void> deleteAccount() async {
    SessionManager().logout();
    SessionManager().resetToDefault();
    notifyListeners();
  }

  /// Clears all local demo data: ride history, reviews, notifications,
  /// support tickets, safety preferences, and logs out the session.
  Future<void> clearAllLocalData() async {
    // 1. Clear session
    SessionManager().logout();
    SessionManager().resetToDefault();

    // 2. Clear notifications
    NotificationService().clearAll();

    // 3. Clear ride history
    RideHistoryService().clearHistory();

    // 4. Clear ride reviews
    await RideReviewService().clearAll();

    // 5. Reset support requests
    SupportService().resetToDefault();

    // 6. Reset safety settings
    SafetyService().resetToDefault();

    // 7. Reset app settings
    await resetSettings();

    notifyListeners();
  }

  /// Resets SettingsService to clean defaults for tests.
  void resetToDefault() {
    _settings = const AppSettings();
    notifyListeners();
  }
}
