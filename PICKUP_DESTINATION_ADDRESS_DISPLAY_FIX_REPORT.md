# QuickRide — Pickup & Destination Address Display Fix Report

**Project Title:** QuickRide – Ride Booking Application  
**Report Type:** Technical Bug Fix & Architecture Investigation Report  
**Application:** QuickRide User App (`quickride_user`)  
**College:** Government Polytechnic College, Dharmavaram  
**Department:** Computer Science and Engineering (CSE)  
**Academic Year:** 2026–2027  

---

## 1. Problem Statement

When selecting pickup or destination locations on Google Maps within the QuickRide User App, the map pin and coordinate selection operated normally. However, the pickup and destination input fields consistently displayed **"Address unavailable"** or generic coordinates instead of human-readable street addresses.

### User Impact
- Passengers could not verify the exact street address, locality, or landmark before requesting a ride.
- Manual editing was hampered by automatic resets to "Address unavailable" whenever the map widget rebuilt.
- Coordinates were occasionally mixed between pickup and destination during quick interactive taps.

---

## 2. Root Cause Analysis

A thorough code audit of `lib/screens/home/home_screen.dart`, `lib/services/location_service.dart`, and `lib/widgets/route_summary_card.dart` identified four distinct root causes:

1. **Incomplete Reverse Geocoding Parsing (`LocationService`)**:
   - The reverse geocoding method relied on strict non-null checks on `Placemark.thoroughfare` and `Placemark.subThoroughfare`.
   - In semi-urban and rural areas (such as Dharmavaram and surrounding regions), Google Geocoding APIs often omit specific street numbers (`subThoroughfare`), providing only `locality`, `subLocality`, and `postalCode`.
   - Because of rigid parsing logic, the method aborted early and defaulted to returning `"Address unavailable"`.

2. **Asynchronous Out-of-Order Race Conditions**:
   - Tapping multiple points on Google Maps triggered multiple asynchronous reverse geocoding requests.
   - If an earlier tap took longer to resolve over the network than a subsequent tap, the older response overwrote the newer selection in the UI.

3. **Controller Reinitialization on Widget Rebuilds**:
   - `TextEditingController` instances for pickup and destination were recreated inside build cycles, wiping out active user text edits and geocoded values.

4. **Pickup & Destination State Coupling**:
   - Marker dragging on the map updated shared temporary coordinate variables without strict guard flags separating pickup mode from destination mode.

---

## 3. Implemented Technical Fixes

### 3.1 Robust Multi-Tier Address Formatter (`LocationService`)
Updated `LocationService.reverseGeocodePoint` to employ a resilient multi-tier fallback mechanism:
```dart
static Future<LocationPoint> reverseGeocodePoint(
  double latitude,
  double longitude, {
  String defaultName = 'Selected Location',
}) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final parts = <String>[];

      // 1. Street / Road / Landmark
      if (p.street != null && p.street!.isNotEmpty) {
        parts.add(p.street!);
      } else if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty) {
        parts.add(p.thoroughfare!);
      }

      // 2. Sub-locality / Colony / Area
      if (p.subLocality != null && p.subLocality!.isNotEmpty) {
        parts.add(p.subLocality!);
      }

      // 3. Locality / City / Town
      if (p.locality != null && p.locality!.isNotEmpty) {
        parts.add(p.locality!);
      }

      // 4. Postal Code & State
      if (p.postalCode != null && p.postalCode!.isNotEmpty) {
        parts.add(p.postalCode!);
      }

      final formattedAddress = parts.isNotEmpty
          ? parts.join(', ')
          : '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

      return LocationPoint(
        latitude: latitude,
        longitude: longitude,
        name: p.name?.isNotEmpty == true ? p.name! : defaultName,
        address: formattedAddress,
      );
    }
  } catch (e) {
    // Graceful fallback to readable coordinate string instead of error placeholder
    return LocationPoint(
      latitude: latitude,
      longitude: longitude,
      name: defaultName,
      address: '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
    );
  }
}
```

### 3.2 Monotonic Sequence Counters to Eliminate Race Conditions
Implemented sequence locks in `HomeScreen`:
- `_pickupGeocodeSeq`: Incremented on every pickup map tap/drag.
- `_destinationGeocodeSeq`: Incremented on every destination map tap/drag.
Responses arriving from older network requests check their sequence ID against the latest counter and discard stale payloads immediately.

### 3.3 Persistent Controller Lifecycle
- Initialized `_pickupController` and `_destinationController` once inside `initState()`.
- Properly freed resources in `dispose()`.
- Two-way binding between controller text and `LocationPoint.address` guarantees user edits are preserved without overwriting map selections.

### 3.4 Isolated Mode Enums & Distinct Markers
- Clear separation between `_isSelectingPickupOnMap` and `_isSelectingDestinationOnMap`.
- Preserved Google Maps integration (no OpenStreetMap fallback).
- Distinct marker colors:
  - Pickup: Yellow/Green draggable pin with custom InfoWindow.
  - Destination: Red draggable pin with custom InfoWindow.
  - GPS: Cyan user location dot.

---

## 4. Verification & Testing

### Automated Test Suite (`test/pickup_destination_address_display_test.dart`)
1. **Scenario 1**: Select pickup from Google Maps → street address immediately populates pickup text controller.
2. **Scenario 2**: Select destination from Google Maps → street address immediately populates destination text controller.
3. **Scenario 3**: Rapid successive map taps → sequence guard discards out-of-order responses, displaying only the latest address.
4. **Scenario 4**: Manual text entry → text field edits preserved without reverting to geocoded coordinates.
5. **Scenario 5**: Swap button → pickup and destination addresses, text fields, and map pins swap cleanly.

All automated tests passed with 0 errors.

---

## 5. Conclusion

The address display defect has been resolved at the architectural level. Google Maps reverse geocoding now reliably delivers formatted street, locality, city, and postal code data into both pickup and destination text fields, ensuring a seamless user experience during college demonstrations and production use.
