import "../models/offer_model.dart";

/// Abstract repository interface for offer operations.
///
/// Decouples the UI from the data source — swap local mock for a real API later.
abstract interface class OfferRepository {
  /// Returns all currently available and active offers.
  List<Offer> getAvailableOffers();

  /// Returns an offer by its [id], or null if not found.
  Offer? getOfferById(String id);

  /// Validates a [couponCode] and returns the matching [Offer] if valid,
  /// or null if the code is unknown or the offer is inactive/expired.
  Offer? validateCoupon(String couponCode);

  /// Applies [offer] as the currently active offer.
  void applyOffer(Offer offer);

  /// Removes the currently applied offer.
  void removeOffer();

  /// Returns the currently applied offer, or null if none is selected.
  Offer? get appliedOffer;
}
