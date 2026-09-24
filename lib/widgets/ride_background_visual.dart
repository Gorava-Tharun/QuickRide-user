import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// An attractive, responsive background visual depicting modern urban transit routes,
/// glowing coordinate nodes, and speed contours.
class RideBackgroundVisual extends StatelessWidget {
  const RideBackgroundVisual({
    super.key,
    required this.child,
    this.animationProgress = 1.0,
  });

  final Widget child;
  final double animationProgress;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      children: [
        // Base deep dark gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.2),
              radius: 1.3,
              colors: [
                Color(0xFF131D31),
                Color(0xFF0C1220),
                Color(0xFF070A12),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),

        // Ambient Top-Left Warm Glow (Gold)
        Positioned(
          top: -size.width * 0.35,
          left: -size.width * 0.25,
          child: Container(
            width: size.width * 0.9,
            height: size.width * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15 * animationProgress),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Ambient Bottom-Right Cool Glow (Cyan)
        Positioned(
          bottom: -size.width * 0.4,
          right: -size.width * 0.25,
          child: Container(
            width: size.width * 0.95,
            height: size.width * 0.95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.12 * animationProgress),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Custom Transit Grid & Route Trajectory Painter
        Positioned.fill(
          child: CustomPaint(
            painter: _TransitGridPainter(
              progress: animationProgress,
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

/// Paints delicate transit streamlines, road curves, and GPS nodes.
class _TransitGridPainter extends CustomPainter {
  const _TransitGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final w = size.width;
    final h = size.height;

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5
      ..color = AppColors.borderDark.withValues(alpha: 0.35 * progress);

    final roadActivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.35 * progress),
          AppColors.secondary.withValues(alpha: 0.4 * progress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Curved Highway 1: Sweeping S-Curve from bottom-left to top-right
    final path1 = Path()
      ..moveTo(-20, h * 0.85)
      ..cubicTo(w * 0.3, h * 0.75, w * 0.2, h * 0.35, w + 30, h * 0.2);
    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path1, roadActivePaint);

    // Curved Highway 2: Graceful counter-curve
    final path2 = Path()
      ..moveTo(-20, h * 0.3)
      ..cubicTo(w * 0.4, h * 0.45, w * 0.7, h * 0.9, w + 40, h * 0.7);
    canvas.drawPath(path2, roadPaint);

    // Diagonal Speed Streaks representing rapid transit
    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.06 * progress);

    for (int i = 1; i <= 5; i++) {
      final yOffset = h * 0.15 * i;
      canvas.drawLine(
        Offset(0, yOffset),
        Offset(w * 0.25, yOffset - 40),
        streakPaint,
      );
      canvas.drawLine(
        Offset(w * 0.75, yOffset),
        Offset(w, yOffset - 40),
        streakPaint,
      );
    }

    // Transit GPS Waypoint nodes
    final nodePoints = [
      Offset(w * 0.18, h * 0.22),
      Offset(w * 0.82, h * 0.28),
      Offset(w * 0.15, h * 0.72),
      Offset(w * 0.85, h * 0.78),
      Offset(w * 0.5, h * 0.88),
    ];

    final nodeGlow = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final nodeCore = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < nodePoints.length; i++) {
      final point = nodePoints[i];
      final isGold = i.isEven;
      final color = isGold ? AppColors.primary : AppColors.secondary;

      nodeGlow.color = color.withValues(alpha: 0.25 * progress);
      canvas.drawCircle(point, 8, nodeGlow);

      nodeCore.color = color.withValues(alpha: 0.6 * progress);
      canvas.drawCircle(point, 3, nodeCore);

      // Subtle pulse ring
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: 0.2 * progress);
      canvas.drawCircle(point, 12, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TransitGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
