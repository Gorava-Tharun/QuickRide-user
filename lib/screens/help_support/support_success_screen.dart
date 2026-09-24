import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/support_request_model.dart';
import '../../widgets/primary_button.dart';
import 'support_request_details_screen.dart';

/// Screen displayed immediately after a user submits a support request.
class SupportSuccessScreen extends StatelessWidget {
  const SupportSuccessScreen({
    super.key,
    required this.request,
  });

  final SupportRequest request;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space24,
              vertical: AppDimensions.space20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated checkmark icon container
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 54,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space24),

                // Title
                const Text(
                  'Request Submitted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryLight,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'Your support request has been submitted successfully.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space24),

                // Generated Request ID Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space20,
                    vertical: 14.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tag_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Request ID: ${request.requestId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Category & Issue pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    '${request.category.title} • ${request.issueType}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),

                const Spacer(),

                // Action Buttons
                PrimaryButton(
                  text: 'View Request',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => SupportRequestDetailsScreen(request: request),
                      ),
                    );
                  },
                  icon: Icons.visibility_rounded,
                ),
                const SizedBox(height: AppDimensions.space12),

                OutlinedButton(
                  onPressed: () {
                    // Navigate back to Help screen
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryLight,
                    minimumSize: const Size(double.infinity, 50.0),
                    side: const BorderSide(color: AppColors.borderDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Back to Help',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
