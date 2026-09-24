import 'package:flutter/material.dart';

/// Standard dimensions, spacing tokens, and sizing metrics for QuickRide.
abstract final class AppDimensions {
  // Spacing
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Logo & Visual Dimensions
  static const double splashLogoSize = 120.0;
  static const double splashLogoGlowRadius = 160.0;

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 999.0;

  // Responsive padding helper
  static EdgeInsets screenPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    return EdgeInsets.symmetric(
      horizontal: isTablet ? space48 : space24,
      vertical: space24,
    );
  }
}
