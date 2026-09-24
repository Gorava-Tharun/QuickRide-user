import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/firestore_models.dart';
import '../models/notification_model.dart';
import '../models/ride_model.dart';
import '../models/safety_preferences_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Centralized service managing safety preferences, ride verification checks,
/// emergency incidents (SOS), and contextual safety notifications.
class SafetyService extends ChangeNotifier {
  SafetyService._internal() {
    _initPreferences();
    _resetChecklistState();
  }

  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;

  static const String _prefSafetyReminders = 'pref_safety_reminders';
  static const String _prefVehicleVerification = 'pref_vehicle_verification';
  static const String _prefTripSharing = 'pref_trip_sharing';

  SafetyPreferences _preferences = const SafetyPreferences();
  SafetyPreferences get preferences => _preferences;

  RideRequest? _activeRide;
  RideRequest? get activeRide => _activeRide;

  final Map<String, bool> _checklist = {};
  Map<String, bool> get checklist => Map.unmodifiable(_checklist);

  final Set<String> _sentVerificationRideIds = {};

  // Step 40: Active Emergency Incident State & Subscription
  FirestoreEmergencyIncidentModel? _activeEmergency;
  FirestoreEmergencyIncidentModel? get activeEmergency => _activeEmergency;
  bool get isEmergencyActive => _activeEmergency != null && _activeEmergency!.isActive;
  StreamSubscription<FirestoreEmergencyIncidentModel?>? _emergencySub;

