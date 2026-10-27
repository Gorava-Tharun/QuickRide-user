# QuickRide — Demo Captain, Complete Ride Lifecycle & Rewards Implementation Report

**Project Title:** QuickRide – Ride Booking Application  
**Report Type:** Feature Architecture & Implementation Report  
**Application:** QuickRide User App (`quickride_user`)  
**College:** Government Polytechnic College, Dharmavaram  
**Department:** Computer Science and Engineering (CSE)  
**Academic Year:** 2026–2027  

---

## 1. Executive Summary

To enable faculty, external examiners, and students to evaluate the complete QuickRide ride-booking flow during college presentations and viva voce examinations without relying on an external Captain device, an end-to-end **Demo Mode** workflow has been introduced.

This implementation provides:
1. **A Clearly Identified Demo Captain** with simulated vehicle, rating, and location data.
2. **Deterministic Lifecycle Progression** with manual control buttons for seamless demonstrations.
3. **Strict Adherence to QuickRide Fare Rules** (Bike/Auto 1–50 km, Car 5–150 km).
4. **Trip Summary, Ratings & Viva Reward Voucher** (`DEMO50` - 50% discount).
5. **Zero Mutation of Production Database**: Total isolation from Cloud Firestore collections (`rides`, `captains`, `users`).

---

## 2. Architecture & Data Safety Design

```
                     [ User App Home Screen ]
                                │
                        Demo Mode Switch
                                │
                 Is Demo Mode Enabled (Viva Mode)?
                                │
                ┌───────────────┴───────────────┐
                ▼                               ▼
             [ YES ]                         [ NO ]
                │                               │
        [ DemoService Flow ]           [ Production Flow ]
                │                               │
   • In-Memory Mock Requests        • Live Cloud Firestore
     ("DEMO_RIDE_<timestamp>")        ("rides", "captains")
   • Local State Progression        • Real Captain Matching
   • Zero Firestore Mutations       • Payment Gateway / Real GPS
```

### 2.1 Database Protection
- When Demo Mode is active, all ride requests are assigned a unique in-memory ID prefixed with `DEMO_RIDE_` and flag `isDemo: true`.
- Network calls to Firestore `createRideRequest()` or `updateRideStatus()` are bypassed.
- No dummy records or simulated drivers are ever inserted into production collections.
- When Demo Mode is disabled, normal live Firestore ride-matching operates with full fidelity.

---

## 3. Implemented Modules & Technical Details

### 3.1 Demo Captain Entity (`CaptainModel.demo`)
- **Name:** `Demo Captain (Rajesh Kumar)`
- **Vehicle Plate:** `AP 09 CB 1234`
- **Rating:** `4.8 ★`
- **Visual Identifier:** Amber `DEMO CAPTAIN` badge displayed in:
  - Match card (`FindingCaptainScreen`)
  - Live status tracking (`CaptainDetailsScreen`)
  - Trip completion summary (`RideCompletedScreen`)
  - Rating & review header (`RatingReviewScreen`)
  - Ride history items (`RideHistoryCard` & `RideDetailsScreen`)

### 3.2 Fare Calculation & Eligibility Verification
The existing single-slab pricing rules in `FareCalculator` are strictly enforced for demo rides:
- **Bike**: ₹8.00/km (1–5 km) down to ₹3.50/km (35–50 km). Minimum 1 km, maximum 50 km.
- **Auto**: ₹12.00/km (1–5 km) down to ₹5.25/km (35–50 km). Minimum 1 km, maximum 50 km.
- **Car**: Minimum distance 5 km, maximum 150 km.
- Trips outside these bounds are flagged as unavailable with descriptive reasons.

### 3.3 Complete Ride Lifecycle Progression

