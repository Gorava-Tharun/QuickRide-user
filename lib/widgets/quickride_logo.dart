import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../core/constants/app_strings.dart';

/// The official QuickRide USER logo widget.
///
/// Displays the official brand emblem featuring the QuickRide rider,
/// mobility arc, and user designation badge.
class QuickRideLogo extends StatelessWidget {
  const QuickRideLogo({
    super.key,
    this.size = AppDimensions.splashLogoSize,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.logoSemanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient radial glow behind the emblem
            if (showGlow)
              Container(
                width: size * 1.35,
                height: size * 1.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.secondary.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),

            // Base emblem container with official logo
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(size * 0.08),
                  child: Image.asset(
                    'assets/images/quickride_user_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
