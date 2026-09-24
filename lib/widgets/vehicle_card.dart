import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';

/// An interactive selection card for ride types (Bike, Auto, Car).
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.space16,
            horizontal: AppDimensions.space8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderDark,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceElevatedDark,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isSelected ? Colors.black : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: AppDimensions.space4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondaryDark,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
