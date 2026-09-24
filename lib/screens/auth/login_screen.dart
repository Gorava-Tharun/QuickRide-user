import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/quickride_logo.dart';
import '../../widgets/ride_background_visual.dart';

/// STEP 2: Professional Login Screen for QuickRide User App.
///
/// Features:
/// - QuickRide logo and welcome header
/// - Unified Mobile Number or Email input
/// - Password input with Show/Hide toggle
/// - Comprehensive client-side validations
/// - Forgot Password modal notice
/// - Sign Up navigation link
/// - Responsive & keyboard-safe layout
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Regular expressions for validation
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _phoneRegex = RegExp(
    r'^[0-9]{10}$',
  );

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates identifier as either a valid email or 10-digit mobile number.
  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorIdentifierEmpty;
    }
    final trimmed = value.trim();

    // Check if input contains letters or @ -> treat as email
    if (trimmed.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      if (!_emailRegex.hasMatch(trimmed)) {
        return AppStrings.errorInvalidIdentifier;
      }
    } else {
      // Treat as phone number (strip spaces or dashes if any)
      final digitsOnly = trimmed.replaceAll(RegExp(r'[\s-]'), '');
      if (!_phoneRegex.hasMatch(digitsOnly)) {
        return AppStrings.errorInvalidIdentifier;
      }
    }
    return null;
  }

  /// Validates password presence and minimum length.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorPasswordEmpty;
    }
    if (value.length < 6) {
      return AppStrings.errorPasswordTooShort;
    }
    return null;
  }

  /// Handles Login action with client-side validation and feedback.
  Future<void> _handleLogin() async {
    // Unfocus any active keyboard
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate brief network latency for authentic UI feedback
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show temporary success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevatedDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                AppStrings.loginSuccessMessage,
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to QuickRide Home Screen (Step 4)
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  /// Displays the Forgot Password notice.
  void _handleForgotPassword() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimensions.space20),
              const Icon(
                Icons.lock_reset_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppDimensions.space16),
              const Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                AppStrings.forgotPasswordNotice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),
              PrimaryButton(
                text: 'Got it',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigates to Sign Up screen.
  void _navigateToSignUp() {
    Navigator.of(context).pushNamed(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RideBackgroundVisual(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppDimensions.screenPadding(context),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppDimensions.space48,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppDimensions.space16),

                          // Header Logo & Branding
                          Center(
                            child: Hero(
                              tag: 'quickride_brand_logo',
                              child: const QuickRideLogo(size: 80),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space24),

                          // Title & Subtitle
                          const Text(
                            AppStrings.welcomeTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space8),
                          const Text(
                            AppStrings.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space32),

                          // Mobile Number or Email Field
                          CustomTextField(
                            controller: _identifierController,
                            labelText: AppStrings.identifierLabel,
                            hintText: AppStrings.identifierHint,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            validator: _validateIdentifier,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                              AutofillHints.telephoneNumber,
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space20),

                          // Password Field with Show/Hide Toggle
                          CustomTextField(
                            controller: _passwordController,
                            labelText: AppStrings.passwordLabel,
                            hintText: AppStrings.passwordHint,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondaryDark,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                            validator: _validatePassword,
                            autofillHints: const [AutofillHints.password],
                          ),
                          const SizedBox(height: AppDimensions.space12),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                AppStrings.forgotPassword,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space24),

                          // Login Button
                          PrimaryButton(
                            text: AppStrings.loginButton,
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                            icon: Icons.arrow_forward_rounded,
                          ),

                          const Spacer(),
                          const SizedBox(height: AppDimensions.space24),

                          // Sign Up Navigation Prompt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                AppStrings.noAccountPrompt,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToSignUp,
                                child: const Text(
                                  AppStrings.signUpLink,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
