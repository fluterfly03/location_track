# Flutter Location & Visit Tracking Assessment

## Overview

This Flutter application is an enterprise-grade field tracking and location synchronization assessment project. It implements continuous GPS movement tracking, accurate geodesic distance calculations, offline-first queue persistence with auto-synchronization, server-side idempotency for duplicate prevention, robust zero-fallback API error handling, and a Gemini LLM-powered visit summary with local smart NLP fallback.

---

## Assessment Tasks

* **Task 1 – Location Tracking & Distance**: Captures precise GPS coordinates on check-in/check-out, tracks continuous movement using `geolocator`, applies stationary/accuracy filtering, calculates cumulative geodesic distance on the WGS-84 ellipsoid, and displays distance strictly in kilometres.
* **Task 2 – Missing Location/API Data Handling**: Implements strict validation on external distance payloads. Explicitly enforces the **Zero Fallback Rule**—null, missing, or negative values are presented as unavailable/error states and are **never** replaced with arbitrary hard-coded numbers (e.g. `0.88 km`).
* **Task 3 – Offline Synchronization**: Persists trip records locally in `SharedPreferences` while offline. Automatically triggers queue sync upon network restoration via `connectivity_plus`. Utilizes client-generated unique `idempotencyKey` values to prevent duplicate server record creation when network responses drop mid-flight.
* **Task 4 – AI Visit Summary**: Integrates Google Gemini 1.5 Flash (`google_generative_ai`) to answer natural language visit queries based strictly on factual application metrics. Provides a local smart NLP fallback engine when no API key is supplied.
* **Task 5 – Code Quality & Architecture**: Built using Clean Layered Architecture (`UI` $\rightarrow$ `Provider` $\rightarrow$ `Repository` $\rightarrow$ `Service` $\rightarrow$ `Model`) with strict null-safety, modular components, comprehensive logging (`LoggerService`), and 28 automated unit/integration tests.

---

### Architecture Overview
The application follows Clean Layered Architecture with Provider state management:

```
┌─────────────────────────────────────────────────────────┐
│                    UI Presentation                      │
│       HomeScreen, ApiDistanceCard, OfflineSyncCard      │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                 Controllers / ViewModels                │
│            TrackingProvider, DistanceProvider           │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                  Repositories / Data                    │
│             DistanceRepository, SyncService            │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                 Services / Infrastructure               │
│ LocationService, DistanceApiService, NetworkService,    │
│ StorageService, MockServerService, AiSummaryService     │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

```text
lib/
├── main.dart                      # Application entry point, MultiProvider setup & Material theme
├── models/                        # Immutable data transfer objects
│   ├── distance_response.dart     # Safe API distance model enforcing zero-fallback rule
│   ├── sync_record.dart           # Offline sync queue record model with idempotency key
│   ├── tracking_point.dart        # GPS coordinate waypoint model with accuracy & speed
│   └── tracking_session.dart      # Trip session model with duration & total distance
├── providers/                     # Reactive state management (Provider pattern)
│   ├── distance_provider.dart     # Manages API distance state, scenarios, and retries
│   └── tracking_provider.dart     # Manages live GPS tracking, permissions, and sync triggers
├── services/                      # Business logic, hardware channels & persistence
│   ├── ai_summary_service.dart    # Gemini 1.5 Flash LLM integration & local NLP engine fallback
│   ├── distance_api_service.dart  # Abstract API contract & MockDistanceApiService
│   ├── distance_repository.dart   # Repository mapping network exceptions to typed errors
│   ├── geocoding_service.dart     # Reverse geocoding (Native geocoding & Nominatim fallback)
│   ├── location_service.dart      # Geolocator stream setup, filtering & geodesic math
│   ├── logger_service.dart        # Enterprise structured logger
│   ├── mock_server_service.dart   # Server database mock enforcing idempotency deduplication
│   ├── network_service.dart       # Connectivity listener & simulated offline toggle
│   ├── storage_service.dart       # Local persistence via SharedPreferences
│   └── sync_service.dart          # Sync queue execution & reconnection triggers
└── ui/                            # Presentation widgets & screens
    ├── screens/
    │   └── home_screen.dart       # Main dashboard screen
    └── widgets/                   # Modular reusable UI cards
        ├── ai_summary_card.dart    # AI summary & Q&A interface
        ├── api_distance_card.dart  # Task 2 API distance card with scenario dropdown
        ├── history_sheet.dart     # Trip history bottom sheet
        ├── live_metrics_card.dart  # Live distance km, speed, and timer display
        ├── location_details_card.dart # Live lat/lng coordinates and check-in/out times
        ├── offline_sync_card.dart  # Sync queue status & idempotency test controls
        ├── permission_banner.dart # Reactive permission & GPS alert banner
        ├── route_map_widget.dart  # Interactive polyline route map (flutter_map)
        └── sync_status_badge.dart # Colored sync status pill widget
