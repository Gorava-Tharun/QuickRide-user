/// Centralized Google Maps & Places configuration for QuickRide.
///
/// The API key is loaded from compile-time environment variables when specified,
/// or uses the project's configured key from local.properties / index.html.
///
/// CRITICAL: In accordance with project security guidelines, this key MUST NEVER
/// be printed in debug logs, error messages, or exposed in the user interface.
class GoogleMapsConfig {
  static const String apiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyDH0Nmmd1s9eZ0CVxYaMaQK8MuulugvaAc',
  );

  /// Default center coordinates for Indian subcontinent hub (Bengaluru, Karnataka)
  static const double defaultLat = 12.9716;
  static const double defaultLng = 77.5946;

  /// Default search radius for local place discovery (50 km)
  static const double defaultSearchRadiusMeters = 50000.0;
}
