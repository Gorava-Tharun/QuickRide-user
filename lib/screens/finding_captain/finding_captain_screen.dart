import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/notification_model.dart';
import '../../models/ride_model.dart';
import '../../models/firestore_models.dart';
import '../../routes/app_routes.dart';
import '../../services/captain_matching_service.dart';
import '../../services/notification_service.dart';
import '../../services/firebase_service.dart';
import '../../services/ride_history_service.dart';
import '../../models/ride_history_model.dart';
import '../../models/ride_details_model.dart';
import '../../widgets/user_cancellation_dialog.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/searching_radar_indicator.dart';
import '../captain_details/captain_details_screen.dart';

/// STEP 9: Finding Your Captain Screen.
///
/// Features:
/// 1. Interactive Google Map displaying Pickup & Destination markers and route polyline.
/// 2. Animated Pulsing Radar Search Indicator.
/// 3. Dynamic status updates ("Finding nearby captains...", "Checking availability...", "Connecting you with a captain...").
/// 4. Decoupled [CaptainMatchingService] handling development search simulation (~5–8 sec).
/// 5. Captain Found State: Displays Captain profile placeholder, rating (4.8 ★), vehicle number, ETA (3 min), and "View Captain" action button.
/// 6. Cancel Ride Flow: Confirmation modal ("Cancel Ride?" -> "Keep Searching" / "Cancel Ride") setting status to CANCELLED and returning to Home.
/// 7. Error / No Captain State: Fallback UI with "Try Again" and "Cancel" buttons.
class FindingCaptainScreen extends StatefulWidget {
  const FindingCaptainScreen({
    super.key,
    required this.rideRequest,
    this.matchingService,
    this.searchDurationSeconds = 6,
    this.simulateNoCaptain = false,
    this.firestoreRideId,
    this.assignedCaptain,
  });

  final RideRequest rideRequest;
  final CaptainMatchingService? matchingService;
  final int searchDurationSeconds;
  final bool simulateNoCaptain;
  final String? firestoreRideId;
  final FirestoreCaptainModel? assignedCaptain;

  @override
  State<FindingCaptainScreen> createState() => _FindingCaptainScreenState();
}

class _FindingCaptainScreenState extends State<FindingCaptainScreen> {
  late CaptainMatchingService _matchingService;
  late RideRequest _currentRideRequest;
  String _currentStatusMessage = 'Finding nearby captains...';
  GoogleMapController? _mapController;
  StreamSubscription<SharedRideModel?>? _rideSubscription;

  @override
  void initState() {
    super.initState();
    _matchingService = widget.matchingService ?? CaptainMatchingService();
    _currentRideRequest = widget.rideRequest;
    if (widget.firestoreRideId != null &&
        QuickRideFirebaseService().isFirebaseAvailable) {
      _listenToFirestoreRide();
    } else {
      _startCaptainSearch();
    }
  }

  void _listenToFirestoreRide() {
    setState(() {
      _currentRideRequest = _currentRideRequest.copyWith(
        status: RideStatus.searchingForCaptain,
      );
      _currentStatusMessage = 'Connecting you with a captain...';
    });

    _rideSubscription = QuickRideFirebaseService()
        .streamRide(widget.firestoreRideId!)
        .listen((ride) async {
      if (ride == null || !mounted) return;

      if (ride.status == SharedRideStatus.accepted &&
          _currentRideRequest.status != RideStatus.captainFound) {
        FirestoreCaptainModel? captainProfile = widget.assignedCaptain;
        if (captainProfile == null && ride.captainId != null) {
          captainProfile = await QuickRideFirebaseService()
              .fetchCaptainProfile(ride.captainId!);
        }

        final matchedCaptain = CaptainModel(
          id: captainProfile?.captainId ?? ride.captainId ?? 'CPT-78901',
          name: captainProfile?.name ?? 'Rajesh Kumar',
          phone: captainProfile?.phone ?? '+91 98765 43210',
          vehicleType: captainProfile?.vehicleType ?? ride.vehicleType,
          vehicleModel:
              captainProfile?.vehicleType ?? 'QuickRide ${ride.vehicleType}',
          vehicleNumber: captainProfile?.vehicleNumber ?? 'KA-05-HA-1234',
          rating: captainProfile?.rating ?? 4.88,
          completedRides: 148,
          estimatedArrivalMinutes: 3,
        );

        NotificationService().addNotification(
          AppNotification(
            id: 'notif_found_${_currentRideRequest.rideId}',
            type: NotificationType.captainFound,
            title: 'Captain Found',
            message:
                'Your captain ${matchedCaptain.name} has accepted your ride request.',
            createdAt: DateTime.now(),
            rideId: _currentRideRequest.rideId,
          ),
        );

        if (mounted) {
          setState(() {
            _currentRideRequest = _currentRideRequest.copyWith(
              status: RideStatus.captainFound,
              captain: matchedCaptain,
            );
            _currentStatusMessage = 'Captain accepted your ride!';
          });
        }
      } else if (ride.status == SharedRideStatus.cancelled &&
          _currentRideRequest.status != RideStatus.cancelled) {
        if (mounted) {
          setState(() {
            _currentRideRequest = _currentRideRequest.copyWith(
              status: RideStatus.cancelled,
            );
          });
        }
      }
    });
  }