| Stage | Status | UI Description & Control |
|---|---|---|
| **1. Requested** | `searchingForCaptain` | Radar animation; displays `[ DEMO CAPTAIN LOCATED ]` with working **"Accept Ride (Demo Captain)"** button. |
| **2. Accepted** | `captainFound` | Displays Captain profile card and **"Simulate Reach Pickup (Arrived)"** button. |
| **3. Arriving** | `arriving` | Displays live status banner; captain navigates toward pickup point. |
| **4. Arrived** | `arrived` | Repositions captain marker at pickup coordinates; provides **"Start Ride (Demo)"** button. |
| **5. In Progress** | `rideStarted` | Updates status banner to `"Ride in Progress (Demo)"`; displays **"Complete Ride (Demo)"** button. |
| **6. Completed** | `rideCompleted` | Positions captain marker at destination; persists trip into `RideHistoryService` with `isDemo: true`; navigates to `RideCompletedScreen`. |

### 3.4 Viva Rewards & Discount Voucher
- On the `RideCompletedScreen`, a dedicated **"DEMO TRIP REWARD & VOUCHER"** card is rendered.
- Tapping **"Claim Demo Reward (DEMO50)"** triggers `DemoService().claimDemoReward()`.
- Generates a 50% discount voucher with promo code **`DEMO50`** and registers it in `OfferService`.
- Prominently displays an academic simulation disclaimer: *"Simulated voucher: No real payments or monetary transactions involved."*

### 3.5 Rating & Review Submission
- The `RatingReviewScreen` accepts 1 to 5 stars, quick-feedback chips, and text reviews.
- Submissions are validated and stored in `RideReviewService`.
- The ride is marked as rated in `RideHistoryService`.
- The Thank You view includes a direct option to claim the demo reward if not yet claimed.

---

## 4. Verification & Quality Assurance

### 4.1 Static Analysis
```
$ flutter analyze
Analyzing quickride_user...
No issues found! (ran in 6.5s)
```

### 4.2 Automated Test Suite (`test/demo_captain_complete_ride_test.dart`)
```
$ flutter test test/demo_captain_complete_ride_test.dart
00:01 +13: All tests passed!
```

Tested scenarios:
1. `Scenario 1: Demo Mode Activation & State Synchronization` — **PASSED**
2. `Scenario 2: Pickup and Destination Route Generation` — **PASSED**
3. `Scenario 3: Demo Captain Generation with Identification Labels` — **PASSED**
4. `Scenario 4: Strict Adherence to QuickRide Fare Rules & Eligibility` — **PASSED**
5. `Scenario 5: Demo Ride Request Creation with Local Identification` — **PASSED**
6. `Scenario 6: Demo Captain Reaches Pickup Transition` — **PASSED**
7. `Scenario 7: Demo Ride Started Transition` — **PASSED**
8. `Scenario 8: Complete Demo Ride Transition & Coordinate Arrival` — **PASSED**
9. `Scenario 9: Ride History Persistence Records Demo Status` — **PASSED**
10. `Scenario 10: Rating and Review Submission for Demo Ride` — **PASSED**
11. `Scenario 11: Demo Reward Claim without Real Payment Dependency` — **PASSED**
12. `Scenario 12: Production Database Safety & Zero Fake Captain Injection` — **PASSED**
13. `Widget Test: RideCompletedScreen shows Demo Captain badge & Claim Voucher` — **PASSED**

### 4.3 Web Release Compilation
```
$ flutter build web --release
Compiling lib\main.dart for the Web... 69.2s
√ Built build\web
```

---

## 5. College Viva / Presentation Demo Script

1. **Launch App**: Open QuickRide User App in browser or emulator.
2. **Turn On Demo Mode**: Toggle the **Demo Mode** switch in the home header.
3. **Route**: Enter Pickup (*Dharmavaram RTC Bus Stand*) and Destination (*Dharmavaram Railway Station*).
4. **Select Vehicle**: Choose **Bike** and inspect fare breakdown (Base + Distance + Time).
5. **Request Ride**: Tap **Book Bike** → **Accept Ride (Demo Captain)** on the search screen.
6. **Live Ride Actions**:
   - Tap **"Simulate Reach Pickup (Arrived)"**
   - Tap **"Start Ride (Demo)"**
   - Tap **"Complete Ride (Demo)"**
7. **Rewards & Review**:
   - Tap **"Claim Demo Reward (DEMO50)"** to view the 50% discount voucher modal.
   - Tap **"Rate Your Ride"**, select 5 stars, add feedback, and submit.
8. **History**: Open **My Rides** tab to view the persisted ride with its `[DEMO]` indicator.
