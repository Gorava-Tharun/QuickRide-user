import 'package:flutter/material.dart';

/// Centralized color palette for the QuickRide User App.
///
/// Combines a modern high-contrast obsidian background with energetic
/// golden-amber mobility accents and cyan speed highlights.
abstract final class AppColors {
  // Brand Accents
  static const Color primary = Color(0xFFFFC700); // Vibrant Rapido Goldenrod
  static const Color primaryDark = Color(0xFFFF9E00);
  static const Color primaryLight = Color(0xFFFFDF6D);
  static const Color secondary = Color(0xFF00E5FF); // Electric Cyan Accent
  static const Color secondaryDark = Color(0xFF00B0FF);

  // Dark Surface & Background (Signature brand mode)
  static const Color backgroundDark = Color(0xFF0A0E17);
  static const Color surfaceDark = Color(0xFF131B2A);
  static const Color surfaceElevatedDark = Color(0xFF1B2436);
  static const Color borderDark = Color(0xFF263248);

  // Light Surface & Background (For Material 3 Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Typography Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Ambient & Glow Effects
  static const Color glowGold = Color(0x55FFC700);
  static const Color glowCyan = Color(0x3300E5FF);
  static const Color splashOverlay = Color(0x1A000000);

  // Card & Semantic Colors
  static const Color cardDark = Color(0xFF162032);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color onlineGreen = Color(0xFF10B981);
}