  void _startCaptainSearch() async {
    setState(() {
      _currentRideRequest = _currentRideRequest.copyWith(
        status: RideStatus.searchingForCaptain,
      );
      _currentStatusMessage = 'Finding nearby captains...';
    });

    final matchedCaptain = await _matchingService.searchForCaptain(
      rideRequest: _currentRideRequest,
      totalDurationSeconds: widget.searchDurationSeconds,
      simulateNoCaptain: widget.simulateNoCaptain,
      onStatusUpdate: (status) {
        if (mounted) {
          setState(() {
            _currentStatusMessage = status;
          });
        }
      },
    );

    if (!mounted) return;

    if (matchedCaptain != null) {
      NotificationService().addNotification(
        AppNotification(
          id: 'notif_found_${_currentRideRequest.rideId}',
          type: NotificationType.captainFound,
          title: 'Captain Found',
          message: 'Your captain ${matchedCaptain.name} has been assigned to your ride.',
          createdAt: DateTime.now(),
          rideId: _currentRideRequest.rideId,
        ),
      );
      setState(() {
        _currentRideRequest = _currentRideRequest.copyWith(
          status: RideStatus.captainFound,
          captain: matchedCaptain,
        );
      });
    } else {
      setState(() {
        _currentRideRequest = _currentRideRequest.copyWith(
          status: RideStatus.noCaptainAvailable,
        );
      });
    }
  }

  void _handleCancelRide() async {
    final rideId = widget.firestoreRideId ?? _currentRideRequest.rideId;
    final isOnline = _currentRideRequest.paymentMethod == PaymentMethod.online;

    final result = await UserCancellationDialog.show(
      context,
      rideId: rideId,
      currentStatus: SharedRideStatus.requested,
      fare: _currentRideRequest.fareDetails.effectiveFinalFare,
      isOnlinePaid: isOnline,
    );

    if (result != null && mounted) {
      if (widget.firestoreRideId != null) {
        await QuickRideFirebaseService().cancelRide(
          widget.firestoreRideId!,
          cancellationReason: result.reason,
          cancellationDescription: result.description,
        );
      }
      _rideSubscription?.cancel();

      setState(() {
        _currentRideRequest = _currentRideRequest.copyWith(
          status: RideStatus.cancelled,
        );
      });

      // Save to local ride history
      RideHistoryService().addCompletedRide(
        RideHistoryItem.fromRequest(_currentRideRequest).copyWith(
          status: RideStatus.cancelled,
        ),
      );

      // Show post-cancellation summary sheet
      if (mounted) {
        await UserCancellationDialog.showSummarySheet(
          context,
          rideId: rideId,
          reason: result.reason,
          description: result.description,
          cancellationFee: result.cancellationFee,
          refundAmount: result.refundAmount,
          isOnlinePaid: isOnline,
          onDone: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }

  void _handleViewCaptain() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CaptainDetailsScreen(
          rideRequest: _currentRideRequest,
          firestoreRideId: widget.firestoreRideId,
        ),
      ),
    );
  }

