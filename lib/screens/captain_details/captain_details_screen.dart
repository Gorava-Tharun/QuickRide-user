import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/firestore_models.dart';
import '../../models/ride_model.dart';
import '../../routes/app_routes.dart';
import '../../services/firebase_service.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/safety_service.dart';
import '../../models/ride_history_model.dart';
import '../../models/ride_details_model.dart';
import '../../services/ride_history_service.dart';
import '../../widgets/user_cancellation_dialog.dart';
import '../../widgets/primary_button.dart';
import '../ride_completed/ride_completed_screen.dart';
import '../safety/safety_center_screen.dart';
import '../chat/chat_screen.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';

/// STEP 10: Captain Details & Ride Tracking Screen.
///
/// Features:
/// 1. Real Google Map with Pickup, Destination, and Live Mock Captain Markers.
/// 2. Decoupled [RideTrackingService] simulating smooth captain movement & ETA progression.
/// 3. Dynamic status headers (Captain Found -> Captain is on the way -> Captain has arrived -> Ride in Progress).
/// 4. Captain Profile Card (Name, 4.8 ★ rating, 1,240 completed rides, vehicle model & registration plate).
/// 5. Call & Message Captain action buttons with production notice dialogs.
/// 6. Synchronized Ride Information Card (Pickup, Destination, Vehicle, Locked Fare, Payment Method).
/// 7. "Start Ride" action when captain arrives, transitioning to RIDE_STARTED state.
/// 8. "Cancel Ride" confirmation modal returning cleanly to HomeScreen.
class CaptainDetailsScreen extends StatefulWidget {
  const CaptainDetailsScreen({
    super.key,
    required this.rideRequest,
    this.firestoreRideId,
    this.trackingService,
    this.autoStartArrivingSimulation = true,
  });

  final RideRequest rideRequest;
  final String? firestoreRideId;
  final RideTrackingService? trackingService;
  final bool autoStartArrivingSimulation;

  @override
  State<CaptainDetailsScreen> createState() => _CaptainDetailsScreenState();
}

class _CaptainDetailsScreenState extends State<CaptainDetailsScreen> {
  late RideTrackingService _trackingService;
  GoogleMapController? _mapController;
  StreamSubscription<SharedRideModel?>? _rideDocSub;
  StreamSubscription<Map<String, double>?>? _captainLocSub;

