import "../models/offer_model.dart";
import "../models/firestore_models.dart";
import "firebase_service.dart";
import "offer_repository.dart";
import "session_manager.dart";

/// Singleton implementation of [OfferRepository] backed by Firestore with local mock fallback.
///
/// Manages the list of active offers, coupon validation (against Firestore & local rules),
/// and the currently applied offer.
class OfferService implements OfferRepository {
  // ── Singleton ──────────────────────────────────────────────────────────────
  OfferService._internal();
  static final OfferService _instance = OfferService._internal();
  factory OfferService() => _instance;

  // ── State ──────────────────────────────────────────────────────────────────
  Offer? _appliedOffer;
  List<FirestoreOfferModel> _firestoreOffers = [];

  @override
  Offer? get appliedOffer => _appliedOffer;

  /// Cache of loaded Firestore offers
  List<FirestoreOfferModel> get firestoreOffers => _firestoreOffers;

  void updateFirestoreOffers(List<FirestoreOfferModel> offers) {
    _firestoreOffers = offers;
  }

  // ── OfferRepository implementation ────────────────────────────────────────

  @override
  List<Offer> getAvailableOffers() {
    if (_firestoreOffers.isNotEmpty) {
      final now = DateTime.now();
      final validFirestore = _firestoreOffers
          .where((o) => o.active && now.isAfter(o.validFrom) && now.isBefore(o.validUntil))
          .map((o) => Offer.fromFirestore(o))
          .toList();

      if (validFirestore.isNotEmpty) {
        return validFirestore;
      }
    }
    return kMockOffers.where((o) => o.isValid).toList();
  }

  @override
  Offer? getOfferById(String id) {
    // Check Firestore offers first
    try {
      final fsMatch = _firestoreOffers.firstWhere((o) => o.offerId == id);
      return Offer.fromFirestore(fsMatch);
    } catch (_) {}

    try {
      return kMockOffers.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Offer? validateCoupon(String couponCode) {
    final normalised = couponCode.trim().toUpperCase();

    // 1. Check in cached Firestore offers
    try {
      final fsMatch = _firestoreOffers.firstWhere(
        (o) => o.couponCode.toUpperCase() == normalised && o.isValid,
      );
      return Offer.fromFirestore(fsMatch);
    } catch (_) {}

    // 2. Check in mock demo codes
    final offerId = kDemoCouponCodes[normalised];
    if (offerId != null) {
      final offer = getOfferById(offerId);
      if (offer != null && offer.isValid) return offer;
    }

    // 3. Check mock offers direct coupon code match
    try {
      final directMock = kMockOffers.firstWhere(
        (o) => o.couponCode?.toUpperCase() == normalised && o.isValid,
      );
      return directMock;
    } catch (_) {}

    return null;
  }

  /// Async validation that checks Firestore directly or uses local mock
  Future<Map<String, dynamic>> validateCouponAsync(
    String couponCode, {
    double fare = 100.0,
  }) async {
    final cleanCode = couponCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return {'isValid': false, 'message': 'Please enter a promo code.'};
    }

    final userId = SessionManager().currentUser.userId;
    final fb = QuickRideFirebaseService();

    if (fb.isFirebaseAvailable) {
      final result = await fb.validateCouponCode(cleanCode, fare: fare, userId: userId);
      if (result['isOffline'] != true) {
        if (result['isValid'] == true && result['offer'] != null) {
          final offer = Offer.fromFirestore(result['offer'] as FirestoreOfferModel);
          return {
            'isValid': true,
            'offer': offer,
            'message': result['message'] ?? 'Coupon applied successfully!',
          };
        }
        return {
          'isValid': false,
          'message': result['message'] ?? 'Invalid or expired coupon.',
        };
      }
    }

    // Offline / Mock fallback validation
    final matched = validateCoupon(cleanCode);
    if (matched != null) {
      if (fare < matched.minimumFare) {
        return {
          'isValid': false,
          'message': 'Minimum fare of ₹${matched.minimumFare.toStringAsFixed(0)} required.',
        };
      }
      return {
        'isValid': true,
        'offer': matched,
        'message': 'Coupon applied successfully!',
      };
    }

    return {
      'isValid': false,
      'message': 'Invalid or expired coupon.',
    };
  }

  @override
  void applyOffer(Offer offer) {
    _appliedOffer = offer;
  }

  @override
  void removeOffer() {
    _appliedOffer = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Clears the applied offer (used in tests and logout flows).
  void clearAppliedOffer() => _appliedOffer = null;

  /// Whether any offer is currently applied.
  bool get hasAppliedOffer => _appliedOffer != null;
}
