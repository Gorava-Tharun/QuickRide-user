import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/session_manager.dart';
import '../../services/firebase_service.dart';
import '../auth/login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await QuickRideFirebaseService().changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text(
                'Password Changed',
                style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            result['message'] as String? ?? 'Your password has been changed successfully.',
            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                SessionManager().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Log In Again', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String? ?? 'Failed to update password.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lock Icon Header
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                const Text(
                  'Password Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space12),

                const Text(
                  'Change your password securely using Firebase Authentication.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space24),

                // Form Fields
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  obscureText: _obscureCurrent,
                  onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Current password is required';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space16),

                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  obscureText: _obscureNew,
                  onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'New password is required';
                    if (val.length < 6) return 'Password must be at least 6 characters long';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space16),

                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter your new password',
                  obscureText: _obscureConfirm,
                  onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please confirm your new password';
                    if (val != _newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
                const SizedBox(height: AppDimensions.space12),

                // Return Button
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimaryLight,
                    side: const BorderSide(color: AppColors.borderDark),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Back to Settings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Security Notice Info Card
                Material(
                  color: AppColors.cardDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    side: const BorderSide(color: AppColors.borderDark),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.security_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Security Notice',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'For user safety during local testing, passwords are not collected, processed, or stored in plain text on this device.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondaryLight,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.borderDark, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Signed in as:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondaryLight,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
