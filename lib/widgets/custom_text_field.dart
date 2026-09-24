import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';

/// A modern, reusable text field with custom borders, icons, and error handling.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryDark,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          autofillHints: autofillHints,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceDark,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textMutedDark,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.borderDark,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.borderDark,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
