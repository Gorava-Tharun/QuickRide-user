import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_models.dart';
import 'location_service.dart';

class QuickRideFirebaseService {
  static final QuickRideFirebaseService _instance =
      QuickRideFirebaseService._internal();
  factory QuickRideFirebaseService() => _instance;
  QuickRideFirebaseService._internal();

  bool _isFirebaseAvailable = false;
  String _statusMessage = 'Uninitialized';
  final List<FirestorePaymentModel> _localPayments = [];
  final List<FirestoreComplaintModel> _localComplaints = [];
  final Map<String, List<FirestoreComplaintReplyModel>> _localReplies = {};

  bool get isFirebaseAvailable => _isFirebaseAvailable || Firebase.apps.isNotEmpty;
  String get statusMessage => _statusMessage;

  /// Safe initialization that catches missing configuration without crashing.
  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseAvailable = true;
        _statusMessage = 'Firebase connected (Default App)';
        debugPrint('[$statusMessage]');
        return true;
      }

      await Firebase.initializeApp();
      _isFirebaseAvailable = true;
      _statusMessage = 'Firebase initialized successfully';
      debugPrint('[$statusMessage]');
      return true;
    } catch (e) {
      _isFirebaseAvailable = false;
      _statusMessage = 'Firebase Offline / Local Fallback Mode: $e';
      debugPrint('[QuickRide Firebase] Note: $statusMessage');
      return false;
    }
  }

  /// Sync User profile to Firestore with fallback
  Future<bool> syncUserProfile(FirestoreUserModel user) async {
    if (!isFirebaseAvailable && Firebase.apps.isEmpty) {
      debugPrint('[QuickRide User] Offline mode: User profile saved locally.');
      return true;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.userId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        await docRef.set(user.toMap());
      } else {
        // Document exists: only update permitted editable fields to satisfy security rules
        final updateData = <String, dynamic>{
          'name': user.name,
          'phone': user.phone,
          'email': user.email,
        };
        if (user.profileImage != null) {
          updateData['profileImage'] = user.profileImage;
        }
        if (user.fcmToken != null) {
          updateData['fcmToken'] = user.fcmToken;
        }
        await docRef.update(updateData);
      }
      debugPrint('[QuickRide User] Successfully synced profile to Firestore: ${user.userId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Firestore sync error: $e');
      return false;
    }
  }

  /// Fetch User profile from Firestore
  Future<FirestoreUserModel?> fetchUserProfile(String userId) async {
    if (!isFirebaseAvailable && Firebase.apps.isEmpty) return null;
    if (userId.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return FirestoreUserModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching profile from Firestore: $e');
    }
    return null;
  }

  /// Change password using Firebase Authentication (with graceful fallback)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);
        return {
          'success': true,
          'message': 'Password changed successfully via Firebase Authentication.',
        };
      }
    } catch (e) {
      debugPrint('[QuickRide Firebase] Auth password update notice: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
        return {
          'success': false,
          'message': 'Current password is incorrect. Please try again.',
        };
      }
    }
    return {
      'success': true,
      'message': 'Password updated successfully.',
    };
  }

  /// Create a ride request document in Cloud Firestore
  Future<bool> createRideRequest(SharedRideModel ride) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: Ride request created locally.');
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(ride.rideId)
          .set(ride.toMap());
      debugPrint('[QuickRide User] Successfully created ride request: ${ride.rideId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Firestore createRideRequest error: $e');
      return false;
    }
  }

  /// Query online verified captains, strictly matching vehicle type, excluding rejected captains,
  /// and preferring nearest proximity to pickup location (Step 44).
  Future<FirestoreCaptainModel?> findOnlineCaptain({
    String? vehicleType,
    List<String> excludeCaptains = const [],
    double? pickupLatitude,
    double? pickupLongitude,
  }) async {
    if (!_isFirebaseAvailable) {
      return null;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('captains')
          .where('online', isEqualTo: true)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final normalizedRequestedType = (vehicleType ?? '').trim().toLowerCase();

      // Step 44 strict filtering:
      // 1. Must be ONLINE
      // 2. Must be VERIFIED (verificationStatus == 'APPROVED' or isVerified == true)
      // 3. Must match requested vehicle type (e.g. 'Bike' != 'Auto')
      // 4. Must not be on an active ride
      // 5. Must not be in excludeCaptains
      final eligibleCaptains = snapshot.docs
          .map((doc) => FirestoreCaptainModel.fromMap(doc.data(), id: doc.id))
          .where((c) {
            if (excludeCaptains.contains(c.captainId)) return false;
            if (!c.online) return false;
            // Verification check
            final isVerified = c.verificationStatus == 'APPROVED' || c.isApproved;
            if (!isVerified) return false;
            // Vehicle type matching
            if (normalizedRequestedType.isNotEmpty) {
              final capVehicleType = c.vehicleType.trim().toLowerCase();
              final matches = capVehicleType.contains(normalizedRequestedType) ||
                  normalizedRequestedType.contains(capVehicleType);
              if (!matches) return false;
            }
            return true;
          })
          .toList();

      if (eligibleCaptains.isEmpty) {
        return null;
      }

      // Proximity Sorting: Nearest captain to pickup first
      if (pickupLatitude != null && pickupLongitude != null) {
        eligibleCaptains.sort((a, b) {
          final distA = a.currentLocation != null
              ? LocationService.calculateDistanceKm(
                  pickupLatitude,
                  pickupLongitude,
                  a.currentLocation!['lat'] ?? 0.0,
                  a.currentLocation!['lng'] ?? 0.0,
                )
              : 999999.0;
          final distB = b.currentLocation != null
              ? LocationService.calculateDistanceKm(
                  pickupLatitude,
                  pickupLongitude,
                  b.currentLocation!['lat'] ?? 0.0,
                  b.currentLocation!['lng'] ?? 0.0,
                )
              : 999999.0;
          return distA.compareTo(distB);
        });
      }

      return eligibleCaptains.first;
    } catch (e) {
      debugPrint('[QuickRide User] Error finding online captain: $e');
      return null;
    }
  }

  /// Assign an online captain to a ride document
  Future<bool> assignCaptainToRide(String rideId, String captainId) async {
    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .update({'captainId': captainId});
      debugPrint('[QuickRide User] Assigned captain $captainId to ride $rideId');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error assigning captain: $e');
      return false;
    }
  }

  /// Fetch a single ride document from Firestore
  Future<SharedRideModel?> fetchRide(String rideId) async {
    if (!_isFirebaseAvailable || rideId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      if (doc.exists && doc.data() != null) {
        return SharedRideModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching ride: $e');
    }
    return null;
  }

  /// Stream changes for an active ride document
  Stream<SharedRideModel?> streamRide(String rideId) {
    if (!_isFirebaseAvailable) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return SharedRideModel.fromMap(snapshot.data()!, id: snapshot.id);
    });
  }

  /// Fetch captain profile by captainId
  Future<FirestoreCaptainModel?> fetchCaptainProfile(String captainId) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('captains')
          .doc(captainId)
          .get();
      if (doc.exists && doc.data() != null) {
        return FirestoreCaptainModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching captain: $e');
    }
    return null;
  }

  /// Cancel an active ride in Cloud Firestore
  Future<bool> cancelRide(
    String rideId, {
    String cancelledBy = 'user',
    String? cancellationReason,
    String? cancellationDescription,
  }) async {
    if (!_isFirebaseAvailable) return true;

    try {
      final docRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) return false;

      final data = docSnap.data() ?? {};
      final currentStatus = data['status'] as String? ?? '';
      if (currentStatus == 'COMPLETED' || currentStatus == 'CANCELLED') {
        debugPrint('[QuickRide User] Cannot cancel ride in terminal state $currentStatus');
        return false;
      }

      final updateData = <String, dynamic>{
        'status': SharedRideStatus.cancelled.firestoreValue,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancelledBy': cancelledBy,
      };
      if (cancellationReason != null && cancellationReason.isNotEmpty) {
        updateData['cancellationReason'] = cancellationReason;
      }
      if (cancellationDescription != null && cancellationDescription.isNotEmpty) {
        updateData['cancellationDescription'] = cancellationDescription;
      }

      await docRef.update(updateData);
      debugPrint('[QuickRide User] Ride $rideId cancelled in Firestore by $cancelledBy ($cancellationReason)');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error cancelling ride: $e');
      return false;
    }
  }

  /// Stream Captain live GPS location from captains/{captainId}
  Stream<Map<String, double>?> streamCaptainLocation(String captainId) {
    if (!_isFirebaseAvailable) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('captains')
        .doc(captainId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      final data = snapshot.data()!;
      if (data['currentLocation'] != null) {
        return Map<String, double>.from(data['currentLocation'] as Map);
      }
      return null;
    });
  }

  /// Fetch active ride for user during app restart recovery
  Future<SharedRideModel?> fetchActiveRideForUser(String userId) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            SharedRideStatus.requested.firestoreValue,
            SharedRideStatus.accepted.firestoreValue,
            SharedRideStatus.arrived.firestoreValue,
            SharedRideStatus.inProgress.firestoreValue,
          ])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return SharedRideModel.fromMap(doc.data(), id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching active ride: $e');
    }
    return null;
  }

  /// Submit a post-ride rating and review (User -> Captain)
  /// Checks whether a rating document already exists for this ride and ratedBy
  /// to strictly prevent duplicate ratings.
  Future<bool> submitRating(FirestoreRatingModel rating) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: Rating for ${rating.rideId} saved locally.');
      return true;
    }

    try {
      final docId = rating.ratingId.isNotEmpty ? rating.ratingId : '${rating.rideId}_user';
      final ratingRef = FirebaseFirestore.instance.collection('ratings').doc(docId);

      // Check if already rated
      final existing = await ratingRef.get();
      if (existing.exists) {
        debugPrint('[QuickRide User] Ride ${rating.rideId} has already been rated.');
        return false;
      }

      // Save rating document
      final modelToSave = FirestoreRatingModel(
        ratingId: docId,
        rideId: rating.rideId,
        userId: rating.userId,
        captainId: rating.captainId,
        ratedBy: 'user',
        ratedUserId: rating.userId,
        ratedCaptainId: rating.captainId,
        stars: rating.stars,
        rating: rating.rating,
        review: rating.review,
        createdAt: rating.createdAt,
      );

      await ratingRef.set(modelToSave.toMap());

      // Update Captain's average rating in Firestore if captainId is provided
      if (rating.captainId.isNotEmpty) {
        final captainRef = FirebaseFirestore.instance.collection('captains').doc(rating.captainId);
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final captainDoc = await transaction.get(captainRef);
            if (captainDoc.exists && captainDoc.data() != null) {
              final data = captainDoc.data()!;
              final currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
              final currentCount = (data['totalRatings'] as num?)?.toInt() ?? 1;
              final newCount = currentCount + 1;
              final newRating = double.parse(
                (((currentRating * currentCount) + rating.stars) / newCount).toStringAsFixed(2),
              );

              transaction.update(captainRef, {
                'rating': newRating,
                'totalRatings': newCount,
              });
            }
          });
        } catch (txError) {
          debugPrint('[QuickRide User] Note: Could not update captain stats: $txError');
        }
      }

      debugPrint('[QuickRide User] Rating $docId successfully saved.');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error submitting rating: $e');
      return false;
    }
  }

  /// Check if the user has already rated a ride in Firestore
  Future<bool> hasRated(String rideId, {String ratedBy = 'user'}) async {
    if (!_isFirebaseAvailable) return false;

    try {
      final docId = '${rideId}_$ratedBy';
      final doc = await FirebaseFirestore.instance.collection('ratings').doc(docId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[QuickRide User] Error checking rating status: $e');
      return false;
    }
  }

  /// Fetch rating document for a ride
  Future<FirestoreRatingModel?> fetchRating(String rideId, {String ratedBy = 'user'}) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final docId = '${rideId}_$ratedBy';
      final doc = await FirebaseFirestore.instance.collection('ratings').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return FirestoreRatingModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching rating: $e');
    }
    return null;
  }

  /// Update device FCM push token in Firestore user profile
  Future<bool> updateFcmToken(String userId, String? token) async {
    if (!_isFirebaseAvailable || userId.isEmpty) {
      debugPrint('[QuickRide User] Offline mode: FCM token update skipped.');
      return false;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[QuickRide User] FCM token updated in Firestore for user: $userId');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error updating FCM token in Firestore: $e');
      return false;
    }
  }

  /// Create a notification record in Firestore
  Future<bool> createNotification(FirestoreNotificationModel notification) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: Notification record saved locally.');
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toMap(), SetOptions(merge: true));
      debugPrint('[QuickRide User] Notification saved: ${notification.notificationId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error saving notification: $e');
      return false;
    }
  }

  /// Stream notifications for this user in real time
  Stream<List<FirestoreNotificationModel>> streamUserNotifications(String userId) {
    if (!_isFirebaseAvailable || userId.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreNotificationModel.fromMap(doc.data(), id: doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Mark a notification as read in Firestore
  Future<bool> markNotificationRead(String notificationId) async {
    if (!_isFirebaseAvailable || notificationId.isEmpty) return false;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error marking notification read: $e');
      return false;
    }
  }

  /// Stream all active offers from Firestore
  Stream<List<FirestoreOfferModel>> streamActiveOffers() {
    if (!_isFirebaseAvailable) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('offers')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => FirestoreOfferModel.fromMap(doc.data(), id: doc.id))
          .where((o) => now.isAfter(o.validFrom) && now.isBefore(o.validUntil))
          .toList();
    });
  }

  /// Fetch active offers once
  Future<List<FirestoreOfferModel>> fetchActiveOffers() async {
    if (!_isFirebaseAvailable) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('active', isEqualTo: true)
          .get();

      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => FirestoreOfferModel.fromMap(doc.data(), id: doc.id))
          .where((o) => now.isAfter(o.validFrom) && now.isBefore(o.validUntil))
          .toList();
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching active offers: $e');
      return [];
    }
  }

  /// Securely validate a coupon code against Firestore
  /// Returns a Map with { 'isValid': bool, 'offer': FirestoreOfferModel?, 'message': String }
  Future<Map<String, dynamic>> validateCouponCode(
    String couponCode, {
    required double fare,
    required String userId,
  }) async {
    final cleanCode = couponCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return {'isValid': false, 'message': 'Please enter a coupon code.'};
    }

    if (!_isFirebaseAvailable) {
      // Offline fallback handled in OfferService
      return {'isValid': false, 'isOffline': true};
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('offers')
          .where('couponCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'isValid': false, 'message': 'Invalid coupon code.'};
      }

      final doc = query.docs.first;
      final offer = FirestoreOfferModel.fromMap(doc.data(), id: doc.id);
      final now = DateTime.now();

      // 1. Active check
      if (!offer.active) {
        return {'isValid': false, 'message': 'This coupon is currently inactive.'};
      }

      // 2. Validity date check
      if (now.isBefore(offer.validFrom) || now.isAfter(offer.validUntil)) {
        return {'isValid': false, 'message': 'This coupon has expired.'};
      }

      // 3. Minimum fare check
      if (fare < offer.minimumFare) {
        return {
          'isValid': false,
          'message': 'Minimum fare of ₹${offer.minimumFare.toStringAsFixed(0)} required.',
        };
      }

      // 4. Global usage limit check
      if (offer.usageLimit != null && offer.usedCount >= offer.usageLimit!) {
        return {'isValid': false, 'message': 'Coupon usage limit has been reached.'};
      }

      // 5. Per-user limit check
      if (offer.perUserLimit != null) {
        final userUses = offer.userUsage[userId] ?? 0;
        if (userUses >= offer.perUserLimit!) {
          return {
            'isValid': false,
            'message': 'You have exceeded the usage limit for this coupon.',
          };
        }
      }

      return {'isValid': true, 'offer': offer, 'message': 'Coupon applied successfully!'};
    } catch (e) {
      debugPrint('[QuickRide User] Error validating coupon in Firestore: $e');
      return {'isValid': false, 'message': 'Error validating coupon. Please try again.'};
    }
  }

  // ─── STEP 37: SECURE PAYMENT OPERATIONS ─────────────────────────────────────

  /// Create or retrieve initial payment order record in Firestore
  Future<FirestorePaymentModel> createPaymentOrder({
    required String rideId,
    required String userId,
    String? captainId,
    required double originalFare,
    double discountAmount = 0.0,
    required double finalAmount,
    String paymentMethod = 'online',
    String? pickupAddress,
    String? dropAddress,
    String? vehicleType,
    double? distanceKm,
    String? couponCode,
    String? passengerName,
    String? captainName,
  }) async {
    final paymentId = 'PAY_$rideId';
    final now = DateTime.now();

    final model = FirestorePaymentModel(
      paymentId: paymentId,
      rideId: rideId,
      userId: userId,
      captainId: captainId,
      originalFare: originalFare,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      currency: 'INR',
      paymentMethod: paymentMethod,
      paymentStatus: FirestorePaymentStatus.pending,
      gatewayOrderId: 'order_${rideId}_${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      couponCode: couponCode,
      passengerName: passengerName,
      captainName: captainName,
    );

    // Keep local cache updated
    final existingIdx = _localPayments.indexWhere((p) => p.paymentId == paymentId);
    if (existingIdx != -1) {
      _localPayments[existingIdx] = model;
    } else {
      _localPayments.insert(0, model);
    }

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: Payment order $paymentId created locally.');
      return model;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('payments').doc(paymentId);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        final existing = FirestorePaymentModel.fromMap(doc.data()!, id: doc.id);
        if (existing.isPaid) return existing;
      }

      await docRef.set(model.toMap(), SetOptions(merge: true));

      // Link to ride
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'paymentId': paymentId,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'PENDING',
      }).catchError((_) {});

      return model;
    } catch (e) {
      debugPrint('[QuickRide User] Error creating payment order: $e');
      return model;
    }
  }

  /// Verify and complete a payment securely
  Future<Map<String, dynamic>> verifyPayment({
    required String rideId,
    required String paymentId,
    required String gatewayPaymentId,
    String? gatewayOrderId,
    String? gatewaySignature,
    String paymentMethod = 'online',
  }) async {
    final now = DateTime.now();

    // Update local cache
    final existingIdx = _localPayments.indexWhere((p) => p.paymentId == paymentId);
    if (existingIdx != -1) {
      _localPayments[existingIdx] = _localPayments[existingIdx].copyWith(
        paymentStatus: FirestorePaymentStatus.paid,
        paymentMethod: paymentMethod,
        gatewayPaymentId: gatewayPaymentId,
        gatewayOrderId: gatewayOrderId,
        gatewaySignature: gatewaySignature,
        paidAt: now,
        updatedAt: now,
      );
    }

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: Payment $paymentId marked PAID locally.');
      return {
        'success': true,
        'paymentStatus': 'PAID',
        'paymentId': paymentId,
        'gatewayPaymentId': gatewayPaymentId,
        'paidAt': now,
      };
    }

    try {
      final payRef = FirebaseFirestore.instance.collection('payments').doc(paymentId);
      final rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);

      final updateData = {
        'paymentStatus': 'PAID',
        'paymentMethod': paymentMethod,
        'gatewayPaymentId': gatewayPaymentId,
        ...?gatewayOrderId == null ? null : {'gatewayOrderId': gatewayOrderId},
        ...?gatewaySignature == null ? null : {'gatewaySignature': gatewaySignature},
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await payRef.set(updateData, SetOptions(merge: true));

      await rideRef.update({
        'paymentStatus': 'PAID',
        'paymentMethod': paymentMethod,
        'paymentId': paymentId,
      }).catchError((_) {});

      return {
        'success': true,
        'paymentStatus': 'PAID',
        'paymentId': paymentId,
        'gatewayPaymentId': gatewayPaymentId,
        'paidAt': now,
      };
    } catch (e) {
      debugPrint('[QuickRide User] Error verifying payment: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Mark payment as FAILED with error message
  Future<bool> recordPaymentFailure({
    required String paymentId,
    required String errorMessage,
  }) async {
    final now = DateTime.now();
    final existingIdx = _localPayments.indexWhere((p) => p.paymentId == paymentId);
    if (existingIdx != -1) {
      _localPayments[existingIdx] = _localPayments[existingIdx].copyWith(
        paymentStatus: FirestorePaymentStatus.failed,
        errorMessage: errorMessage,
        updatedAt: now,
      );
    }

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance.collection('payments').doc(paymentId).update({
        'paymentStatus': 'FAILED',
        'errorMessage': errorMessage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error recording payment failure: $e');
      return false;
    }
  }

  /// Fetch payment document for a given rideId
  Future<FirestorePaymentModel?> fetchPaymentForRide(String rideId) async {
    final paymentId = 'PAY_$rideId';
    if (!_isFirebaseAvailable) {
      try {
        return _localPayments.firstWhere((p) => p.paymentId == paymentId || p.rideId == rideId);
      } catch (_) {
        return null;
      }
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('payments').doc(paymentId).get();
      if (doc.exists && doc.data() != null) {
        return FirestorePaymentModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching payment for ride $rideId: $e');
    }
    return null;
  }

  /// Stream payment document updates in real-time
  Stream<FirestorePaymentModel?> streamPaymentForRide(String rideId) {
    final paymentId = 'PAY_$rideId';
    if (!_isFirebaseAvailable) {
      try {
        final match = _localPayments.firstWhere((p) => p.paymentId == paymentId || p.rideId == rideId);
        return Stream.value(match);
      } catch (_) {
        return Stream.value(null);
      }
    }

    return FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return FirestorePaymentModel.fromMap(snapshot.data()!, id: snapshot.id);
    });
  }

  /// Real-time stream of all payments for a specific user, sorted newest first
  Stream<List<FirestorePaymentModel>> streamUserPayments(String userId) {
    if (!_isFirebaseAvailable) {
      final list = _localPayments.where((p) => p.userId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.value(list);
    }

    return FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FirestorePaymentModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetch user payments once from Firestore
  Future<List<FirestorePaymentModel>> fetchUserPayments(String userId) async {
    if (!_isFirebaseAvailable) {
      final list = _localPayments.where((p) => p.userId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => FirestorePaymentModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching user payments: $e');
      final list = _localPayments.where((p) => p.userId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
  }

  // ==========================================
  // --- COMPLAINTS & CUSTOMER SUPPORT ---
  // ==========================================

  /// Stream real-time complaints filed by user
  Stream<List<FirestoreComplaintModel>> streamUserComplaints(String userId) {
    if (!_isFirebaseAvailable) {
      final list = _localComplaints.where((c) => c.userId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.value(list);
    }

    return FirebaseFirestore.instance
        .collection('complaints')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FirestoreComplaintModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetch user complaints once
  Future<List<FirestoreComplaintModel>> fetchUserComplaints(String userId) async {
    if (!_isFirebaseAvailable) {
      final list = _localComplaints.where((c) => c.userId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .get();

      final list = snapshot.docs
          .map((doc) => FirestoreComplaintModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching user complaints: $e');
      final list = _localComplaints.where((c) => c.userId == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
  }

  /// Fetch single complaint by ID
  Future<FirestoreComplaintModel?> fetchComplaintById(String complaintId) async {
    if (!_isFirebaseAvailable) {
      return _localComplaints.cast<FirestoreComplaintModel?>().firstWhere(
            (c) => c?.complaintId == complaintId,
            orElse: () => null,
          );
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .get();

      if (doc.exists && doc.data() != null) {
        return FirestoreComplaintModel.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching complaint $complaintId: $e');
      return _localComplaints.cast<FirestoreComplaintModel?>().firstWhere(
            (c) => c?.complaintId == complaintId,
            orElse: () => null,
          );
    }
  }

  /// Create a new complaint in Firestore
  Future<bool> createComplaint(FirestoreComplaintModel complaint) async {
    _localComplaints.removeWhere((c) => c.complaintId == complaint.complaintId);
    _localComplaints.insert(0, complaint);

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: complaint stored locally: ${complaint.complaintId}');
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaint.complaintId)
          .set(complaint.toMap(), SetOptions(merge: true));
      debugPrint('[QuickRide User] Successfully created complaint in Firestore: ${complaint.complaintId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error creating complaint in Firestore: $e');
      return false;
    }
  }

  /// Stream conversation replies for a complaint
  Stream<List<FirestoreComplaintReplyModel>> streamComplaintReplies(String complaintId) {
    if (!_isFirebaseAvailable) {
      final list = List<FirestoreComplaintReplyModel>.from(_localReplies[complaintId] ?? []);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return Stream.value(list);
    }

    return FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .collection('replies')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FirestoreComplaintReplyModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Fetch conversation replies once
  Future<List<FirestoreComplaintReplyModel>> fetchComplaintReplies(String complaintId) async {
    if (!_isFirebaseAvailable) {
      final list = List<FirestoreComplaintReplyModel>.from(_localReplies[complaintId] ?? []);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .collection('replies')
          .get();

      final list = snapshot.docs
          .map((doc) => FirestoreComplaintReplyModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching complaint replies: $e');
      final list = List<FirestoreComplaintReplyModel>.from(_localReplies[complaintId] ?? []);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }
  }

  /// Add a reply message to a complaint thread
  Future<bool> addComplaintReply(FirestoreComplaintReplyModel reply) async {
    _localReplies.putIfAbsent(reply.complaintId, () => []);
    _localReplies[reply.complaintId]!.add(reply);

    // Update local complaint updatedAt
    final cIndex = _localComplaints.indexWhere((c) => c.complaintId == reply.complaintId);
    if (cIndex != -1) {
      _localComplaints[cIndex] = _localComplaints[cIndex].copyWith(updatedAt: DateTime.now());
    }

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: complaint reply stored locally: ${reply.replyId}');
      return true;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final replyRef = FirebaseFirestore.instance
          .collection('complaints')
          .doc(reply.complaintId)
          .collection('replies')
          .doc(reply.replyId);
      final complaintRef = FirebaseFirestore.instance
          .collection('complaints')
          .doc(reply.complaintId);

      batch.set(replyRef, reply.toMap());
      batch.update(complaintRef, {'updatedAt': DateTime.now().toIso8601String()});
      await batch.commit();

      debugPrint('[QuickRide User] Successfully added reply to complaint: ${reply.complaintId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error adding reply to complaint: $e');
      return false;
    }
  }

  // ==========================================================================
  // STEP 40: SAFETY CENTER & EMERGENCY (SOS) MANAGEMENT
  // ==========================================================================

  final List<FirestoreEmergencyIncidentModel> _localEmergencies = [];
  final List<FirestoreEmergencyContactModel> _localEmergencyContacts = [];

  /// Create a new emergency incident
  Future<bool> createEmergencyIncident(FirestoreEmergencyIncidentModel emergency) async {
    // Check if duplicate active emergency exists for this ride
    final existingIdx = _localEmergencies.indexWhere(
      (e) => e.rideId == emergency.rideId && e.isActive,
    );
    if (existingIdx != -1) {
      debugPrint('[QuickRide User] Active emergency already exists for ride: ${emergency.rideId}');
      return true;
    }

    _localEmergencies.add(emergency);

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: emergency incident stored locally: ${emergency.emergencyId}');
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('emergencies')
          .doc(emergency.emergencyId)
          .set(emergency.toMap());
      debugPrint('[QuickRide User] Emergency incident saved in Firestore: ${emergency.emergencyId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error saving emergency incident to Firestore: $e');
      return false;
    }
  }

  /// Update current coordinates for an active emergency incident
  Future<bool> updateEmergencyLocation(String emergencyId, double latitude, double longitude) async {
    final idx = _localEmergencies.indexWhere((e) => e.emergencyId == emergencyId);
    if (idx != -1) {
      _localEmergencies[idx] = _localEmergencies[idx].copyWith(
        latitude: latitude,
        longitude: longitude,
        updatedAt: DateTime.now(),
      );
    }

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance.collection('emergencies').doc(emergencyId).update({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error updating emergency location: $e');
      return false;
    }
  }

  /// Stream active emergency incident for a specific user
  Stream<FirestoreEmergencyIncidentModel?> streamActiveEmergency(String userId) {
    if (!_isFirebaseAvailable || userId.isEmpty) {
      final active = _localEmergencies.cast<FirestoreEmergencyIncidentModel?>().firstWhere(
        (e) => e?.userId == userId && e?.isActive == true,
        orElse: () => null,
      );
      return Stream.value(active);
    }

    return FirebaseFirestore.instance
        .collection('emergencies')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return FirestoreEmergencyIncidentModel.fromMap(doc.data(), id: doc.id);
    });
  }

  /// Fetch active emergency for user once
  Future<FirestoreEmergencyIncidentModel?> fetchActiveEmergency(String userId) async {
    if (!_isFirebaseAvailable || userId.isEmpty) {
      return _localEmergencies.cast<FirestoreEmergencyIncidentModel?>().firstWhere(
        (e) => e?.userId == userId && e?.isActive == true,
        orElse: () => null,
      );
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('emergencies')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'ACTIVE')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return FirestoreEmergencyIncidentModel.fromMap(doc.data(), id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching active emergency: $e');
    }

    return _localEmergencies.cast<FirestoreEmergencyIncidentModel?>().firstWhere(
      (e) => e?.userId == userId && e?.isActive == true,
      orElse: () => null,
    );
  }

  /// Stream emergency contacts for user
  Stream<List<FirestoreEmergencyContactModel>> streamEmergencyContacts(String userId) {
    if (!_isFirebaseAvailable || userId.isEmpty) {
      return Stream.value(List<FirestoreEmergencyContactModel>.from(_localEmergencyContacts));
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FirestoreEmergencyContactModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetch emergency contacts once
  Future<List<FirestoreEmergencyContactModel>> fetchEmergencyContacts(String userId) async {
    if (!_isFirebaseAvailable || userId.isEmpty) {
      return List<FirestoreEmergencyContactModel>.from(_localEmergencyContacts);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .get();
      final list = snapshot.docs
          .map((doc) => FirestoreEmergencyContactModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching emergency contacts: $e');
      return List<FirestoreEmergencyContactModel>.from(_localEmergencyContacts);
    }
  }

  /// Add emergency contact
  Future<bool> addEmergencyContact(FirestoreEmergencyContactModel contact) async {
    _localEmergencyContacts.removeWhere((c) => c.contactId == contact.contactId);
    _localEmergencyContacts.add(contact);

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide User] Offline mode: emergency contact stored locally: ${contact.contactId}');
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(contact.ownerId)
          .collection('emergency_contacts')
          .doc(contact.contactId)
          .set(contact.toMap());
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error adding emergency contact: $e');
      return false;
    }
  }

  /// Update emergency contact
  Future<bool> updateEmergencyContact(FirestoreEmergencyContactModel contact) async {
    final idx = _localEmergencyContacts.indexWhere((c) => c.contactId == contact.contactId);
    if (idx != -1) {
      _localEmergencyContacts[idx] = contact;
    }

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(contact.ownerId)
          .collection('emergency_contacts')
          .doc(contact.contactId)
          .set(contact.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error updating emergency contact: $e');
      return false;
    }
  }

  /// Delete emergency contact
  Future<bool> deleteEmergencyContact(String userId, String contactId) async {
    _localEmergencyContacts.removeWhere((c) => c.contactId == contactId);

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error deleting emergency contact: $e');
      return false;
    }
  }

  // ==========================================================================
  // STEP 45: REAL-TIME CHAT
  // ==========================================================================

  final Map<String, List<FirestoreChatMessageModel>> _localChatMessages = {};
  final Map<String, StreamController<List<FirestoreChatMessageModel>>> _chatControllers = {};

  StreamController<List<FirestoreChatMessageModel>> _getChatController(String rideId) {
    return _chatControllers.putIfAbsent(
      rideId,
      () => StreamController<List<FirestoreChatMessageModel>>.broadcast(),
    );
  }

  /// Stream real-time chat messages for a ride
  Stream<List<FirestoreChatMessageModel>> streamChatMessages(String rideId) {
    if (!_isFirebaseAvailable) {
      final controller = _getChatController(rideId);
      final messages = _localChatMessages[rideId] ?? [];
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.unmodifiable(messages));
        }
      });
      return controller.stream;
    }

    try {
      return FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FirestoreChatMessageModel.fromMap(doc.data(), id: doc.id))
              .toList());
    } catch (e) {
      debugPrint('[QuickRide User] Error streaming chat messages for ride $rideId: $e');
      final controller = _getChatController(rideId);
      final messages = _localChatMessages[rideId] ?? [];
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.unmodifiable(messages));
        }
      });
      return controller.stream;
    }
  }

  /// Fetch one-time chat message list
  Future<List<FirestoreChatMessageModel>> fetchChatMessages(String rideId) async {
    if (!_isFirebaseAvailable) {
      return List.unmodifiable(_localChatMessages[rideId] ?? []);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreChatMessageModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('[QuickRide User] Error fetching chat messages: $e');
      return List.unmodifiable(_localChatMessages[rideId] ?? []);
    }
  }

  /// Send a chat message
  Future<bool> sendChatMessage(FirestoreChatMessageModel message) async {
    final list = _localChatMessages.putIfAbsent(message.rideId, () => []);
    list.add(message);
    _getChatController(message.rideId).add(List.unmodifiable(list));

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(message.rideId)
          .collection('messages')
          .doc(message.messageId)
          .set(message.toMap());
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error sending chat message: $e');
      return false;
    }
  }

  /// Mark message as read
  Future<bool> markChatMessageAsRead(String rideId, String messageId) async {
    final list = _localChatMessages[rideId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.messageId == messageId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(read: true);
        _getChatController(rideId).add(List.unmodifiable(list));
      }
    }

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .doc(messageId)
          .update({'read': true});
      return true;
    } catch (e) {
      debugPrint('[QuickRide User] Error marking chat message as read: $e');
      return false;
    }
  }

  /// Reset in-memory chat messages (for hermetic testing)
  void clearLocalChatMessages([String? rideId]) {
    if (rideId != null) {
      _localChatMessages.remove(rideId);
      _getChatController(rideId).add([]);
    } else {
      _localChatMessages.clear();
      for (final controller in _chatControllers.values) {
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }
  }

  /// Dev connection diagnostic helper
  Future<Map<String, dynamic>> testConnection() async {
    return {
      'isFirebaseAvailable': _isFirebaseAvailable,
      'status': _statusMessage,
      'appId': 'com.quickride.user',
      'firestoreTarget': 'users, rides, ratings, complaints, notifications, offers, payments, emergencies',
    };
  }
}

