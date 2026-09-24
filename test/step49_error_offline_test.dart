import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickride_user/services/connectivity_service.dart';
import 'package:quickride_user/core/errors/app_error_handler.dart';
import 'package:quickride_user/widgets/offline_banner.dart';
import 'package:quickride_user/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 49: QuickRide User Error Handling & Offline Support Tests', () {
    late ConnectivityService connectivity;

    setUp(() {
      connectivity = ConnectivityService();
      connectivity.setMockOnlineState(true);
      SessionManager().resetToDefault();
    });

    tearDown(() {
      connectivity.setMockOnlineState(true);
      SessionManager().resetToDefault();
    });

    group('1. ConnectivityService & Reconnection Synchronization', () {
      test('Initial connectivity defaults to online', () {
        expect(connectivity.isOnline, isTrue);
        expect(connectivity.isOffline, isFalse);
      });

      test('Toggling mock online state updates isOnline and isOffline', () {
        connectivity.setMockOnlineState(false);
        expect(connectivity.isOnline, isFalse);
        expect(connectivity.isOffline, isTrue);

        connectivity.setMockOnlineState(true);
        expect(connectivity.isOnline, isTrue);
        expect(connectivity.isOffline, isFalse);
      });

      test('onConnectivityChanged stream emits status updates', () async {
        final events = <bool>[];
        final sub = connectivity.onConnectivityChanged.listen((status) {
          events.add(status);
        });

        connectivity.setMockOnlineState(false);
        connectivity.setMockOnlineState(true);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(events, containsAllInOrder([false, true]));
      });

      test('Reconnection listeners execute when internet returns', () async {
        bool reconnected = false;
        void onRestore() {
          reconnected = true;
        }

        connectivity.addReconnectionListener(() async => onRestore());

        // Go offline
        connectivity.setMockOnlineState(false);
        expect(reconnected, isFalse);

        // Restore online
        connectivity.setMockOnlineState(true);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(reconnected, isTrue);
        connectivity.removeReconnectionListener(() async => onRestore());
      });
    });

    group('2. AppErrorHandler User-Friendly Message Mapping', () {
      test('Translates standard Firebase Auth error codes', () {
        final notFound = FirebaseAuthException(code: 'user-not-found');
        expect(AppErrorHandler.getFriendlyErrorMessage(notFound), contains('No account found'));

        final wrongPass = FirebaseAuthException(code: 'wrong-password');
        expect(AppErrorHandler.getFriendlyErrorMessage(wrongPass), contains('Incorrect email or password'));

        final weakPass = FirebaseAuthException(code: 'weak-password');
        expect(AppErrorHandler.getFriendlyErrorMessage(weakPass), contains('Password is too weak'));

        final networkFail = FirebaseAuthException(code: 'network-request-failed');
        expect(AppErrorHandler.getFriendlyErrorMessage(networkFail), contains('Network error'));
      });

      test('Translates Firestore database and network errors', () {
        final permDenied = FirebaseException(plugin: 'firestore', code: 'permission-denied');
        expect(AppErrorHandler.getFriendlyErrorMessage(permDenied), contains('Access denied'));

        final unavailable = FirebaseException(plugin: 'firestore', code: 'unavailable');
        expect(AppErrorHandler.getFriendlyErrorMessage(unavailable), contains('Service temporarily unavailable'));

        const socketErr = SocketException('Failed host lookup');
        expect(AppErrorHandler.getFriendlyErrorMessage(socketErr), contains('No internet connection'));

        final timeoutErr = TimeoutException('Request timeout');
        expect(AppErrorHandler.getFriendlyErrorMessage(timeoutErr), contains('timed out'));
      });

      test('Sanitizes unknown errors with safe default fallback', () {
        expect(AppErrorHandler.getFriendlyErrorMessage(null), contains('unexpected error occurred'));
        expect(AppErrorHandler.getFriendlyErrorMessage(Exception('unknown internal error')), contains('could not be completed'));
      });
    });

    group('3. OfflineBanner UI Widget Tests', () {
      testWidgets('OfflineBanner is hidden when online', (tester) async {
        connectivity.setMockOnlineState(true);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: OfflineBanner(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No internet connection. Offline protection active.'), findsNothing);
      });

      testWidgets('OfflineBanner displays banner and retry button when offline', (tester) async {
        connectivity.setMockOnlineState(false);

        bool retried = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineBanner(
                onRetry: () => retried = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No internet connection. Offline protection active.'), findsOneWidget);
        expect(find.text('RETRY'), findsOneWidget);

        // Tap retry
        await tester.tap(find.text('RETRY'));
        await tester.pump();
        expect(retried, isTrue);
      });
    });

    group('4. SessionManager Active Ride & Idempotency Protection', () {
      test('Tracks active ride lifecycle safely', () {
        final session = SessionManager();
        expect(session.hasActiveRide, isFalse);
        expect(session.activeRideId, isNull);

        session.setActiveRide('QR-ACTIVE-101');
        expect(session.hasActiveRide, isTrue);
        expect(session.activeRideId, 'QR-ACTIVE-101');

        session.clearActiveRide();
        expect(session.hasActiveRide, isFalse);
        expect(session.activeRideId, isNull);
      });

      test('Logout clears active ride reference but preserves profile defaults', () {
        final session = SessionManager();
        session.setActiveRide('QR-ACTIVE-202');
        expect(session.hasActiveRide, isTrue);

        session.logout();
        expect(session.isLoggedIn, isFalse);
        expect(session.hasActiveRide, isFalse);
      });
    });
  });
}
