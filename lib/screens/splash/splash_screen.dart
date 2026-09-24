import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_routes.dart';
import '../../widgets/quickride_logo.dart';
import '../../widgets/ride_background_visual.dart';

/// STEP 1: Premium Splash Screen for QuickRide User App.
///
/// Implements a 5-step staggered startup animation sequence:
/// 1. Logo fades in.
/// 2. Logo slightly scales up with smooth deceleration.
/// 3. QuickRide brand typography appears smoothly.
/// 4. Tagline ("Your Ride, Your Way") appears with letter spacing.
/// 5. Ambient mobility glow settles into a smooth ready state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staggered Animations
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  late final Animation<double> _taglineFadeAnimation;
  late final Animation<Offset> _taglineSlideAnimation;
  late final Animation<double> _ambientProgressAnimation;
  late final Animation<double> _footerFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 1. Logo Fade In (0% -> 38%)
    _logoFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
    );

    // 2. Logo Scale Up (15% -> 55%) with smooth subtle overshoot
    _logoScaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
      ),
    );

    // 3. QuickRide Text Appears Smoothly (42% -> 75%)
    _titleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.75, curve: Curves.easeOut),
    );
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Tagline Appears (62% -> 92%)
    _taglineFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.92, curve: Curves.easeOut),
    );
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // 5. Ambient Visuals and Finishing Transition
    _ambientProgressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
    );

    _footerFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
    );

    // Navigate to Login Screen upon completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });

    // Start the startup animation sequence
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return RideBackgroundVisual(
            animationProgress: _ambientProgressAnimation.value,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 640;
                  final logoSize = isCompact
                      ? AppDimensions.splashLogoSize * 0.8
                      : AppDimensions.splashLogoSize;

                  return Padding(
                    padding: AppDimensions.screenPadding(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),

                        // STEP 1 & 2: Logo Fade In & Scale Up
                        FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: QuickRideLogo(size: logoSize),
                          ),
                        ),

                        SizedBox(
                          height: isCompact
                              ? AppDimensions.space20
                              : AppDimensions.space32,
                        ),

                        // STEP 3: QuickRide Brand Name
                        SlideTransition(
                          position: _titleSlideAnimation,
                          child: FadeTransition(
                            opacity: _titleFadeAnimation,
                            child: _buildBrandName(context),
                          ),
                        ),

                        SizedBox(
                          height: isCompact
                              ? AppDimensions.space8
                              : AppDimensions.space12,
                        ),

                        // STEP 4: Tagline "Your Ride, Your Way"
                        SlideTransition(
                          position: _taglineSlideAnimation,
                          child: FadeTransition(
                            opacity: _taglineFadeAnimation,
                            child: _buildTagline(context),
                          ),
                        ),

                        const Spacer(flex: 3),

                        // STEP 5: Modern Transition & Brand Badge
                        FadeTransition(
                          opacity: _footerFadeAnimation,
                          child: _buildFooterBadge(context),
                        ),

                        const SizedBox(height: AppDimensions.space12),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the stylized QuickRide brand name with dual-tone gradient styling.
  Widget _buildBrandName(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // "Quick" in crisp modern white
        const Text(
          'Quick',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        // "Ride" in vibrant Rapido golden-amber with subtle neon shadow
        Text(
          'Ride',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.primary,
            shadows: [
              Shadow(
                color: AppColors.primary.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the elegant tagline "Your Ride, Your Way".
  Widget _buildTagline(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: AppColors.borderDark.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.electric_bolt_rounded,
            size: 14,
            color: AppColors.secondary,
          ),
          SizedBox(width: AppDimensions.space8),
          Text(
            AppStrings.tagline,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Subtle footer showing application identity and mobility readiness.
  Widget _buildFooterBadge(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        const Text(
          'SEAMLESS URBAN MOBILITY',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textMutedDark,
          ),
        ),
      ],
    );
  }
}
