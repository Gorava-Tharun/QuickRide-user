/// User preferences for safety reminders and verification prompts.
class SafetyPreferences {
  const SafetyPreferences({
    this.showSafetyReminders = true,
    this.showVehicleVerificationReminder = true,
    this.showTripSharingReminder = true,
  });

  final bool showSafetyReminders;
  final bool showVehicleVerificationReminder;
  final bool showTripSharingReminder;

  SafetyPreferences copyWith({
    bool? showSafetyReminders,
    bool? showVehicleVerificationReminder,
    bool? showTripSharingReminder,
  }) {
    return SafetyPreferences(
      showSafetyReminders: showSafetyReminders ?? this.showSafetyReminders,
      showVehicleVerificationReminder:
          showVehicleVerificationReminder ?? this.showVehicleVerificationReminder,
      showTripSharingReminder:
          showTripSharingReminder ?? this.showTripSharingReminder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showSafetyReminders': showSafetyReminders,
      'showVehicleVerificationReminder': showVehicleVerificationReminder,
      'showTripSharingReminder': showTripSharingReminder,
    };
  }

  factory SafetyPreferences.fromJson(Map<String, dynamic> json) {
    return SafetyPreferences(
      showSafetyReminders: json['showSafetyReminders'] as bool? ?? true,
      showVehicleVerificationReminder:
          json['showVehicleVerificationReminder'] as bool? ?? true,
      showTripSharingReminder:
          json['showTripSharingReminder'] as bool? ?? true,
    );
  }
}
