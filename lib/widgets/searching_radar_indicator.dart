import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Animated radar pulse indicator widget for captain searching state.
class SearchingRadarIndicator extends StatefulWidget {
  const SearchingRadarIndicator({
    super.key,
    this.size = 72.0,
    this.icon = Icons.search_rounded,
  });

  final double size;
  final IconData icon;

  @override
  State<SearchingRadarIndicator> createState() => _SearchingRadarIndicatorState();
}

class _SearchingRadarIndicatorState extends State<SearchingRadarIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulsing Ring 2
              Transform.scale(
                scale: 1.0 + (_controller.value * 0.8),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: (1.0 - _controller.value) * 0.25,
                    ),
                  ),
                ),
              ),

              // Inner Pulsing Ring 1
              Transform.scale(
                scale: 1.0 + ((_controller.value * 0.4) % 0.4),
                child: Container(
                  width: widget.size * 1.2,
                  height: widget.size * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: (1.0 - _controller.value) * 0.4,
                    ),
                  ),
                ),
              ),

              // Center Icon Container
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: AppColors.primary,
                  size: widget.size * 0.48,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