  @override
  void initState() {
    super.initState();
    _trackingService = widget.trackingService ??
        RideTrackingService(initialRequest: widget.rideRequest);

    SafetyService().setActiveRide(_trackingService.currentRequest);
    _trackingService.addListener(_onTrackingUpdate);

    if (widget.firestoreRideId != null && QuickRideFirebaseService().isFirebaseAvailable) {
      _initFirestoreSync();
    } else if (widget.autoStartArrivingSimulation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _trackingService.status == RideStatus.captainFound) {
          _trackingService.startArrivingSimulation();
        }
      });
    }
  }

  void _initFirestoreSync() {
    _rideDocSub = QuickRideFirebaseService().streamRide(widget.firestoreRideId!).listen((ride) {
      if (!mounted || ride == null) return;

      _trackingService.updateStatusFromFirestore(ride.status);
      _handleRideStatusNotification(ride);

      if (ride.status == SharedRideStatus.cancelled && _trackingService.status != RideStatus.cancelled) {
        _trackingService.cancelRide();
        SafetyService().setActiveRide(null);
        _rideDocSub?.cancel();
        _captainLocSub?.cancel();
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLarge)),
              title: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
                  SizedBox(width: 10),
                  Text('Ride Cancelled', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Text(
                ride.cancelledBy == 'captain'
                    ? 'The captain has cancelled the ride.\n\nReason: ${ride.cancellationReason ?? "Captain unavailable"}\n\nAny online payment has been refunded in full.'
                    : 'This ride has been cancelled.',
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (ride.captainLocation != null) {
        final lat = (ride.captainLocation!['latitude'] as num?)?.toDouble();
        final lng = (ride.captainLocation!['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _trackingService.updateCaptainLocationFromGps(lat, lng);
        }
      }

      if (ride.captainId != null && _captainLocSub == null) {
        _subscribeCaptainLocation(ride.captainId!);
      }
    });

    if (widget.rideRequest.captain?.id != null) {
      _subscribeCaptainLocation(widget.rideRequest.captain!.id);
    }
  }

  void _subscribeCaptainLocation(String captainId) {
    _captainLocSub?.cancel();
    _captainLocSub = QuickRideFirebaseService().streamCaptainLocation(captainId).listen((loc) {
      if (!mounted || loc == null) return;
      final lat = (loc['latitude'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _trackingService.updateCaptainLocationFromGps(lat, lng);
      }
    });
  }

  void _handleRideStatusNotification(SharedRideModel ride) {
    final statusName = ride.status.name;
    if (!PushNotificationService().shouldProcessRideEvent(ride.rideId, statusName)) {
      return;
    }

    String title = '';
    String message = '';
    NotificationType notifType = NotificationType.general;

    switch (ride.status) {
      case SharedRideStatus.accepted:
        title = 'Captain Accepted';
        message = 'Your captain ${widget.rideRequest.captain?.name ?? "has"} accepted your ride.';
        notifType = NotificationType.captainFound;
        break;
      case SharedRideStatus.arrived:
        title = 'Captain Has Arrived';
        message = 'Your captain is waiting at the pickup location.';
        notifType = NotificationType.captainArriving;
        break;
      case SharedRideStatus.inProgress:
        title = 'Ride Started';
        message = 'Your ride to ${ride.destination} has started.';
        notifType = NotificationType.rideStarted;
        break;
      case SharedRideStatus.completed:
        title = 'Ride Completed';
        message = 'Your ride has completed successfully. Thank you for riding with QuickRide!';
        notifType = NotificationType.rideCompleted;
        break;
      case SharedRideStatus.cancelled:
        title = 'Ride Cancelled';
        message = 'Your ride has been cancelled.';
        notifType = NotificationType.rideCancelled;
        break;
      default:
        return;
    }

    if (title.isNotEmpty) {
      PushNotificationService().showLocalNotification(
        title: title,
        body: message,
        payload: '${ride.rideId}|${notifType.code}',
      );
      NotificationService().addNotification(
        AppNotification(
          id: 'ride_${ride.rideId}_$statusName',
          type: notifType,
          title: title,
          message: message,
          createdAt: DateTime.now(),
          isRead: false,
          rideId: ride.rideId,
        ),
      );
    }
  }

  void _onTrackingUpdate() {
    if (!mounted) return;
    setState(() {});
    _updateMapCamera();
    SafetyService().setActiveRide(_trackingService.currentRequest);

    if (_trackingService.status == RideStatus.arrived) {
      SafetyService().triggerVerificationNotification(_trackingService.currentRequest.rideId);
    }

    // When the status reaches cancelled, return to home with notice.
    if (_trackingService.status == RideStatus.cancelled) {
      _rideDocSub?.cancel();
      _captainLocSub?.cancel();
      SafetyService().setActiveRide(null);
      _trackingService.removeListener(_onTrackingUpdate);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This ride has been cancelled.')),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        }
      });
      return;
    }

    // When the simulation reaches rideCompleted, navigate to the summary screen.
    if (_trackingService.status == RideStatus.rideCompleted) {
      _rideDocSub?.cancel();
      _captainLocSub?.cancel();
      SafetyService().setActiveRide(null);
      _trackingService.removeListener(_onTrackingUpdate);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => RideCompletedScreen(
                rideRequest: _trackingService.currentRequest,
              ),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _rideDocSub?.cancel();
    _captainLocSub?.cancel();
    _trackingService.removeListener(_onTrackingUpdate);
    if (widget.trackingService == null) {
      _trackingService.dispose();
    }
    super.dispose();
  }

  void _updateMapCamera() {
    final captainLoc = _trackingService.captainLocation;
    final pickup = _trackingService.currentRequest.pickup;
    final destination = _trackingService.currentRequest.destination;

    if (_mapController == null || captainLoc == null) return;

    final lats = [pickup.latitude, destination.latitude, captainLoc.latitude];
    final lngs = [pickup.longitude, destination.longitude, captainLoc.longitude];

    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60.0,
      ),
    );
  }

  Set<Marker> _buildMapMarkers() {
    final req = _trackingService.currentRequest;
    final captainLoc = req.captainLocation;

    final markers = <Marker>{
      // Pickup Marker
      Marker(
        markerId: const MarkerId('pickup_marker'),
        position: LatLng(req.pickup.latitude, req.pickup.longitude),
        infoWindow: InfoWindow(title: AppStrings.pickupMarkerTitle, snippet: req.pickup.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      // Destination Marker
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: LatLng(req.destination.latitude, req.destination.longitude),
        infoWindow: InfoWindow(title: AppStrings.destinationMarkerTitle, snippet: req.destination.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      ),
    };

    if (captainLoc != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('captain_marker'),
          position: LatLng(captainLoc.latitude, captainLoc.longitude),
          rotation: captainLoc.bearing,
          infoWindow: InfoWindow(
            title: req.captain?.name ?? 'Captain',
            snippet: req.status.label,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildMapPolyline() {
    final req = _trackingService.currentRequest;
    return {
      Polyline(
        polylineId: const PolylineId('route_polyline'),
        points: [
          LatLng(req.pickup.latitude, req.pickup.longitude),
          LatLng(req.destination.latitude, req.destination.longitude),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  void _handleCallCaptain() {
    _showNotice('Calling Captain is available in the production version.');
  }

  void _handleMessageCaptain() {
    final req = _trackingService.currentRequest;
    final rideId = widget.firestoreRideId ?? req.rideId;
    String statusStr = 'ACCEPTED';
    switch (_trackingService.status) {
      case RideStatus.searchingForCaptain:
      case RideStatus.noCaptainAvailable:
        statusStr = 'REQUESTED';
        break;
      case RideStatus.captainFound:
      case RideStatus.arriving:
        statusStr = 'ACCEPTED';
        break;
      case RideStatus.arrived:
        statusStr = 'ARRIVED';
        break;
      case RideStatus.rideStarted:
        statusStr = 'IN_PROGRESS';
        break;
      case RideStatus.rideCompleted:
        statusStr = 'COMPLETED';
        break;
      case RideStatus.cancelled:
        statusStr = 'CANCELLED';
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          rideId: rideId,
          currentUserId: req.userId.isNotEmpty ? req.userId : 'user_quickride_01',
          currentUserName: 'Rider',
          captainId: req.captain?.id ?? 'captain_default',
          captainName: req.captain?.name ?? 'Captain',
          captainPhone: req.captain?.phone ?? '',
          vehicleType: req.selectedVehicle.title,
          vehicleNumber: req.captain?.vehicleNumber ?? '',
          rideStatus: statusStr,
        ),
      ),
    );
  }

  void _handleCancelRide() async {
    if (_trackingService.status == RideStatus.rideCompleted) {
      _showNotice('Cannot cancel a completed ride.');
      return;
    }

    final req = _trackingService.currentRequest;
    final rideId = widget.firestoreRideId ?? req.rideId;
    final isOnline = req.paymentMethod == PaymentMethod.online;

    SharedRideStatus currentSharedStatus;
    switch (_trackingService.status) {
      case RideStatus.searchingForCaptain:
      case RideStatus.noCaptainAvailable:
        currentSharedStatus = SharedRideStatus.requested;
        break;
      case RideStatus.captainFound:
      case RideStatus.arriving:
        currentSharedStatus = SharedRideStatus.accepted;
        break;
      case RideStatus.arrived:
        currentSharedStatus = SharedRideStatus.arrived;
        break;
      case RideStatus.rideStarted:
        currentSharedStatus = SharedRideStatus.inProgress;
        break;
      case RideStatus.rideCompleted:
        currentSharedStatus = SharedRideStatus.completed;
        break;
      case RideStatus.cancelled:
        currentSharedStatus = SharedRideStatus.cancelled;
        break;
    }

    final result = await UserCancellationDialog.show(
      context,
      rideId: rideId,
      currentStatus: currentSharedStatus,
      fare: req.fareDetails.effectiveFinalFare,
      isOnlinePaid: isOnline,
      acceptedAt: req.createdAt,
    );

    if (result != null && mounted) {
      if (widget.firestoreRideId != null) {
        await QuickRideFirebaseService().cancelRide(
          widget.firestoreRideId!,
          cancellationReason: result.reason,
          cancellationDescription: result.description,
        );
      }

      SafetyService().setActiveRide(null);
      _trackingService.cancelRide();
      _rideDocSub?.cancel();
      _captainLocSub?.cancel();

      // Record in local history
      RideHistoryService().addCompletedRide(
        RideHistoryItem.fromRequest(req).copyWith(
          status: RideStatus.cancelled,
        ),
      );

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

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = _trackingService.currentRequest;
    final captain = req.captain ?? CaptainModel.demo(vehicleCategoryTitle: req.selectedVehicle.title);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Half: Map View
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(req.pickup.latitude, req.pickup.longitude),
                      zoom: 14.0,
                    ),
                    markers: _buildMapMarkers(),
                    polylines: _buildMapPolyline(),
                    onMapCreated: (ctrl) {
                      _mapController = ctrl;
                      _updateMapCamera();
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),

                  // Overlay Back / Cancel Button
                  Positioned(
                    top: AppDimensions.space12,
                    left: AppDimensions.space12,
                    child: CircleAvatar(
                      backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight, size: 18),
                        onPressed: _handleCancelRide,
                        tooltip: 'Back',
                      ),
                    ),
                  ),

                  // Dynamic Status Banner Overlay
                  Positioned(
                    top: AppDimensions.space12,
                    right: AppDimensions.space12,
                    left: 68,
                    child: _buildLiveStatusBanner(req, captain),
                  ),
                ],
              ),
            ),

            // Bottom Half: Captain Details & Ride Info Card
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: AnimatedBuilder(
                    animation: SafetyService(),
                    builder: (context, _) {
                      final emergency = SafetyService().activeEmergency;
                      final isEmergencyActive = SafetyService().isEmergencyActive;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEmergencyActive && emergency != null) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: AppDimensions.space12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'EMERGENCY SOS ACTIVE (${emergency.statusLabel})\nLive location transmitting to Safety Desk',
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => SafetyCenterScreen(activeRide: req),
                                        ),
                                      );
                                    },
                                    child: const Text('View', style: TextStyle(fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Captain Information Card
                          _buildCaptainProfileCard(captain),
                          const SizedBox(height: AppDimensions.space12),

                          // Contact Action Buttons (Call & Message)
                          _buildContactButtonsRow(),
                          const SizedBox(height: AppDimensions.space16),

                          // Ride Info Synchronized Card
                          _buildRideInfoCard(req),
                          const SizedBox(height: AppDimensions.space16),

                          // Contextual Action Buttons (Start Ride / Cancel Ride)
                          _buildActionButtons(req),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusBanner(RideRequest req, CaptainModel captain) {
    String title;
    String subtitle;
    IconData icon;

    switch (req.status) {
      case RideStatus.arriving:
        title = 'Captain is on the way';
        subtitle = 'Arriving in approximately ${captain.formattedEta}';
        icon = Icons.directions_bike_rounded;
        break;
      case RideStatus.arrived:
        title = 'Captain Has Arrived!';
        subtitle = 'Your captain is waiting at the pickup location.';
        icon = Icons.where_to_vote_rounded;
        break;
      case RideStatus.rideStarted:
        title = 'Ride in Progress';
        subtitle = 'On the way to ${req.destination.name}';
        icon = Icons.navigation_rounded;
        break;
      default:
        title = 'Captain Found';
        subtitle = 'Captain is assigning route...';
        icon = Icons.person_pin_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.primary, width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
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

  Widget _buildCaptainProfileCard(CaptainModel captain) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.8),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 12),

          // Details Column
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
                const SizedBox(height: 2),
                Text(
                  '${captain.vehicleType} • ${captain.vehicleModel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    captain.vehicleNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rating & Completed Rides Badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              const SizedBox(height: 4),
              Text(
                captain.formattedCompletedRides,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtonsRow() {
    final req = _trackingService.currentRequest;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleCallCaptain,
            icon: const Icon(Icons.call_rounded, color: AppColors.primary, size: 18),
            label: const Text(
              'Call Captain',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _handleMessageCaptain,
            icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.secondary, size: 18),
            label: const Text(
              'Message Captain',
              style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Safety Center',
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SafetyCenterScreen(activeRide: req),
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.shield_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideInfoCard(RideRequest req) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.space16),
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
                  req.pickup.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  req.destination.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: AppColors.borderDark, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle: ${req.selectedVehicle.title}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
              ),
              Text(
                'Fare: ${req.fareDetails.formattedFinalFare} (${req.paymentMethodTitle})',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RideRequest req) {
    if (req.status == RideStatus.arrived) {
      return Column(
        children: [
          PrimaryButton(
            text: 'Start Ride',
            onPressed: () => _trackingService.startRide(),
            icon: Icons.play_arrow_rounded,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _handleCancelRide,
            child: const Text(
              'Cancel Ride',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    if (req.status == RideStatus.rideStarted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ride in Progress — En Route to Destination',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
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
    );
  }
}