```

---

## Technologies & Packages

| Package / Tool | Version | Purpose |
| :--- | :--- | :--- |
| **Flutter SDK** | `^3.12.2` | Core cross-platform application framework |
| **Dart** | `3.12.2+` | Strongly-typed programming language |
| **geolocator** | `^14.1.1` | GPS location streaming & geodesic distance calculation |
| **flutter_map** | `^8.3.2` | OpenStreetMap route polyline & waypoint visualization |
| **latlong2** | `^0.10.1` | Geographic coordinate math objects for mapping |
| **shared_preferences** | `^2.5.5` | Local persistent Key-Value storage for sync queue & history |
| **provider** | `^6.1.5+1` | Reactive application state management |
| **connectivity_plus** | `^6.1.3` | Real-time hardware network connectivity status listener |
| **google_generative_ai** | `^0.4.7` | Google Gemini 1.5 Flash LLM integration for visit summaries |
| **geocoding** | `^5.0.0` | Native reverse geocoding from coordinates to street addresses |
| **http** | `^1.6.0` | HTTP client for Nominatim reverse geocoding API fallback |
| **intl** | `^0.20.3` | Date formatting and time representation |

---

## Setup & Installation

### Prerequisites
* Flutter SDK `3.22.x` or higher
* Dart SDK `3.4.x` or higher
* Android Studio (with Android SDK 34+) / Xcode (15+)

### Installation
1. Clone the repository and navigate to root directory:
   ```bash
   git clone <REPOSITORY_URL>
   cd task1
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Run Application
Launch on connected Android emulator, iOS simulator, or physical device:
```bash
flutter run
```

### Execute Test Suite
Run the 28 unit and integration tests:
```bash
flutter test
```

### Build APK
Generate release Android APK:
```bash
flutter build apk --release
```

---

## Location Permissions

### Android Configuration (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
```
* **Why required**: `ACCESS_FINE_LOCATION` guarantees precise GPS coordinates for distance metrics. `FOREGROUND_SERVICE_LOCATION` prevents OS process suspension during active trip tracking.


---





### Representative AI Prompt Format
```text
You are a helpful AI travel assistant analyzing the user's location tracking data for today.

Here is the visit data collected by the application today:
- Check-in Time: 9:45 AM
- Completion Time: 5:20 PM
- Total Distance Travelled: 18.4 km
- Number of Locations Visited: 3
- First Location (Start): MG Road, Bengaluru
- Last Location (End): Indiranagar, Bengaluru
- Total Duration: 7 hrs 35 mins

