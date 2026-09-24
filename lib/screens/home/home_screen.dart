import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/location_model.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/route_service.dart';
import '../../widgets/location_search_dialog.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/route_summary_card.dart';
import '../../models/firestore_models.dart';
import '../../models/ride_model.dart';
import '../../services/firebase_service.dart';
import '../../services/session_manager.dart';
import '../captain_details/captain_details_screen.dart';
import '../finding_captain/finding_captain_screen.dart';
import '../notifications/notification_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/profile_screen.dart';
import '../ride_history/ride_history_screen.dart';
import '../vehicle_selection/vehicle_selection_screen.dart';
import '../ride_completed/ride_completed_screen.dart';
import '../chat/chat_screen.dart';
import '../payment/payment_history_screen.dart';
import '../help_support/my_support_requests_screen.dart';
import '../safety/safety_center_screen.dart';
import '../../services/push_notification_service.dart';
import '../../widgets/offline_banner.dart';

/// STEP 5: QuickRide User Home Screen with Pickup & Destination Selection.
///
/// Features:
/// - Real Google Maps view with live camera controls and eager gesture handling.
/// - Dynamic Pickup & Destination selection with auto-reverse geocoding.
/// - Distinct markers: Pickup (Green/Yellow hue) and Destination (Red hue).
/// - Polyline route preview showing geodesic paths and waypoints.
/// - Real-time distance (km) and estimated travel time (min) calculation.
/// - Camera fitting to bounds of both pickup and destination.
/// - Swap locations button (↕) exchanging pickup & destination instantly.
/// - Strict validations (missing pickup, missing destination, duplicate locations).
/// - Continue button passing trip metrics payload to Step 6 placeholder.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  GoogleMapController? _mapController;

  // Active Location State
  late LocationPoint _pickupLocation;
  LocationPoint? _destinationLocation;
  RouteDetails? _routeDetails;

  // Markers & Polylines
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isLocating = false;
  bool _isLocationPermissionDenied = false;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Default pickup initialization (Current Location / Bengaluru default)
    _pickupLocation = const LocationPoint(
      latitude: LocationService.defaultLatitude,
      longitude: LocationService.defaultLongitude,
      name: AppStrings.currentLocation,
      address: 'Bengaluru, Karnataka, India',
    );
    _rebuildMapMarkers();
    PushNotificationService().initialize(
      userId: SessionManager().currentUser.userId,
      onNotificationTap: _handleNotificationTap,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveRideRecovery();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _handleNotificationTap(String rideId, String type, [Map<String, dynamic>? data]) async {
    if (!mounted) return;

    // Handle support and complaint notifications without rideId
    if (type == 'COMPLAINT_STATUS_UPDATE' ||
        type == 'COMPLAINT_REPLY' ||
        type == 'NEW_COMPLAINT' ||
        type == 'SUPPORT_UPDATE') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MySupportRequestsScreen()),
      );
      return;
    }

    if (type == 'PAYMENT_SUCCESS' || type == 'PAYMENT_REFUNDED') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
      );
      return;
    }

    if (rideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification details are no longer active.')),
      );
      return;
    }

    final fb = QuickRideFirebaseService();
    if (!fb.isFirebaseAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline mode: Notification details available once reconnected.')),
      );
      return;
    }

    final ride = await fb.fetchRide(rideId);
    if (!mounted) return;
    if (ride == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride information is no longer active.')),
      );
      return;
    }

    if (type == 'CHAT_MESSAGE') {
      if (ride.captainId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No captain assigned to this ride.')),
        );
        return;
      }
      final cap = await fb.fetchCaptainProfile(ride.captainId!);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            rideId: ride.rideId,
            currentUserId: SessionManager().currentUser.userId,
            currentUserName: SessionManager().currentUser.fullName,
            captainId: ride.captainId!,
            captainName: cap?.name ?? 'Captain',
            captainPhone: cap?.phone ?? '9876543210',
            vehicleType: cap?.vehicleType ?? ride.vehicleType,
            vehicleNumber: cap?.vehicleNumber ?? '',
            rideStatus: ride.status.firestoreValue,
          ),
        ),
      );
      return;
    }

    if (type == 'EMERGENCY_ALERT' || type == 'EMERGENCY_STATUS') {
      final req = RideRequest.fromSharedRide(ride);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SafetyCenterScreen(activeRide: req),
        ),
      );
      return;
    }

    if (ride.status == SharedRideStatus.completed) {
      final req = RideRequest.fromSharedRide(ride);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RideCompletedScreen(rideRequest: req),
        ),
      );
    } else if (ride.status == SharedRideStatus.accepted ||
               ride.status == SharedRideStatus.arrived ||
               ride.status == SharedRideStatus.inProgress) {
      CaptainModel? captainModel;
      if (ride.captainId != null) {
        final cap = await fb.fetchCaptainProfile(ride.captainId!);
        if (cap != null) {
          captainModel = CaptainModel(
            id: cap.captainId,
            name: cap.name,
            vehicleType: cap.vehicleType,
            vehicleModel: 'Standard Vehicle',
            vehicleNumber: cap.vehicleNumber,
            rating: cap.rating,
            completedRides: 150,
            estimatedArrivalMinutes: 3,
            phone: cap.phone,
          );
        }
      }
      final req = RideRequest.fromSharedRide(ride, captain: captainModel);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaptainDetailsScreen(
            rideRequest: req,
            firestoreRideId: ride.rideId,
          ),
        ),
      );
    } else if (ride.status == SharedRideStatus.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your ride has been cancelled.')),
      );
    }
  }

  /// App Restart Recovery: check if the user has an active ride in Firestore
  Future<void> _checkActiveRideRecovery() async {
    final fbService = QuickRideFirebaseService();
    if (!fbService.isFirebaseAvailable) return;

    final userId = SessionManager().currentUser.userId;
    final activeRide = await fbService.fetchActiveRideForUser(userId);
    if (activeRide == null || !mounted) return;

    CaptainModel? captainModel;
    if (activeRide.captainId != null) {
      final cap = await fbService.fetchCaptainProfile(activeRide.captainId!);
      if (cap != null) {
        captainModel = CaptainModel(
          id: cap.captainId,
          name: cap.name,
          vehicleType: cap.vehicleType,
          vehicleModel: 'Standard Vehicle',
          vehicleNumber: cap.vehicleNumber,
          rating: cap.rating,
          completedRides: 150,
          estimatedArrivalMinutes: 3,
          phone: cap.phone,
        );
      }
    }

    final rideReq = RideRequest.fromSharedRide(activeRide, captain: captainModel);

    if (!mounted) return;

    if (activeRide.status == SharedRideStatus.requested) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FindingCaptainScreen(
            rideRequest: rideReq,
            firestoreRideId: activeRide.rideId,
          ),
        ),
      );
    } else if (activeRide.status == SharedRideStatus.accepted ||
               activeRide.status == SharedRideStatus.arrived ||
               activeRide.status == SharedRideStatus.inProgress) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaptainDetailsScreen(
            rideRequest: rideReq,
            firestoreRideId: activeRide.rideId,
          ),
        ),
      );
    }
  }

  /// Request user GPS coordinates and update pickup location.
  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);

    final result = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (result.isPermissionGranted && result.position != null) {
      final pos = result.position!;
      final newPickup = LocationPoint(
        latitude: pos.latitude,
        longitude: pos.longitude,
        name: AppStrings.currentLocation,
        address: LocationService.formatCoordinatesAddress(
          pos.latitude,
          pos.longitude,
          defaultName: 'Current Location',
        ),
      );

      setState(() {
        _isLocating = false;
        _isLocationPermissionDenied = false;
        _pickupLocation = newPickup;
      });

      _updateRouteAndCamera();
      _showNotice('Current location detected successfully.');
    } else {
      setState(() {
        _isLocating = false;
        _isLocationPermissionDenied = true;
      });
      _showNotice(
        result.errorMessage ?? AppStrings.locationPermissionDeniedNotice,
        isError: true,
      );
    }
  }

  /// Handles user tapping on map to select pickup or destination.
  void _onMapTapped(LatLng point) {
    if (_destinationLocation == null) {
      // If destination not yet set, set destination
      _setDestination(
        LocationPoint(
          latitude: point.latitude,
          longitude: point.longitude,
          name: 'Selected Destination',
          address: LocationService.formatCoordinatesAddress(point.latitude, point.longitude),
        ),
      );
      _showNotice('Destination marked on map.');
    } else {
      // Destination exists, update pickup location to tapped point
      setState(() {
        _pickupLocation = LocationPoint(
          latitude: point.latitude,
          longitude: point.longitude,
          name: 'Custom Pickup',
          address: LocationService.formatCoordinatesAddress(point.latitude, point.longitude),
        );
      });
      _updateRouteAndCamera();
      _showNotice('Pickup location updated from map.');
    }
  }

  /// Opens search dialog for Pickup.
  Future<void> _handleSearchPickup() async {
    final selected = await LocationSearchDialog.show(
      context,
      title: 'Select Pickup Location',
      initialQuery: _pickupLocation.name == AppStrings.currentLocation ? '' : _pickupLocation.name,
      isPickup: true,
    );

    if (selected != null && mounted) {
      setState(() {
        _pickupLocation = selected;
      });
      _updateRouteAndCamera();
    }
  }

  /// Opens search dialog for Destination.
  Future<void> _handleSearchDestination() async {
    final selected = await LocationSearchDialog.show(
      context,
      title: 'Select Destination',
      initialQuery: _destinationLocation?.name ?? '',
      isPickup: false,
    );

    if (selected != null && mounted) {
      _setDestination(selected);
    }
  }

  void _setDestination(LocationPoint destination) {
    setState(() {
      _destinationLocation = destination;
    });
    _updateRouteAndCamera();
  }

  /// Swaps pickup and destination.
  void _handleSwapLocations() {
    if (_destinationLocation == null) {
      _showNotice('Please select a destination to swap.', isError: true);
      return;
    }

    setState(() {
      final temp = _pickupLocation;
      _pickupLocation = _destinationLocation!;
      _destinationLocation = temp;
    });

    _updateRouteAndCamera();
    _showNotice('Pickup and destination swapped.');
  }

  /// Rebuilds markers, polyline route, and fits camera bounds.
  void _updateRouteAndCamera() {
    _rebuildMapMarkers();

    if (_destinationLocation != null) {
      final route = RouteService.generateRoute(_pickupLocation, _destinationLocation!);
      setState(() {
        _routeDetails = route;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route_preview'),
            points: route.polylinePoints,
            color: AppColors.primary,
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        };
      });

      _fitCameraToBounds(_pickupLocation.toLatLng(), _destinationLocation!.toLatLng());
    } else {
      setState(() {
        _routeDetails = null;
        _polylines = {};
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickupLocation.toLatLng(), zoom: 15.5),
        ),
      );
    }
  }

  void _rebuildMapMarkers() {
    final markers = <Marker>{};

    // 1. Pickup Marker (Yellow/Green)
    markers.add(
      Marker(
        markerId: const MarkerId('pickup_marker'),
        position: _pickupLocation.toLatLng(),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: InfoWindow(
          title: AppStrings.pickupMarkerTitle,
          snippet: _pickupLocation.name,
        ),
      ),
    );

    // 2. Destination Marker (Red)
    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_marker'),
          position: _destinationLocation!.toLatLng(),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: AppStrings.destinationMarkerTitle,
            snippet: _destinationLocation!.name,
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// Smoothly animates camera to fit both pickup and destination with padding.
  void _fitCameraToBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;

    final southwest = LatLng(
      p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
      p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
    );
    final northeast = LatLng(
      p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
      p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
    );

    final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 65.0),
    );
  }

  /// Validates locations and proceeds to the Step 6 placeholder.
  void _handleContinue() {
    // 1. Validate Pickup
    if (_pickupLocation.name.trim().isEmpty) {
      _showNotice(AppStrings.errorMissingPickup, isError: true);
      return;
    }

    // 2. Validate Destination
    if (_destinationLocation == null || _destinationLocation!.name.trim().isEmpty) {
      _showNotice(AppStrings.errorMissingDestination, isError: true);
      return;
    }

    // 3. Validate distinct locations
    final distKm = LocationService.calculateDistanceKm(
      _pickupLocation.latitude,
      _pickupLocation.longitude,
      _destinationLocation!.latitude,
      _destinationLocation!.longitude,
    );

    if (distKm < 0.05 || _pickupLocation.name.toLowerCase() == _destinationLocation!.name.toLowerCase()) {
      _showNotice(AppStrings.errorSameLocations, isError: true);
      return;
    }

    final route = _routeDetails ?? RouteService.generateRoute(_pickupLocation, _destinationLocation!);

    // Navigate to Step 6: Vehicle Selection Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => VehicleSelectionScreen(routeDetails: route),
      ),
    );
  }

  void _showNotice(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Network Offline Status Banner
              const OfflineBanner(),
              const SizedBox(height: AppDimensions.space8),

              // 1. Top Header Section
              _buildTopHeader(),
              const SizedBox(height: AppDimensions.space16),

              // 2. Location Permission Warning Banner (if denied)
              if (_isLocationPermissionDenied) ...[
                _buildPermissionDeniedBanner(),
                const SizedBox(height: AppDimensions.space12),
              ],

              // 3. Google Maps Interactive View with Polyline & Markers
              _buildGoogleMapView(),
              const SizedBox(height: AppDimensions.space16),

              // 4. Pickup & Destination Selection Card with Swap Button
              RouteSummaryCard(
                pickup: _pickupLocation,
                destination: _destinationLocation,
                onTapPickup: _handleSearchPickup,
                onTapDestination: _handleSearchDestination,
                onSwap: _handleSwapLocations,
                routeDetails: _routeDetails,
              ),
              const SizedBox(height: AppDimensions.space20),

              // 5. Continue Button
              PrimaryButton(
                text: AppStrings.continueButton,
                onPressed: _handleContinue,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: AppDimensions.space20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                AppStrings.homeGreeting,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                AppStrings.whereToQuestion,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationBell(),
            const SizedBox(width: AppDimensions.space8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return AnimatedBuilder(
      animation: _notificationService,
      builder: (context, _) {
        final unread = _notificationService.unreadCount;
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderDark, width: 1.2),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimaryLight,
                    size: 22,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unread > 99 ? '99+' : unread.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionDeniedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1B14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: Colors.amberAccent, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: Colors.amberAccent, size: 24),
          const SizedBox(width: AppDimensions.space12),
          const Expanded(
            child: Text(
              AppStrings.locationPermissionDeniedNotice,
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => LocationService.openAppSettings(),
            child: const Text(
              AppStrings.openSettings,
              style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapView() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickupLocation.toLatLng(),
                zoom: 15.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _onMapTapped,
              markers: _markers,
              polylines: _polylines,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              myLocationEnabled: !_isLocationPermissionDenied,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: true,
            ),

            // Locate Me FAB overlay button
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'locate_me_fab',
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: AppColors.primary,
                onPressed: _fetchCurrentLocation,
                tooltip: 'My location',
                child: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
              ),
            ),

            // Top hint banner
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 13, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      AppStrings.tapToSelectOnMap,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => _selectedNavIndex = 0);
          } else if (index == 1) {
            Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (_) => const RideHistoryScreen(),
            ))
                .then((_) {
              if (mounted) setState(() => _selectedNavIndex = 0);
            });
          } else if (index == 2) {
            Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (_) => const OffersScreen(),
            ))
                .then((_) {
              if (mounted) setState(() => _selectedNavIndex = 0);
            });
          } else if (index == 3) {
            Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (_) => const ProfileScreen(),
            ))
                .then((_) {
              if (mounted) setState(() => _selectedNavIndex = 0);
            });
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
