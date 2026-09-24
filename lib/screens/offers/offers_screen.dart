import "dart:async";
import "package:flutter/material.dart";
import "../../core/constants/app_colors.dart";
import "../../core/constants/app_dimensions.dart";
import "../../core/constants/app_strings.dart";
import "../../models/offer_model.dart";
import "../../models/firestore_models.dart";
import "../../routes/app_routes.dart";
import "../../services/firebase_service.dart";
import "../../services/offer_service.dart";
import "../profile/profile_screen.dart";
import "../ride_history/ride_history_screen.dart";
import "offer_details_screen.dart";
import "widgets/offer_card.dart";

/// STEP 14: Offers & Promotions Screen.
///
/// Features:
/// 1. Top title "Offers & Rewards" and subtitle "Save more on your QuickRide trips".
/// 2. "Have a promo code?" input section with "Enter promo code" field and "Apply" button.
/// 3. Validates demo promo codes (e.g. QUICK50, RIDE50) with feedback.
/// 4. Applied offer banner displaying active discount, "Applied ✓", and "Remove" action.
/// 5. List of available promotional offer cards.
/// 6. Empty state if no offers exist.
/// 7. Bottom navigation bar with "Offers" (index 2) active.
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final OfferService _offerService = OfferService();
  final TextEditingController _couponController = TextEditingController();
  StreamSubscription<List<FirestoreOfferModel>>? _offersSubscription;

  late List<Offer> _offers;
  String? _couponError;
  String? _couponSuccess;
  bool _isValidatingCoupon = false;

  @override
  void initState() {
    super.initState();
    _offers = _offerService.getAvailableOffers();
    _initOffersStream();
  }

  void _initOffersStream() {
    final fb = QuickRideFirebaseService();
    if (fb.isFirebaseAvailable) {
      _offersSubscription = fb.streamActiveOffers().listen((firestoreOffers) {
        if (mounted) {
          _offerService.updateFirestoreOffers(firestoreOffers);
          setState(() {
            _offers = _offerService.getAvailableOffers();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _offersSubscription?.cancel();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _handleApplyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponError = "Please enter a promo code.";
        _couponSuccess = null;
      });
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
      _couponSuccess = null;
    });

    final result = await _offerService.validateCouponAsync(code);

    if (!mounted) return;

    setState(() {
      _isValidatingCoupon = false;
    });

    if (result['isValid'] == true && result['offer'] != null) {
      final matched = result['offer'] as Offer;
      _offerService.applyOffer(matched);
      setState(() {
        _couponSuccess = result['message'] as String? ?? "Coupon applied successfully!";
        _couponError = null;
        _couponController.clear();
      });
      _showToast(result['message'] as String? ?? "Coupon applied successfully!", isSuccess: true);
    } else {
      final msg = result['message'] as String? ?? "Invalid or expired coupon.";
      setState(() {
        _couponError = msg;
        _couponSuccess = null;
      });
      _showToast(msg, isSuccess: false);
    }
  }

  void _handleApplyOffer(Offer offer) {
    _offerService.applyOffer(offer);
    setState(() {
      _couponSuccess = null;
      _couponError = null;
    });
    _showToast("Coupon applied successfully!", isSuccess: true);
  }

  void _handleRemoveOffer() {
    final removedTitle = _offerService.appliedOffer?.title ?? "Offer";
    _offerService.removeOffer();
    setState(() {
      _couponSuccess = null;
      _couponError = null;
    });
    _showToast("$removedTitle removed.", isSuccess: false);
  }

  void _navigateToDetails(Offer offer) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => OfferDetailsScreen(offer: offer),
      ),
    )
        .then((_) {
      if (mounted) setState(() {});
    });
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

  void _showToast(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appliedOffer = _offerService.appliedOffer;

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
          "Offers & Rewards",
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _offers.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header / Subtitle
                          _buildHeader(),
                          const SizedBox(height: AppDimensions.space16),

                          // Active Applied Offer Banner (if any)
                          if (appliedOffer != null) ...[
                            _buildAppliedOfferBanner(appliedOffer),
                            const SizedBox(height: AppDimensions.space16),
                          ],

                          // "Have a promo code?" input card
                          _buildCouponInputSection(),
                          const SizedBox(height: AppDimensions.space20),

                          // Available Offers header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "AVAILABLE OFFERS",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                "${_offers.length} offers",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space12),

                          // Offer Cards List
                          ..._offers.map(
                            (offer) => OfferCard(
                              offer: offer,
                              isApplied: appliedOffer?.id == offer.id,
                              onApply: () => _handleApplyOffer(offer),
                              onRemove: _handleRemoveOffer,
                              onTapDetails: () => _navigateToDetails(offer),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Save more on your QuickRide trips",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAppliedOfferBanner(Offer offer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Applied \u2713",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "(${offer.discountLabel})",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  offer.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _handleRemoveOffer,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
            ),
            child: const Text(
              "Remove",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponInputSection() {
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
            children: const [
              Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                "Have a promo code?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),

          // Input field and Apply button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: _couponError != null
                          ? AppColors.error
                          : AppColors.borderDark,
                      width: 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                      letterSpacing: 1.0,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Enter promo code",
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryLight,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isValidatingCoupon ? null : _handleApplyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: _isValidatingCoupon
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Apply",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),

          // Feedback message
          if (_couponError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Text(
                  _couponError!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
          if (_couponSuccess != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  _couponSuccess!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 2.0,
                ),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: AppDimensions.space20),
            const Text(
              "No offers available",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Check back later for exciting QuickRide deals.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
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
        currentIndex: 2, // "Offers" active
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
            // Already on Offers
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfileScreen(),
              ),
            );
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
