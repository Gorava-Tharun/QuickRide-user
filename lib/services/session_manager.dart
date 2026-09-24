import '../models/user_profile_model.dart';
import '../models/firestore_models.dart';
import 'firebase_service.dart';
import 'push_notification_service.dart';
import 'connectivity_service.dart';

/// Modular local session manager for QuickRide.
///
/// Keeps user session, profile, and active ride state in memory.
/// Seamlessly synchronizes with Cloud Firestore when connected,
/// with automatic local fallback and offline recovery protection.
class SessionManager {
  // ── Singleton ──────────────────────────────────────────────────────────────
  SessionManager._internal() {
    _currentUser = _defaultProfile;
    _setupReconnectionSync();
  }
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;

  static final UserProfile _defaultProfile = UserProfile(
    userId: "user_quickride_01",
    fullName: "Alex Johnson",
    mobileNumber: "9876543210",
    email: "alex.johnson@quickride.com",
    createdAt: DateTime(2026, 1, 15),
  );

  bool _isLoggedIn = true;
  late UserProfile _currentUser;
  String? _activeRideId;
  SharedRideModel? _cachedActiveRide;

  bool get isLoggedIn => _isLoggedIn;
  UserProfile get currentUser => _currentUser;
  String? get activeRideId => _activeRideId;
  SharedRideModel? get cachedActiveRide => _cachedActiveRide;
  bool get hasActiveRide => _activeRideId != null && _activeRideId!.isNotEmpty;

  /// Sets the currently active ride (protects against duplicate ride creation)
  void setActiveRide(String? rideId, {SharedRideModel? ride}) {
    _activeRideId = rideId;
    _cachedActiveRide = ride;
  }

  /// Clears active ride when completed or cancelled
  void clearActiveRide() {
    _activeRideId = null;
    _cachedActiveRide = null;
  }

  /// Updates the current user profile and syncs with Firestore.
  void updateProfile(UserProfile updated) {
    _currentUser = updated;
    _syncToFirestore();
  }

  /// Sets logged-in state and optionally updates credentials from login inputs.
  void login({String? identifier, String? fullName, String? phone, String? email}) {
    _isLoggedIn = true;
    if (identifier != null || fullName != null || phone != null || email != null) {
      final isEmail = identifier?.contains("@") ?? false;
      _currentUser = _currentUser.copyWith(
        fullName: fullName ?? _currentUser.fullName,
        email: email ?? (isEmail ? identifier : _currentUser.email),
        mobileNumber: phone ?? (!isEmail && identifier != null ? identifier : _currentUser.mobileNumber),
      );
    }
    _syncToFirestore();
    PushNotificationService().registerUser(_currentUser.userId);
  }

  void _syncToFirestore() {
    QuickRideFirebaseService().syncUserProfile(
      FirestoreUserModel(
        userId: _currentUser.userId,
        name: _currentUser.fullName,
        phone: _currentUser.mobileNumber,
        email: _currentUser.email,
        profileImage: _currentUser.profileImage,
        status: 'ACTIVE',
        fcmToken: PushNotificationService().fcmToken,
        createdAt: _currentUser.createdAt,
      ),
    );
  }

  void _setupReconnectionSync() {
    ConnectivityService().addReconnectionListener(() async {
      if (_isLoggedIn) {
        _syncToFirestore();
        if (_activeRideId != null) {
          final refreshed = await QuickRideFirebaseService().fetchActiveRideForUser(_currentUser.userId);
          if (refreshed != null) {
            _cachedActiveRide = refreshed;
          }
        }
      }
    });
  }

  /// Logs out the user. Does NOT delete completed ride history or user profile.
  void logout() {
    _isLoggedIn = false;
    _activeRideId = null;
    _cachedActiveRide = null;
    PushNotificationService().clearUser();
  }

  /// Resets session and user profile to defaults (used in test tearDowns).
  void resetToDefault() {
    _isLoggedIn = true;
    _currentUser = _defaultProfile;
    _activeRideId = null;
    _cachedActiveRide = null;
  }
}
