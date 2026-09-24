import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Provides Material 3 ThemeData configurations for QuickRide.
abstract final class AppTheme {
  /// Dark Theme (Signature Brand Experience)
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.black,
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildDarkTextTheme(),
    );
  }

  /// Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primaryDark,
      onPrimary: Colors.black,
      secondary: AppColors.secondaryDark,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _buildLightTextTheme(),
    );
  }

  static TextTheme _buildDarkTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryDark,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondaryDark,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textSecondaryDark,
      ),
    );
  }

  static TextTheme _buildLightTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryLight,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimaryLight,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondaryLight,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textSecondaryLight,
      ),
    );
  }
}
