import 'package:flutter/material.dart';

/// Centralized application settings data model for QuickRide.
///
/// Encapsulates preferences for notifications, safety, appearance, language,
/// location, privacy, and data usage.
class AppSettings {
  const AppSettings({
    this.rideNotificationsEnabled = true,
    this.offerNotificationsEnabled = true,
    this.safetyNotificationsEnabled = true,
    this.generalNotificationsEnabled = true,
    this.safetyRemindersEnabled = true,
    this.vehicleVerificationEnabled = true,
    this.tripSharingReminderEnabled = true,
    this.themeMode = ThemeMode.dark,
    this.language = 'en',
    this.locationServicesEnabled = true,
    this.personalizedOffersEnabled = true,
    this.dataUsageOptimized = false,
  });

  final bool rideNotificationsEnabled;
  final bool offerNotificationsEnabled;
  final bool safetyNotificationsEnabled;
  final bool generalNotificationsEnabled;
  final bool safetyRemindersEnabled;
  final bool vehicleVerificationEnabled;
  final bool tripSharingReminderEnabled;
  final ThemeMode themeMode;
  final String language;
  final bool locationServicesEnabled;
  final bool personalizedOffersEnabled;
  final bool dataUsageOptimized;

  String get themeModeName {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String get languageName {
    switch (language) {
      case 'te':
        return 'Telugu';
      case 'en':
      default:
        return 'English';
    }
  }

  AppSettings copyWith({
    bool? rideNotificationsEnabled,
    bool? offerNotificationsEnabled,
    bool? safetyNotificationsEnabled,
    bool? generalNotificationsEnabled,
    bool? safetyRemindersEnabled,
    bool? vehicleVerificationEnabled,
    bool? tripSharingReminderEnabled,
    ThemeMode? themeMode,
    String? language,
    bool? locationServicesEnabled,
    bool? personalizedOffersEnabled,
    bool? dataUsageOptimized,
  }) {
    return AppSettings(
      rideNotificationsEnabled:
          rideNotificationsEnabled ?? this.rideNotificationsEnabled,
      offerNotificationsEnabled:
          offerNotificationsEnabled ?? this.offerNotificationsEnabled,
      safetyNotificationsEnabled:
          safetyNotificationsEnabled ?? this.safetyNotificationsEnabled,
      generalNotificationsEnabled:
          generalNotificationsEnabled ?? this.generalNotificationsEnabled,
      safetyRemindersEnabled:
          safetyRemindersEnabled ?? this.safetyRemindersEnabled,
      vehicleVerificationEnabled:
          vehicleVerificationEnabled ?? this.vehicleVerificationEnabled,
      tripSharingReminderEnabled:
          tripSharingReminderEnabled ?? this.tripSharingReminderEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      locationServicesEnabled:
          locationServicesEnabled ?? this.locationServicesEnabled,
      personalizedOffersEnabled:
          personalizedOffersEnabled ?? this.personalizedOffersEnabled,
      dataUsageOptimized: dataUsageOptimized ?? this.dataUsageOptimized,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideNotificationsEnabled': rideNotificationsEnabled,
      'offerNotificationsEnabled': offerNotificationsEnabled,
      'safetyNotificationsEnabled': safetyNotificationsEnabled,
      'generalNotificationsEnabled': generalNotificationsEnabled,
      'safetyRemindersEnabled': safetyRemindersEnabled,
      'vehicleVerificationEnabled': vehicleVerificationEnabled,
      'tripSharingReminderEnabled': tripSharingReminderEnabled,
      'themeMode': themeMode.name,
      'language': language,
      'locationServicesEnabled': locationServicesEnabled,
      'personalizedOffersEnabled': personalizedOffersEnabled,
      'dataUsageOptimized': dataUsageOptimized,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    ThemeMode parsedTheme = ThemeMode.dark;
    final themeStr = json['themeMode'] as String?;
    if (themeStr != null) {
      for (final mode in ThemeMode.values) {
        if (mode.name == themeStr) {
          parsedTheme = mode;
          break;
        }
      }
    }

    return AppSettings(
      rideNotificationsEnabled:
          json['rideNotificationsEnabled'] as bool? ?? true,
      offerNotificationsEnabled:
          json['offerNotificationsEnabled'] as bool? ?? true,
      safetyNotificationsEnabled:
          json['safetyNotificationsEnabled'] as bool? ?? true,
      generalNotificationsEnabled:
          json['generalNotificationsEnabled'] as bool? ?? true,
      safetyRemindersEnabled: json['safetyRemindersEnabled'] as bool? ?? true,
      vehicleVerificationEnabled:
          json['vehicleVerificationEnabled'] as bool? ?? true,
      tripSharingReminderEnabled:
          json['tripSharingReminderEnabled'] as bool? ?? true,
      themeMode: parsedTheme,
      language: json['language'] as String? ?? 'en',
      locationServicesEnabled:
          json['locationServicesEnabled'] as bool? ?? true,
      personalizedOffersEnabled:
          json['personalizedOffersEnabled'] as bool? ?? true,
      dataUsageOptimized: json['dataUsageOptimized'] as bool? ?? false,
    );
  }
}
