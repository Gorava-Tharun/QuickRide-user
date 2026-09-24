import '../models/app_settings_model.dart';

/// Contract interface defining application settings operations.
abstract interface class SettingsRepository {
  /// Retrieves current application settings.
  Future<AppSettings> getSettings();

  /// Persists full application settings.
  Future<void> saveSettings(AppSettings settings);

  /// Updates application settings.
  Future<void> updateSettings(AppSettings settings);

  /// Resets all application settings to default.
  Future<void> resetSettings();
}
