import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/quickride_logo.dart';
import '../../widgets/ride_background_visual.dart';

/// STEP 3: Professional Sign Up / Create Account Screen for QuickRide User App.
///
/// Features:
/// - QuickRide logo & header ("Create your QuickRide account")
/// - 5 input fields: Full Name, Mobile Number, Email, Password, Confirm Password
/// - Show/Hide password toggles on both password fields
/// - Comprehensive client-side validations
/// - "Create Account" primary action with loading feedback
/// - Floating "Account created successfully!" message
/// - Auto-navigation to Login Screen upon success
/// - "Already have an account? Login" bottom target
/// - Responsive & keyboard-safe layout
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Validation regular expressions
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _mobileRegex = RegExp(
    r'^[0-9]{10}$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates Full Name: required, minimum 2 characters.
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorNameEmpty;
    }
    if (value.trim().length < 2) {
      return AppStrings.errorNameTooShort;
    }
    return null;
  }

  /// Validates Mobile Number: required, valid 10-digit number.
  String? _validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorMobileEmpty;
    }
    final cleanDigits = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (!_mobileRegex.hasMatch(cleanDigits)) {
      return AppStrings.errorInvalidMobile;
    }
    return null;
  }

  /// Validates Email: required, valid email format.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorEmailEmpty;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return AppStrings.errorInvalidEmail;
    }
    return null;
  }

  /// Validates Password: required, minimum 6 characters.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorPasswordEmpty;
    }
    if (value.length < 6) {
      return AppStrings.errorPasswordTooShort;
    }
    return null;
  }

  /// Validates Confirm Password: required, must match Password.
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.errorConfirmPasswordEmpty;
    }
    if (value != _passwordController.text) {
      return AppStrings.errorPasswordsDoNotMatch;
    }
    return null;
  }

  /// Handles account creation action.
  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    // Simulate authentic network latency
    await Future<void>.delayed(const Duration(milliseconds: 900));

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
                AppStrings.accountCreatedSuccessMessage,
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate to Login Screen
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  /// Navigates back to the Login Screen.
  void _navigateToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
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
                          const SizedBox(height: AppDimensions.space12),

                          // Header Logo & Branding
                          Center(
                            child: Hero(
                              tag: 'quickride_brand_logo',
                              child: const QuickRideLogo(size: 72),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space20),

                          // Title & Subtitle
                          const Text(
                            AppStrings.signUpTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space8),
                          const Text(
                            AppStrings.signUpSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space24),

                          // 1. Full Name Field
                          CustomTextField(
                            controller: _nameController,
                            labelText: AppStrings.fullNameLabel,
                            hintText: AppStrings.fullNameHint,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            validator: _validateName,
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: AppDimensions.space16),

                          // 2. Mobile Number Field
                          CustomTextField(
                            controller: _mobileController,
                            labelText: AppStrings.mobileLabel,
                            hintText: AppStrings.mobileHint,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.phone_android_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            validator: _validateMobile,
                            autofillHints: const [AutofillHints.telephoneNumber],
                          ),
                          const SizedBox(height: AppDimensions.space16),

                          // 3. Email Address Field
                          CustomTextField(
                            controller: _emailController,
                            labelText: AppStrings.emailLabel,
                            hintText: AppStrings.emailHint,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            validator: _validateEmail,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: AppDimensions.space16),

                          // 4. Password Field
                          CustomTextField(
                            controller: _passwordController,
                            labelText: AppStrings.passwordLabel,
                            hintText: AppStrings.passwordHint,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
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
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                          const SizedBox(height: AppDimensions.space16),

                          // 5. Confirm Password Field
                          CustomTextField(
                            controller: _confirmPasswordController,
                            labelText: AppStrings.confirmPasswordLabel,
                            hintText: AppStrings.confirmPasswordHint,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleCreateAccount(),
                            prefixIcon: const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondaryDark,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              tooltip: _obscureConfirmPassword ? 'Show confirm password' : 'Hide confirm password',
                            ),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: AppDimensions.space24),

                          // Create Account Primary Button
                          PrimaryButton(
                            text: AppStrings.createAccountButton,
                            isLoading: _isLoading,
                            onPressed: _handleCreateAccount,
                            icon: Icons.person_add_alt_1_rounded,
                          ),

                          const Spacer(),
                          const SizedBox(height: AppDimensions.space24),

                          // Already have an account? Login target
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                AppStrings.alreadyHaveAccountPrompt,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToLogin,
                                child: const Text(
                                  AppStrings.loginLink,
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
