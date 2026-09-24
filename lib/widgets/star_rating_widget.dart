import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Reusable animated 5-star rating widget.
///
/// [rating] — currently selected star count (0 = none selected).
/// [onRatingChanged] — callback fired when the user taps a star.
/// [size] — diameter of each star icon (default 42).
/// [readOnly] — when true, disables tap interactions.
class StarRatingWidget extends StatefulWidget {
  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 42.0,
    this.readOnly = false,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final bool readOnly;

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  /// Tracks which star the user is currently hovering over (for press animation).
  int _hovered = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final isFilled = starIndex <= (widget.rating);
        final isHovered = starIndex <= _hovered;

        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () => widget.onRatingChanged(starIndex),
          onTapDown: widget.readOnly
              ? null
              : (_) => setState(() => _hovered = starIndex),
          onTapCancel: widget.readOnly
              ? null
              : () => setState(() => _hovered = 0),
          onTapUp: widget.readOnly
              ? null
              : (_) => setState(() => _hovered = 0),
          child: AnimatedScale(
            scale: (isHovered && !widget.readOnly) ? 1.20 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  key: ValueKey('star_${starIndex}_$isFilled'),
                  color: isFilled ? AppColors.primary : AppColors.textMutedDark,
                  size: widget.size,
                  shadows: isFilled
                      ? [
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
