import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';

/// Centralized Error & Exception Handler for QuickRide User App.
///
/// Converts raw technical exceptions (Firebase, Network, Timeouts, OS)
/// into clear, user-friendly, actionable feedback without crashing.
class AppErrorHandler {
  AppErrorHandler._();

  /// Translates raw exceptions into friendly user strings.
  static String getFriendlyErrorMessage(Object? error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    if (error is FirebaseAuthException) {
      switch (error.code.toLowerCase()) {
        case 'user-not-found':
          return 'No account found with this email or phone number.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been suspended. Please contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }

    if (error is FirebaseException) {
      switch (error.code.toLowerCase()) {
        case 'permission-denied':
          return 'Access denied. You do not have permission for this action.';
        case 'unavailable':
          return 'Service temporarily unavailable. Operating in offline mode.';
        case 'not-found':
          return 'The requested ride or record could not be found.';
        case 'already-exists':
          return 'This record already exists.';
        case 'deadline-exceeded':
          return 'Connection timed out. Please try again.';
        case 'quota-exceeded':
          return 'Daily limit reached. Please try again later.';
        default:
          return error.message ?? 'A database error occurred. Please try again.';
      }
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network and retry.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please check your internet connection.';
    }

    if (error is FormatException) {
      return 'Invalid data format received. Please try again.';
    }

    final str = error.toString();
    if (str.contains('SocketException') || str.contains('Network is unreachable')) {
      return 'No internet connection. Please check your network and retry.';
    }
    if (str.contains('permission-denied')) {
      return 'Access denied. You do not have permission for this action.';
    }
    if (str.contains('timeout') || str.contains('TimeoutException')) {
      return 'Connection timed out. Please try again.';
    }

    // Default sanitized message
    return 'Operation could not be completed. Please try again.';
  }

  /// Displays a styled error SnackBar with optional retry action.
  static void showErrorSnackBar(
    BuildContext context,
    Object? error, {
    VoidCallback? onRetry,
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = customMessage ?? getFriendlyErrorMessage(error);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Displays a success SnackBar.
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Displays an offline notification SnackBar.
  static void showOfflineSnackBar(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You are currently offline. Displaying local data.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: onRetry != null
            ? SnackBarAction(
                label: 'CHECK',
                textColor: AppColors.primary,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
