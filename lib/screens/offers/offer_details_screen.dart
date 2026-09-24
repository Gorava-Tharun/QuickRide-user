import "package:flutter/material.dart";
import "../../core/constants/app_colors.dart";
import "../../core/constants/app_dimensions.dart";
import "../../models/offer_model.dart";
import "../../services/offer_service.dart";
import "../../widgets/primary_button.dart";

/// Screen displaying complete details, terms, and eligibility of an [Offer].
class OfferDetailsScreen extends StatefulWidget {
  const OfferDetailsScreen({
    super.key,
    required this.offer,
  });

  final Offer offer;

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final OfferService _offerService = OfferService();

  bool get _isApplied => _offerService.appliedOffer?.id == widget.offer.id;

  void _handleToggleApply() {
    setState(() {
      if (_isApplied) {
        _offerService.removeOffer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.offer.title} removed."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _offerService.applyOffer(widget.offer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Coupon applied successfully!"),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;

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
          tooltip: "Back",
        ),
        title: const Text(
          "Offer Details",
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner Card
                    _buildHeaderBanner(offer),
                    const SizedBox(height: AppDimensions.space16),

                    // Quick Stats / Info Grid
                    _buildDetailsGrid(offer),
                    const SizedBox(height: AppDimensions.space16),

                    // Description Section
                    _buildSectionCard(
                      title: "About this offer",
                      icon: Icons.info_outline_rounded,
                      child: Text(
                        offer.description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Terms and Conditions Section
                    _buildSectionCard(
                      title: "Terms and conditions",
                      icon: Icons.gavel_rounded,
                      child: Text(
                        offer.termsAndConditions,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Action Button
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(Offer offer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: _isApplied ? AppColors.primary : AppColors.borderDark,
          width: _isApplied ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: offer.badgeColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: offer.badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: offer.badgeColor, width: 1.5),
                ),
                child: Icon(offer.iconData, color: offer.badgeColor, size: 28),
              ),
              const SizedBox(width: AppDimensions.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: offer.badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: offer.badgeColor, width: 1),
                      ),
                      child: Text(
                        offer.discountLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: offer.badgeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            offer.subtitle,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (offer.couponCode != null) ...[
            const SizedBox(height: AppDimensions.space12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "COUPON CODE: ${offer.couponCode}",
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(Offer offer) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            label: "Discount",
            value: offer.discountLabel,
            valueColor: offer.badgeColor,
          ),
          const Divider(color: AppColors.borderDark, height: 16),
          _buildInfoRow(
            label: "Minimum ride amount",
            value: offer.minimumFare > 0
                ? "₹${offer.minimumFare.toStringAsFixed(0)}"
                : "No minimum",
          ),
          const Divider(color: AppColors.borderDark, height: 16),
          _buildInfoRow(
            label: "Maximum discount",
            value: offer.maximumDiscount != null
                ? "₹${offer.maximumDiscount!.toStringAsFixed(0)}"
                : "No limit",
          ),
          const Divider(color: AppColors.borderDark, height: 16),
          _buildInfoRow(
            label: "Validity",
            value: offer.formattedExpiry,
          ),
          if (offer.couponCode != null) ...[
            const Divider(color: AppColors.borderDark, height: 16),
            _buildInfoRow(
              label: "Coupon code",
              value: offer.couponCode!,
              valueColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.0)),
      ),
      child: _isApplied
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Applied \u2713",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _handleToggleApply,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    minimumSize: const Size(100, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    "Remove",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : PrimaryButton(
              text: "Apply Offer",
              onPressed: _handleToggleApply,
              icon: Icons.check_circle_outline_rounded,
            ),
    );
  }
}
