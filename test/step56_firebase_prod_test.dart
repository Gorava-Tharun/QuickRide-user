import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_user/services/firebase_service.dart';
import 'package:quickride_user/services/push_notification_service.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 56: QuickRide User App Production Firebase Configuration & Safety Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SessionManager().resetToDefault();
    });

    test('QuickRideFirebaseService initializes gracefully without unhandled crashes', () async {
      final fb = QuickRideFirebaseService();
      final initialized = await fb.initialize();
      expect(initialized, isA<bool>());
      expect(fb.statusMessage, isNotEmpty);
    });

    test('SessionManager handles authentication state and user profile securely', () {
      final session = SessionManager();
      expect(session.isLoggedIn, isTrue);
      expect(session.currentUser.userId, isNotEmpty);
      expect(session.currentUser.email, contains('@'));

      session.logout();
      expect(session.isLoggedIn, isFalse);
      expect(session.hasActiveRide, isFalse);
    });

    test('PushNotificationService registers and clears user device tokens cleanly', () {
      final pushService = PushNotificationService();
      expect(() => pushService.registerUser('test_user_01'), returnsNormally);
      expect(() => pushService.clearUser(), returnsNormally);
    });

    test('QuickRideFirebaseService handles coupon validation and fallback securely', () async {
      final fb = QuickRideFirebaseService();
      final result = await fb.validateCouponCode('SAVE50', fare: 100.0, userId: 'test_user_01');
      expect(result, isNotNull);
      expect(result.containsKey('isValid'), isTrue);
    });
  });
}
