import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/ride_history_model.dart';
import '../../models/ride_review_model.dart';
import '../../services/ride_history_service.dart';
import '../../services/ride_review_service.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/star_rating_widget.dart';
import '../help_support/report_issue_screen.dart';
import '../../models/support_request_model.dart';
import '../rating_review/rating_review_screen.dart';
import '../../models/firestore_models.dart';
import '../payment/digital_receipt_screen.dart';

/// STEP 13: Detailed view of a past completed or cancelled ride.
class RideDetailsScreen extends StatefulWidget {
  const RideDetailsScreen({
    super.key,
    required this.ride,
  });

  final RideHistoryItem ride;

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  late RideHistoryItem _currentRide;
  RideReview? _review;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _currentRide = widget.ride;
    _fetchReviewDetails();
  }

  Future<void> _fetchReviewDetails() async {
    final review = await RideReviewService().getReviewForRide(_currentRide.rideId);
    final historyItem = RideHistoryService().findById(_currentRide.rideId);

    if (mounted) {
      setState(() {
        _review = review;
        if (historyItem != null) {
          _currentRide = historyItem;
        }
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitCameraToBounds();
  }

  void _fitCameraToBounds() {
    if (_mapController == null) return;
    final p = _currentRide.pickup;
    final d = _currentRide.destination;

    final minLat = math.min(p.latitude, d.latitude);
    final maxLat = math.max(p.latitude, d.latitude);
    final minLng = math.min(p.longitude, d.longitude);
    final maxLng = math.max(p.longitude, d.longitude);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0,
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('pickup_marker'),
        position: LatLng(_currentRide.pickup.latitude, _currentRide.pickup.longitude),
        infoWindow: InfoWindow(title: 'Pickup', snippet: _currentRide.pickup.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: LatLng(_currentRide.destination.latitude, _currentRide.destination.longitude),
        infoWindow: InfoWindow(title: 'Destination', snippet: _currentRide.destination.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('route_preview'),
        points: [
          LatLng(_currentRide.pickup.latitude, _currentRide.pickup.longitude),
          LatLng(_currentRide.destination.latitude, _currentRide.destination.longitude),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  Future<void> _handleRateRide() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RatingReviewScreen(
          rideRequest: _currentRide.toRideRequest(),
        ),
      ),
    );
    // Reload review details upon return
    await _fetchReviewDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimaryLight, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ride Details',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only Map Preview
              _buildMapPreview(),

              Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Banner
                    _buildStatusBanner(),
                    const SizedBox(height: AppDimensions.space16),

                    // Trip Details Card
                    _buildTripCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Vehicle & Captain Cards Row/Column
                    _buildVehicleCard(),
                    const SizedBox(height: AppDimensions.space16),

                    _buildCaptainCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Fare Breakdown Card
                    _buildFareCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Payment & Date Card
                    _buildPaymentAndDateCard(),
                    const SizedBox(height: AppDimensions.space16),

                    // Rating & Review Card
                    _buildRatingSection(),
                    const SizedBox(height: AppDimensions.space16),

                    // Help & Support Issue Reporting
                    _buildHelpSection(),
                    const SizedBox(height: AppDimensions.space24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_currentRide.pickup.latitude, _currentRide.pickup.longitude),
          zoom: 13.0,
        ),
        markers: _buildMarkers(),
        polylines: _buildPolylines(),
        onMapCreated: _onMapCreated,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
      ),
    );
  }

  Widget _buildStatusBanner() {
    final isCancelled = _currentRide.isCancelled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCancelled
            ? AppColors.error.withValues(alpha: 0.15)
            : const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isCancelled ? AppColors.error : const Color(0xFF10B981),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
            color: isCancelled ? AppColors.error : const Color(0xFF10B981),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentRide.formattedStatus,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isCancelled ? AppColors.error : const Color(0xFF10B981),
                  ),
                ),
                Text(
                  isCancelled
                      ? 'This ride was cancelled by the user.'
                      : 'Completed on ${_currentRide.formattedDateTime}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard() {
    return _buildSectionCard(
      title: 'TRIP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    Text(
                      _currentRide.pickup.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      _currentRide.pickup.address,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    Text(
                      _currentRide.destination.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      _currentRide.destination.address,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance: ${_currentRide.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              Text(
                'Duration: ${_currentRide.estimatedMinutes} mins',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard() {
    return _buildSectionCard(
      title: 'VEHICLE',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentRide.vehicle.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  _currentRide.captain.vehicleModel,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentRide.captain.vehicleNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptainCard() {
    return _buildSectionCard(
      title: 'CAPTAIN',
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentRide.captain.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${_currentRide.captain.completedRides} rides completed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                _currentRide.captain.formattedRating,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareCard() {
    final fare = _currentRide.fareDetails;
    final isCancelled = _currentRide.isCancelled;

    return _buildSectionCard(
      title: 'FARE',
      child: Column(
        children: [
          if (isCancelled) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status', style: TextStyle(color: AppColors.textSecondaryLight)),
                Text('Ride Cancelled',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Charged Amount', style: TextStyle(color: AppColors.textSecondaryLight)),
                Text('₹0.00',
                    style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700)),
              ],
            ),
          ] else ...[
            _buildFareRow('Base Fare', fare.formattedBaseFare),
            const SizedBox(height: 6),
            _buildFareRow('Distance Fare', fare.formattedDistanceFare),
            const SizedBox(height: 6),
            _buildFareRow('Time Fare', fare.formattedTimeFare),
            if (fare.waitingCharge > 0) ...[
              const SizedBox(height: 6),
              _buildFareRow('Waiting Charge', fare.formattedWaitingCharge),
            ],
            if (fare.discount > 0) ...[
              const SizedBox(height: 6),
              _buildFareRow(
                'First Ride Discount',
                fare.formattedDiscount,
                valueColor: const Color(0xFF10B981),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.borderDark, height: 1),
            ),
            _buildFareRow(
              'Final Fare',
              fare.formattedFinalFare,
              isBold: true,
              valueColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFareRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentAndDateCard() {
    final isPaid = _currentRide.paymentStatus.toUpperCase() == 'PAID';
    final isCancelled = _currentRide.isCancelled;

    return _buildSectionCard(
      title: 'PAYMENT & DATE',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Method',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
              Text(
                _currentRide.paymentMethodTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Status',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isCancelled
                          ? AppColors.textSecondaryLight.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isPaid
                        ? const Color(0xFF10B981)
                        : (isCancelled ? AppColors.textSecondaryLight : Colors.orange),
                    width: 1,
                  ),
                ),
                child: Text(
                  isCancelled ? 'CANCELLED' : _currentRide.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPaid
                        ? const Color(0xFF10B981)
                        : (isCancelled ? AppColors.textSecondaryLight : Colors.orange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Date & Time',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
              Text(
                _currentRide.formattedDateTime,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          if (!isPaid && !isCancelled) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderDark, height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/payment',
                    arguments: _currentRide.toRideRequest(),
                  );
                },
                icon: const Icon(Icons.lock_outline_rounded, size: 16),
                label: Text(
                  'Pay Now • ₹${_currentRide.fareDetails.finalFare.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
          if (isPaid) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderDark, height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final payModel = FirestorePaymentModel(
                    paymentId: 'PAY_${_currentRide.rideId}',
                    rideId: _currentRide.rideId,
                    userId: _currentRide.userId,
                    captainId: _currentRide.captain.id,
                    originalFare: _currentRide.fareDetails.originalFare,
                    discountAmount: _currentRide.fareDetails.totalDiscount,
                    finalAmount: _currentRide.fareDetails.effectiveFinalFare,
                    paymentMethod: _currentRide.paymentMethod.name,
                    paymentStatus: FirestorePaymentStatus.paid,
                    pickupAddress: _currentRide.pickup.address,
                    dropAddress: _currentRide.destination.address,
                    vehicleType: _currentRide.vehicle.title,
                    distanceKm: _currentRide.distanceKm,
                    couponCode: _currentRide.fareDetails.offerLabel,
                    captainName: _currentRide.captain.name,
                    createdAt: _currentRide.createdAt,
                    updatedAt: _currentRide.completedAt,
                    paidAt: _currentRide.completedAt,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DigitalReceiptScreen(
                        payment: payModel,
                        rideHistoryItem: _currentRide,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 16),
                label: const Text(
                  'View Digital Receipt & Invoice',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final isCancelled = _currentRide.isCancelled;
    final isRated = _currentRide.isRated || _review != null;

    return _buildSectionCard(
      title: 'RATING & REVIEW',
      child: isCancelled
          ? const Text(
              'Ride Cancelled — No rating required.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            )
          : isRated
              ? _buildRatedContent()
              : _buildUnratedContent(),
    );
  }

  Widget _buildRatedContent() {
    final rating = _review?.rating ?? _currentRide.rating ?? 5;
    final reviewText = _review?.reviewText ?? _currentRide.reviewText ?? '';
    final tags = _review?.feedbackTags.map((t) => t.label).toList() ??
        _currentRide.reviewTags ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Rating',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 6),
        StarRatingWidget(
          rating: rating,
          onRatingChanged: (_) {},
          readOnly: true,
          size: 28,
        ),
        if (reviewText.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Your Review',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Text(
              reviewText,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildUnratedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Not Rated',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Share your feedback to help us improve your experience.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          text: 'Rate Ride',
          onPressed: _handleRateRide,
          icon: Icons.star_rate_rounded,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return _buildSectionCard(
      title: 'NEED HELP WITH THIS RIDE?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Having issues with your fare, captain, or vehicle condition? Let our support team assist you.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReportIssueScreen(
                    initialCategory: SupportCategory.rideIssue,
                    preselectedRideId: _currentRide.rideId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            label: const Text(
              'Report an Issue',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
