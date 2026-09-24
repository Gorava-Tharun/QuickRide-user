import "package:flutter/material.dart";
import "../../core/constants/app_colors.dart";
import "../../core/constants/app_dimensions.dart";
import "../../core/constants/app_strings.dart";
import "../../models/user_profile_model.dart";
import "../../routes/app_routes.dart";
import "../../services/session_manager.dart";
import "../offers/offers_screen.dart";
import "../ride_history/ride_history_screen.dart";
import "edit_profile_screen.dart";
import "../help_support/help_support_screen.dart";
import "../help_support/my_support_requests_screen.dart";
import "../safety/safety_center_screen.dart";
import "../settings/settings_screen.dart";
import "../settings/change_password_screen.dart";
import "privacy_policy_screen.dart";
import "terms_conditions_screen.dart";
import "../payment/payment_history_screen.dart";
import "../../services/firebase_service.dart";



/// STEP 15: User Profile & Account Screen.
///
/// Features:
/// 1. Profile header with avatar placeholder, full name, mobile number, and email.
/// 2. "Edit Profile" action button navigating to [EditProfileScreen].
/// 3. Personal Information card (Full Name, Mobile Number, Email, Created Date).
/// 4. Account menu options:
///    - My Rides -> [RideHistoryScreen]
///    - Offers & Rewards -> [OffersScreen]
///    - Help & Support -> [HelpSupportScreen]
///    - Terms & Conditions -> [TermsConditionsScreen]
///    - Privacy Policy -> [PrivacyPolicyScreen]
///    - About QuickRide -> About dialog
///    - Logout -> Confirmation dialog, clears session, navigates to [LoginScreen].
/// 5. Integrated Bottom Navigation with "Profile" (index 3) active.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userId = _sessionManager.currentUser.userId;
    final user = await QuickRideFirebaseService().fetchUserProfile(userId);
    if (user != null && mounted) {
      _sessionManager.updateProfile(
        _sessionManager.currentUser.copyWith(
          fullName: user.name,
          mobileNumber: user.phone,
          email: user.email,
          profileImage: user.profileImage,
        ),
      );
      setState(() {});
    }
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppDimensions.space16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.person_rounded, size: 80, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  void _handleLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: const Text(
          "Logout from QuickRide?",
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          "Are you sure you want to logout? Your ride history and profile data will remain safe.",
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _sessionManager.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            child: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }


  void _handleAboutQuickRide() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Version ${AppStrings.appVersion}",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your Ride, Your Way — Fast, affordable, and safe mobility connecting you with trusted captains anytime, anywhere.",
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "Close",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _sessionManager.currentUser;

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
          onPressed: _navigateToHome,
          tooltip: "Back",
        ),
        title: const Text(
          "My Profile",
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
            vertical: AppDimensions.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header
              _buildProfileHeader(user),
              const SizedBox(height: AppDimensions.space16),

              // 2. Personal Information Card
              _buildPersonalInfoCard(user),
              const SizedBox(height: AppDimensions.space20),

              // 3. Account Options Section Header
              const Text(
                "ACCOUNT OPTIONS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),

              // 4. Menu Items Card
              _buildMenuCard(),
              const SizedBox(height: AppDimensions.space16),

              // 5. Logout Tile
              _buildLogoutButton(),
              const SizedBox(height: AppDimensions.space24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileHeader(UserProfile user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: (user.profileImage != null && user.profileImage!.isNotEmpty)
                ? () => _showImagePreviewDialog(user.profileImage!)
                : _navigateToEditProfile,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: (user.profileImage != null && user.profileImage!.isNotEmpty)
                    ? Image.network(
                        user.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Center(
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space16),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "+91 ${user.mobileNumber}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit Profile Action
          IconButton(
            onPressed: _navigateToEditProfile,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            tooltip: "Edit Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserProfile user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.badge_rounded, color: AppColors.primary, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _navigateToEditProfile,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          _buildInfoRow("Full Name", user.fullName),
          const SizedBox(height: 10),
          _buildInfoRow("Mobile Number", "+91 ${user.mobileNumber}"),
          const SizedBox(height: 10),
          _buildInfoRow("Email", user.email),
          const SizedBox(height: 10),
          _buildInfoRow("Account created date", user.formattedCreatedAt),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.history_rounded,
            title: "My Rides",
            subtitle: "View completed and cancelled trips",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RideHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.local_offer_rounded,
            title: "Offers & Rewards",
            subtitle: "Promotions, discounts & coupons",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OffersScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.receipt_long_rounded,
            title: "Payment History",
            subtitle: "Past transactions, invoices & digital receipts",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PaymentHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.headset_mic_rounded,
            title: "Help & Support",
            subtitle: "24/7 customer support and FAQs",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.receipt_long_rounded,
            title: "My Support Requests",
            subtitle: "View your submitted complaints & queries",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MySupportRequestsScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.shield_rounded,
            title: "Safety Center",
            subtitle: "Emergency tools, verification & ride safety",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SafetyCenterScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.settings_rounded,
            title: "Settings",
            subtitle: "Notifications, safety, theme & account",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.lock_outline_rounded,
            title: "Change Password",
            subtitle: "Update account security password",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.description_rounded,
            title: "Terms & Conditions",
            subtitle: "QuickRide terms of service",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TermsConditionsScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.privacy_tip_rounded,
            title: "Privacy Policy",
            subtitle: "How we protect and manage your data",
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(color: AppColors.borderDark, height: 1),
          _buildMenuItem(
            icon: Icons.info_outline_rounded,
            title: "About QuickRide",
            subtitle: "Version ${AppStrings.appVersion} • Info & licenses",
            onTap: _handleAboutQuickRide,
          ),


        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 8),
                Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.0)),
      ),
      child: BottomNavigationBar(
        currentIndex: 3, // "Profile" active
        onTap: (index) {
          if (index == 0) {
            _navigateToHome();
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RideHistoryScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OffersScreen(),
              ),
            );
          } else if (index == 3) {
            // Already on Profile
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.navHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: AppStrings.navMyRides,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_rounded),
            label: AppStrings.navOffers,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}