  Future<void> _initPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preferences = SafetyPreferences(
        showSafetyReminders: prefs.getBool(_prefSafetyReminders) ?? true,
        showVehicleVerificationReminder:
            prefs.getBool(_prefVehicleVerification) ?? true,
        showTripSharingReminder: prefs.getBool(_prefTripSharing) ?? true,
      );
      notifyListeners();
    } catch (_) {
      // In tests or environments where SharedPreferences is mocked
    }
  }

  /// Updates safety preferences and persists changes locally.
  Future<void> updatePreferences(SafetyPreferences newPrefs) async {
    _preferences = newPrefs;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefSafetyReminders, newPrefs.showSafetyReminders);
      await prefs.setBool(_prefVehicleVerification, newPrefs.showVehicleVerificationReminder);
      await prefs.setBool(_prefTripSharing, newPrefs.showTripSharingReminder);
    } catch (_) {}
  }

  /// Associates an active ride with the safety center.
  void setActiveRide(RideRequest? ride) {
    _activeRide = ride;
    _resetChecklistState();
    notifyListeners();
  }

  void _resetChecklistState() {
    _checklist.clear();
    _checklist.addAll({
      'verify_vehicle': false,
      'verify_captain': false,
      'confirm_dest': false,
      'secure_belongings': false,
      'share_trip': false,
    });
  }

  /// Toggles an interactive safety checklist item.
  void toggleChecklistItem(String key) {
    if (_checklist.containsKey(key)) {
      _checklist[key] = !(_checklist[key] ?? false);
      notifyListeners();
    }
  }

  /// Resets the checklist to all unchecked (e.g. for a new ride).
  void resetChecklist() {
    _resetChecklistState();
    notifyListeners();
  }

  /// Emits a local "Verify Your Ride" notification if reminders are enabled
  /// and this ride hasn't already received one.
  void triggerVerificationNotification(String rideId) {
    if (!_preferences.showSafetyReminders ||
        !_preferences.showVehicleVerificationReminder) {
      return;
    }

    if (_sentVerificationRideIds.contains(rideId)) {
      return; // Prevent duplicate notifications
    }

    _sentVerificationRideIds.add(rideId);

    NotificationService().addNotification(
      AppNotification(
        id: 'notif_verify_ride_$rideId',
        type: NotificationType.general,
        title: 'Verify Your Ride',
        message: 'Please check your captain and vehicle details before starting your trip.',
        createdAt: DateTime.now(),
        isRead: false,
        rideId: rideId,
      ),
    );
  }

  // ==========================================================================
  // STEP 40: EMERGENCY SOS & TELEMETRY
  // ==========================================================================

  /// Triggers an emergency SOS for an active ride or user session
  Future<bool> triggerSOS({
    RideRequest? ride,
    String? userId,
    String? reason,
  }) async {
    final targetRide = ride ?? _activeRide;
    final effectiveUserId = userId ?? targetRide?.userId ?? 'demo_user';
    final rideId = targetRide?.rideId ?? 'RIDE_DIRECT_${DateTime.now().millisecondsSinceEpoch}';

    // Best-effort live location retrieval
    double lat = targetRide?.pickup.latitude ?? 12.9716;
    double lng = targetRide?.pickup.longitude ?? 77.5946;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 3),
          ),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {
      // Fallback gracefully to ride coordinates
    }

    final incident = FirestoreEmergencyIncidentModel(
      emergencyId: 'EMG_${rideId}_${DateTime.now().millisecondsSinceEpoch}',
      rideId: rideId,
      userId: effectiveUserId,
      captainId: targetRide?.captain?.id ?? '',
      latitude: lat,
      longitude: lng,
      status: EmergencyStatus.active,
      triggeredBy: 'user',
      userName: 'Rider',
      userPhone: '',
      captainName: targetRide?.captain?.name,
      captainPhone: targetRide?.captain?.phone,
      vehicleNumber: targetRide?.captain?.vehicleNumber,
      vehicleType: targetRide?.selectedVehicle.title,
      pickup: targetRide?.pickup.name,
      destination: targetRide?.destination.name,
      adminNotes: reason ?? 'Emergency SOS triggered by rider via QuickRide Safety Center',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await QuickRideFirebaseService().createEmergencyIncident(incident);
    if (success) {
      _activeEmergency = incident;
      _subscribeToActiveEmergency(effectiveUserId);
      notifyListeners();

      NotificationService().addNotification(
        AppNotification(
          id: 'notif_sos_${incident.emergencyId}',
          type: NotificationType.general,
          title: 'Emergency SOS Activated',
          message: 'QuickRide Safety Monitoring Desk has received your live alert. Help is being coordinated.',
          createdAt: DateTime.now(),
          isRead: false,
          rideId: rideId,
        ),
      );
    }
    return success;
  }

  /// Subscribe to active emergency updates from Firestore
  void _subscribeToActiveEmergency(String userId) {
    _emergencySub?.cancel();
    _emergencySub = QuickRideFirebaseService().streamActiveEmergency(userId).listen((emergency) {
      _activeEmergency = emergency;
      notifyListeners();
    });
  }

  /// Restores active emergency if one was created previously
  Future<void> restoreActiveEmergency(String userId) async {
    final existing = await QuickRideFirebaseService().fetchActiveEmergency(userId);
    if (existing != null) {
      _activeEmergency = existing;
      _subscribeToActiveEmergency(userId);
      notifyListeners();
    }
  }

  /// Updates emergency live location telemetry
  Future<bool> updateEmergencyLocation(double latitude, double longitude) async {
    if (_activeEmergency == null || !_activeEmergency!.isActive) return false;
    _activeEmergency = _activeEmergency!.copyWith(
      latitude: latitude,
      longitude: longitude,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return QuickRideFirebaseService().updateEmergencyLocation(
      _activeEmergency!.emergencyId,
      latitude,
      longitude,
    );
  }

  /// Clear active emergency state
  void clearActiveEmergency() {
    _emergencySub?.cancel();
    _emergencySub = null;
    _activeEmergency = null;
    notifyListeners();
  }

  // ==========================================================================
  // STEP 40: EMERGENCY CONTACTS HELPERS
  // ==========================================================================

  Stream<List<FirestoreEmergencyContactModel>> streamEmergencyContacts(String userId) {
    return QuickRideFirebaseService().streamEmergencyContacts(userId);
  }

  Future<List<FirestoreEmergencyContactModel>> fetchEmergencyContacts(String userId) {
    return QuickRideFirebaseService().fetchEmergencyContacts(userId);
  }

  Future<bool> addEmergencyContact(FirestoreEmergencyContactModel contact) {
    return QuickRideFirebaseService().addEmergencyContact(contact);
  }

  Future<bool> updateEmergencyContact(FirestoreEmergencyContactModel contact) {
    return QuickRideFirebaseService().updateEmergencyContact(contact);
  }

  Future<bool> deleteEmergencyContact(String userId, String contactId) {
    return QuickRideFirebaseService().deleteEmergencyContact(userId, contactId);
  }

  /// Resets safety service to default state (used in unit/widget testing).
  void resetToDefault() {
    _preferences = const SafetyPreferences();
    _activeRide = null;
    _sentVerificationRideIds.clear();
    _resetChecklistState();
    _emergencySub?.cancel();
    _emergencySub = null;
    _activeEmergency = null;
    notifyListeners();
  }
}
