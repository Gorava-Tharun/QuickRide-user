# QuickRide User App (`quickride_user`)

<p align="center">
  <img src="../screenshots/user_home_map.png" alt="QuickRide User App" width="450" style="border-radius: 8px;" />
</p>

The official passenger client for the **QuickRide** on-demand ride-booking ecosystem, built with Flutter, Firebase, and Google Maps.

---

## 🌟 Key Features
- **Interactive Google Maps Interface:** Automatic current geolocation, dynamic pin dropping, and route preview.
- **Places Autocomplete & Geocoding:** Search and select pickup and drop locations seamlessly.
- **Transparent Multi-Tier Fare Estimation:** Live pricing comparison across Bike, Auto, and Car with estimated time of arrival (ETA).
- **Synchronized Ride Requests:** Instant dispatch to available Captains via Cloud Firestore streams.
- **Real-Time Ride Tracking:** Live turn-by-turn map tracking with polyline updates as the Captain approaches.
- **4-Digit OTP Ride Verification:** Unique security PIN generated per ride; Captain must enter it before starting the trip.
- **In-App Live Chat:** Direct real-time messaging with your driver without exposing phone numbers.
- **Safety Center & SOS Alert:** Immediate one-tap emergency broadcast with real-time GPS location sent to emergency contacts.
- **Ride History & Rating:** Complete past ride summaries, receipts, and driver feedback rating system.

---

## 📱 Tech Stack
- **Framework:** Flutter 3.x (Dart 3.x)
- **State Management:** Provider
- **Mapping:** `google_maps_flutter`, Google Maps Directions API, Places API
- **Backend:** Firebase Authentication, Cloud Firestore, Firebase Cloud Storage

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Firebase & Google Maps
- Ensure `android/app/google-services.json` is present.
- Ensure your Google Maps API key is configured in `android/app/src/main/AndroidManifest.xml`.

### 3. Run the App
```bash
flutter run
```

---

## 🧪 Automated Tests & Quality Assurance
Run the automated test suite across unit, widget, and end-to-end flows:
```bash
flutter test
```

Verify zero analyzer warnings or errors:
```bash
flutter analyze
```

---

## 📑 Project Reports & Documentation
- [Pickup & Destination Address Display Fix Report](PICKUP_DESTINATION_ADDRESS_DISPLAY_FIX_REPORT.md) — Comprehensive technical root-cause investigation and multi-tier geocoding fix report.
- [Demo Captain, Complete Ride Lifecycle & Rewards Implementation Report](DEMO_CAPTAIN_COMPLETE_RIDE_REWARDS_REPORT.md) — Complete academic presentation and viva workflow documentation with simulated Demo Captain, 6-stage lifecycle, and `DEMO50` rewards voucher.
- [Real-Time Firebase Storage & Sync Debug Report](FIREBASE_STORAGE_AND_SYNC_DEBUG_REPORT.md) — Cross-app database synchronization and Cloud Firestore trace report.