  Set<Marker> _buildMapMarkers() {
    final pickup = _currentRideRequest.pickup;
    final destination = _currentRideRequest.destination;

    return {
      Marker(
        markerId: const MarkerId('pickup_marker'),
        position: LatLng(pickup.latitude, pickup.longitude),
        infoWindow: InfoWindow(
          title: AppStrings.pickupMarkerTitle,
          snippet: pickup.name,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: LatLng(destination.latitude, destination.longitude),
        infoWindow: InfoWindow(
          title: AppStrings.destinationMarkerTitle,
          snippet: destination.name,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    };
  }

  Set<Polyline> _buildMapPolyline() {
    final pickup = _currentRideRequest.pickup;
    final destination = _currentRideRequest.destination;

    return {
      Polyline(
        polylineId: const PolylineId('route_line'),
        points: [
          LatLng(pickup.latitude, pickup.longitude),
          LatLng(destination.latitude, destination.longitude),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final pickup = _currentRideRequest.pickup;
    final destination = _currentRideRequest.destination;

    final southWestLat = pickup.latitude < destination.latitude ? pickup.latitude : destination.latitude;
    final southWestLng = pickup.longitude < destination.longitude ? pickup.longitude : destination.longitude;
    final northEastLat = pickup.latitude > destination.latitude ? pickup.latitude : destination.latitude;
    final northEastLng = pickup.longitude > destination.longitude ? pickup.longitude : destination.longitude;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(southWestLat, southWestLng),
          northeast: LatLng(northEastLat, northEastLng),
        ),
        60.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Half: Google Map View
            Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _currentRideRequest.pickup.latitude,
                            _currentRideRequest.pickup.longitude,
                          ),
                          zoom: 14.0,
                        ),
                        markers: _buildMapMarkers(),
                        polylines: _buildMapPolyline(),
                        onMapCreated: _onMapCreated,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                      ),

                      // Overlay Back Button
                      Positioned(
                        top: AppDimensions.space12,
                        left: AppDimensions.space12,
                        child: CircleAvatar(
                          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.85),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight, size: 18),
                            onPressed: _handleCancelRide,
                            tooltip: 'Back',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Half: Status Card & Controls
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
                    ),
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: _buildBottomContent(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomContent() {
    switch (_currentRideRequest.status) {
      case RideStatus.searchingForCaptain:
        return _buildSearchingView();
      case RideStatus.captainFound:
        return _buildCaptainFoundView();
      case RideStatus.noCaptainAvailable:
        return _buildNoCaptainView();
      case RideStatus.cancelled:
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSearchingView() {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Animated Pulsing Radar Search Indicator
        const SearchingRadarIndicator(size: 60),

        const SizedBox(height: 16),

        const Text(
          'Finding your Captain',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          _currentStatusMessage,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 16),

        // Trip Mini Card
        _buildMiniTripCard(),

        const Spacer(),

        // Cancel Ride Button
        OutlinedButton.icon(
          onPressed: _handleCancelRide,
          icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
          label: const Text(
            'Cancel Ride',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: AppColors.error, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptainFoundView() {
    final captain = _currentRideRequest.captain!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Captain Found!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Arriving in ${captain.formattedEta}',
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
          ),

          const SizedBox(height: AppDimensions.space16),

          // Captain Details Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.borderDark, width: 1.2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            captain.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${captain.vehicleType} • ${captain.vehicleNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            captain.formattedRating,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryLight,
                            ),
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

                // Pickup & Destination Summary
                _buildMiniTripCard(),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space20),

          // View Captain Button
          PrimaryButton(
            text: 'View Captain',
            onPressed: _handleViewCaptain,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildNoCaptainView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error, width: 1.5),
          ),
          child: const Icon(
            Icons.person_off_rounded,
            color: AppColors.error,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No Captain Available',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We couldn\'t find an available captain nearby. Please try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancelRide,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.borderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: 'Try Again',
                onPressed: _startCaptainSearch,
                icon: Icons.refresh_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniTripCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentRideRequest.pickup.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentRideRequest.destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
