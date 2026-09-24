/// Represents the calculated fare breakdown for a trip.
class FareDetails {
  const FareDetails({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.waitingCharge,
    required this.originalFare,
    required this.discount,
    required this.finalFare,
    this.discountPercentage = 50.0,
    this.offerDiscount = 0.0,
    this.offerLabel,
    this.ratePerKm = 0.0,
    this.selectedSlab = 'None',
    this.isAvailable = true,
    this.unavailableReason,
  });

  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double waitingCharge;
  final double originalFare;
  final double discount;
  final double finalFare;
  final double discountPercentage;

  /// Rupee discount applied from an active promo offer (default 0).
  final double offerDiscount;

  /// Display label for the applied offer (e.g. "RIDE50 Coupon").
  final String? offerLabel;

  /// Centralized slab pricing fields (Step 44)
  final double ratePerKm;
  final String selectedSlab;
  final bool isAvailable;
  final String? unavailableReason;

  /// Total discount including both first-ride discount and any applied offer.
  double get totalDiscount => discount + offerDiscount;

  /// Final fare after first-ride discount AND any applied offer discount.
  double get effectiveFinalFare => (finalFare - offerDiscount).clamp(0.0, double.infinity);

  String get formattedBaseFare => '₹${baseFare.toStringAsFixed(2)}';
  String get formattedDistanceFare => '₹${distanceFare.toStringAsFixed(2)}';
  String get formattedTimeFare => '₹${timeFare.toStringAsFixed(2)}';
  String get formattedWaitingCharge => '₹${waitingCharge.toStringAsFixed(2)}';
  String get formattedOriginalFare => '₹${originalFare.toStringAsFixed(2)}';
  String get formattedDiscount => '-₹${discount.toStringAsFixed(2)}';
  String get formattedFinalFare => '₹${finalFare.toStringAsFixed(2)}';
  String get formattedOfferDiscount => '-₹${offerDiscount.toStringAsFixed(2)}';
  String get formattedEffectiveFinalFare => '₹${effectiveFinalFare.toStringAsFixed(2)}';
  String get formattedRatePerKm => '₹${ratePerKm.toStringAsFixed(2)}/km';

  /// Returns a copy of this [FareDetails] with the given offer discount applied.
  FareDetails withOffer({required double offerDiscount, required String offerLabel}) {
    return FareDetails(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      waitingCharge: waitingCharge,
      originalFare: originalFare,
      discount: discount,
      finalFare: finalFare,
      discountPercentage: discountPercentage,
      offerDiscount: offerDiscount,
      offerLabel: offerLabel,
      ratePerKm: ratePerKm,
      selectedSlab: selectedSlab,
      isAvailable: isAvailable,
      unavailableReason: unavailableReason,
    );
  }

  /// Returns a copy without any offer discount.
  FareDetails withoutOffer() {
    return FareDetails(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      waitingCharge: waitingCharge,
      originalFare: originalFare,
      discount: discount,
      finalFare: finalFare,
      discountPercentage: discountPercentage,
      ratePerKm: ratePerKm,
      selectedSlab: selectedSlab,
      isAvailable: isAvailable,
      unavailableReason: unavailableReason,
    );
  }
}
