import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/help_support/help_support_screen.dart';
import '../screens/help_support/my_support_requests_screen.dart';
import '../screens/help_support/report_issue_screen.dart';
import '../screens/help_support/support_request_details_screen.dart';
import '../screens/help_support/support_success_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/notifications/notification_screen.dart';
import '../screens/offers/offers_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/ride_history/ride_history_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../models/ride_model.dart';
import '../models/support_request_model.dart';
import '../screens/safety/safety_center_screen.dart';
import '../screens/safety/safety_preferences_screen.dart';
import '../screens/settings/about_quickride_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/privacy_settings_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../models/firestore_models.dart';
import '../screens/payment/digital_receipt_screen.dart';
import '../screens/payment/payment_history_screen.dart';
import '../screens/payment/payment_screen.dart';

/// Centralized route definitions and generator for QuickRide.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String home = '/home';
  static const String rideHistory = '/ride-history';
  static const String offers = '/offers';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String helpSupport = '/help-support';
  static const String reportIssue = '/report-issue';
  static const String mySupportRequests = '/my-support-requests';
  static const String supportRequestDetails = '/support-request-details';
  static const String supportSuccess = '/support-success';
  static const String notifications = '/notifications';
  static const String safetyCenter = '/safety-center';
  static const String safetyPreferences = '/safety-preferences';
  static const String settings = '/settings';
  static const String privacySettings = '/privacy-settings';
  static const String changePassword = '/change-password';
  static const String aboutQuickRide = '/about-quickride';
  static const String payment = '/payment';
  static const String paymentHistory = '/payment-history';
  static const String digitalReceipt = '/digital-receipt';

  /// Generates application routes.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case signUp:
        return MaterialPageRoute<void>(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case rideHistory:
        return MaterialPageRoute<void>(
          builder: (_) => const RideHistoryScreen(),
          settings: settings,
        );
      case offers:
        return MaterialPageRoute<void>(
          builder: (_) => const OffersScreen(),
          settings: settings,
        );
      case profile:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case editProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );
      case helpSupport:
        return MaterialPageRoute<void>(
          builder: (_) => const HelpSupportScreen(),
          settings: settings,
        );
      case reportIssue:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialCategory = args?['category'] as SupportCategory? ??
            SupportCategory.rideIssue;
        final preselectedRideId = args?['rideId'] as String?;
        return MaterialPageRoute<void>(
          builder: (_) => ReportIssueScreen(
            initialCategory: initialCategory,
            preselectedRideId: preselectedRideId,
          ),
          settings: settings,
        );
      case mySupportRequests:
        return MaterialPageRoute<void>(
          builder: (_) => const MySupportRequestsScreen(),
          settings: settings,
        );
      case supportRequestDetails:
        final request = settings.arguments as SupportRequest;
        return MaterialPageRoute<void>(
          builder: (_) => SupportRequestDetailsScreen(request: request),
          settings: settings,
        );
      case supportSuccess:
        final request = settings.arguments as SupportRequest;
        return MaterialPageRoute<void>(
          builder: (_) => SupportSuccessScreen(request: request),
          settings: settings,
        );
      case notifications:
        return MaterialPageRoute<void>(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );
      case safetyCenter:
        final activeRide = settings.arguments as RideRequest?;
        return MaterialPageRoute<void>(
          builder: (_) => SafetyCenterScreen(activeRide: activeRide),
          settings: settings,
        );
      case AppRoutes.safetyPreferences:
        return MaterialPageRoute<void>(
          builder: (_) => const SafetyPreferencesScreen(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case AppRoutes.privacySettings:
        return MaterialPageRoute<void>(
          builder: (_) => const PrivacySettingsScreen(),
          settings: settings,
        );
      case AppRoutes.changePassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ChangePasswordScreen(),
          settings: settings,
        );
      case AppRoutes.aboutQuickRide:
        return MaterialPageRoute<void>(
          builder: (_) => const AboutQuickRideScreen(),
          settings: settings,
        );
      case AppRoutes.payment:
        final ride = settings.arguments as RideRequest;
        return MaterialPageRoute<void>(
          builder: (_) => PaymentScreen(rideRequest: ride),
          settings: settings,
        );
      case AppRoutes.paymentHistory:
        return MaterialPageRoute<void>(
          builder: (_) => const PaymentHistoryScreen(),
          settings: settings,
        );
      case AppRoutes.digitalReceipt:
        final payment = settings.arguments as FirestorePaymentModel;
        return MaterialPageRoute<void>(
          builder: (_) => DigitalReceiptScreen(payment: payment),
          settings: settings,
        );
      default:


        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
