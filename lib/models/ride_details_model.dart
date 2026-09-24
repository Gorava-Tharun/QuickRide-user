import 'fare_model.dart';
import 'location_model.dart';
import 'vehicle_model.dart';

/// Available payment methods for QuickRide.
enum PaymentMethod {
  cash,
  online,
}

/// Comprehensive model encapsulating a confirmed ride request before dispatch.
class RideDetails {
  const RideDetails({
    required this.routeDetails,
    required this.selectedVehicle,
    required this.fareDetails,
    this.paymentMethod = PaymentMethod.cash,
    required this.timestamp,
  });

  final RouteDetails routeDetails;
  final VehicleOption selectedVehicle;
  final FareDetails fareDetails;
  final PaymentMethod paymentMethod;
  final DateTime timestamp;

  String get paymentMethodTitle {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.online:
        return 'Online Payment';
    }
  }

  RideDetails copyWith({
    RouteDetails? routeDetails,
    VehicleOption? selectedVehicle,
    FareDetails? fareDetails,
    PaymentMethod? paymentMethod,
    DateTime? timestamp,
  }) {
    return RideDetails(
      routeDetails: routeDetails ?? this.routeDetails,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      fareDetails: fareDetails ?? this.fareDetails,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
