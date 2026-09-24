import '../models/ride_model.dart';

/// Reusable data model representing sanitized trip details for secure sharing.
///
/// Designed for future backend trip-sharing links while keeping sensitive
/// personal information protected.
class TripShareData {
  const TripShareData({
    required this.rideId,
    required this.userName,
    required this.pickup,
    required this.destination,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.captainName,
    this.captainPhonePlaceholder = 'Protected by QuickRide Shield',
    required this.rideStatus,
    required this.estimatedArrival,
    this.currentLocation = 'En route to destination',
  });

  final String rideId;
  final String userName;
  final String pickup;
  final String destination;
  final String vehicleType;
  final String vehicleNumber;
  final String captainName;
  final String captainPhonePlaceholder;
  final String rideStatus;
  final String estimatedArrival;
  final String currentLocation;

  /// Creates a [TripShareData] instance from an active [RideRequest].
  factory TripShareData.fromRideRequest(
    RideRequest req, {
    String userName = 'QuickRide Passenger',
  }) {
    final captain = req.captain;
    return TripShareData(
      rideId: req.rideId,
      userName: userName,
      pickup: req.pickup.name,
      destination: req.destination.name,
      vehicleType: req.selectedVehicle.title,
      vehicleNumber: captain?.vehicleNumber ?? 'Assigned on arrival',
      captainName: captain?.name ?? 'Assigned Captain',
      captainPhonePlaceholder: 'Protected by QuickRide Shield',
      rideStatus: req.status.name,
      estimatedArrival: captain != null ? captain.formattedEta : '${req.estimatedMinutes} mins',
      currentLocation: '${req.pickup.name} -> ${req.destination.name}',
    );
  }

  /// Default demo trip share data used when no active ride is in session.
  factory TripShareData.demo() {
    return const TripShareData(
      rideId: 'QR-DEMO-789',
      userName: 'Demo Rider',
      pickup: 'MG Road Metro Station',
      destination: 'Indiranagar 100ft Road',
      vehicleType: 'Comfort Sedan',
      vehicleNumber: 'KA 03 AB 4567',
      captainName: 'Rajesh Kumar',
      captainPhonePlaceholder: 'Protected by QuickRide Shield',
      rideStatus: 'inProgress',
      estimatedArrival: '12 mins',
      currentLocation: 'Approaching Domlur Flyover',
    );
  }

  /// Generates human-readable summary text for sharing.
  String formattedShareText() {
    return '''
QuickRide Trip Details:
Rider: $userName
From: $pickup
To: $destination
Vehicle: $vehicleType ($vehicleNumber)
Captain: $captainName
Status: $rideStatus (ETA: $estimatedArrival)
Track safely with QuickRide.
''';
  }

  TripShareData copyWith({
    String? rideId,
    String? userName,
    String? pickup,
    String? destination,
    String? vehicleType,
    String? vehicleNumber,
    String? captainName,
    String? captainPhonePlaceholder,
    String? rideStatus,
    String? estimatedArrival,
    String? currentLocation,
  }) {
    return TripShareData(
      rideId: rideId ?? this.rideId,
      userName: userName ?? this.userName,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      captainName: captainName ?? this.captainName,
      captainPhonePlaceholder: captainPhonePlaceholder ?? this.captainPhonePlaceholder,
      rideStatus: rideStatus ?? this.rideStatus,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'userName': userName,
      'pickup': pickup,
      'destination': destination,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'captainName': captainName,
      'captainPhonePlaceholder': captainPhonePlaceholder,
      'rideStatus': rideStatus,
      'estimatedArrival': estimatedArrival,
      'currentLocation': currentLocation,
    };
  }

  factory TripShareData.fromJson(Map<String, dynamic> json) {
    return TripShareData(
      rideId: json['rideId'] as String? ?? 'QR-UNKNOWN',
      userName: json['userName'] as String? ?? 'Passenger',
      pickup: json['pickup'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      vehicleNumber: json['vehicleNumber'] as String? ?? '',
      captainName: json['captainName'] as String? ?? '',
      captainPhonePlaceholder: json['captainPhonePlaceholder'] as String? ??
          'Protected by QuickRide Shield',
      rideStatus: json['rideStatus'] as String? ?? 'active',
      estimatedArrival: json['estimatedArrival'] as String? ?? '',
      currentLocation: json['currentLocation'] as String? ?? '',
    );
  }
}