Generate a concise, clear, 2-3 sentence AI summary of today's activity matching this example tone:
"Today the user checked in at 9:45 AM, travelled approximately 18.4 km, visited three locations, and completed the journey at 5:20 PM."
```

---

## Error Handling

* **Location Permission Denied**: Displayed reactively via `PermissionBanner` with button to re-trigger permission prompt.
* **Location Permission Permanently Denied**: `PermissionBanner` detects `deniedForever` and displays button opening System App Settings via `Geolocator.openAppSettings()`.
* **GPS Services Disabled**: Detected via `isLocationServiceEnabled()`, banner displays direct link to System Location Settings.
* **API Null / Missing Distance**: Handled by `DistanceResponse.fromJson()`, UI renders Orange Unavailable card with Retry button. Zero fallback rule enforced.
* **API Server Error (500)**: Caught by `DistanceRepository`, UI renders Red Error card with Retry button.
* **API Timeout**: Handled via `TimeoutException`, mapped to `TimeoutError` user state with Retry option.
* **Network Unavailable**: Handled via `SocketException` / `connectivity_plus`, queued locally without crashing UI.
* **AI API Failure**: Gemini API errors caught gracefully and redirected to Local Smart NLP fallback engine.

---

## Test Cases

The application includes 28 automated tests passing clean under `flutter test`:

| # | Test Case Description | Expected Result | Implementation Status |
| :- | :--- | :--- | :--- |
| 1 | Check-in trip initialization | Captures start location & timestamp | **Covered by automated test & manual** |
| 2 | Location stream waypoint updates | Waypoints appended to session points | **Covered by automated test & manual** |
| 3 | Geodesic distance calculation | Meters correctly converted to km | **Covered by automated test** |
| 4 | Check-out trip completion | End location & timestamp saved | **Covered by automated test & manual** |
| 5 | Stationary/Duplicate filtering | Points $< 3.0$m discarded as noise | **Covered by automated test** |
| 6 | Poor GPS accuracy filtering | Points with accuracy $> 35$m discarded | **Covered by automated test** |
| 7 | Speed teleportation jump filtering | Speeds $> 42$ m/s discarded | **Covered by automated test** |
| 8 | Valid distance API parsing (`18.4`) | `isValid = true`, distance returned | **Covered by automated test** |
| 9 | Null distance API parsing (`null`) | `isValid = false`, no `0.88` fallback | **Covered by automated test** |
| 10 | Missing distance field (`{}`) | `isValid = false`, no `0.88` fallback | **Covered by automated test** |
| 11 | Negative distance API parsing (`-5`) | `isValid = false`, rejected | **Covered by automated test** |
| 12 | HTTP 500 server error handling | Throws `DistanceRepositoryException` | **Covered by automated test** |
| 13 | Request timeout handling | Throws `TimeoutError` exception | **Covered by automated test** |
| 14 | Network socket error handling | Throws `NetworkError` exception | **Covered by automated test** |
| 15 | Retry success workflow | Failed fetch recovers on retry | **Covered by automated test** |
| 16 | Offline queue persistence | Records saved & restored in storage | **Covered by automated test** |
| 17 | Auto-sync on network reconnect | Queue syncs automatically | **Covered by automated test** |
| 18 | Idempotency deduplication | Duplicate `idempotencyKey` prevented | **Covered by automated test** |
| 19 | Server response loss mid-flight | Retry succeeds without duplicate | **Covered by automated test** |
| 20 | AI summary generation | Structured daily summary returned | **Covered by automated test** |
| 21 | AI Q&A start time query | Returns accurate check-in time | **Covered by automated test** |
| 22 | AI Q&A distance query | Returns factual km distance | **Covered by automated test** |
| 23 | App restart state restoration | Restores pending queue & active trip | **Covered by automated test** |







---

## Screen Recording Checklist

The submission screen recording demonstrates:
1. [x] Application launch & UI initialization
2. [x] Location permission banner & request flow
3. [x] Start / Check-in button tap & starting location capture
4. [x] Live GPS movement tracking & distance accumulation
5. [x] Stop / Check-out button tap & trip summary dialog
6. [x] Task 2 API distance card scenario switching (Valid, Null, Missing, Negative, 500 Error, Timeout, Network Error) & Retry
7. [x] Task 3 Network offline toggle switch & offline trip recording
8. [x] Network reconnection & automatic queue synchronization
9. [x] "Test Edge Case: Loss of Server Response (Idempotency)" button & duplicate prevention verification
10. [x] Task 4 AI Visit Assistant summary generation, Q&A interactive buttons, and Gemini API key dialog
