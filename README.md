# Flutter Location Tracker & API Data Handling Application

An enterprise-grade Flutter application implementing background location tracking, offline data synchronization, idempotency key duplicate prevention, and robust missing API location/distance data handling.

---

## Task 1 – Offline Operation & Synchronisation

- **Offline Location Recording**: Captures GPS waypoints during journeys when internet connectivity is lost and buffers them in local storage.
- **Local Persistence & Queue**: Persists tracking sessions and pending sync queues using `SharedPreferences`.
- **Network Reconnection & Auto-Sync**: Monitors connectivity transitions using `connectivity_plus` and automatically synchronizes queued records upon network restoration.
- **Idempotency Engine & Duplicate Prevention**: Attaches a unique client-side `idempotencyKey` to every trip payload. If a mobile device sends data, the server creates the record, and the response drops due to lost connectivity, the subsequent retry attempt is recognized by the server using the idempotency key—preventing duplicate record creation.
- **Retry Mechanism**: Includes retry count tracking, error logging, and manual/automatic retry controls.

---

## Task 2 – Missing Location/API Data Handling

### Overview
This feature implements robust handling for missing, null, or invalid location and distance data from an API feed in accordance with enterprise software engineering standards.

### Key Architectural Notes
* **No Hardcoded Production Endpoint**: As no production API endpoint was provided by the interviewer, a clean layered abstraction (`UI` $\rightarrow$ `ViewModel/Provider` $\rightarrow$ `Repository` $\rightarrow$ `ApiService` $\rightarrow$ `MockApiService`) was implemented.
* **Production-Ready Abstraction**: The `DistanceApiService` abstract contract allows `MockDistanceApiService` to be seamlessly swapped out with a real HTTP endpoint in production without altering business logic or UI code.
* **Strict Null Safety & Zero Fallback Rule**: Null, missing, or negative/invalid API distance values are **NEVER** replaced with arbitrary hardcoded fallback values (e.g. `final distance = response.distance ?? 0.88;` is strictly forbidden). If data is missing or invalid, it is explicitly presented as unavailable or in an error state.
* **Comprehensive Error Handling**: Handles valid values (`18.4 km`), null values (`{ "distance": null }`), missing fields (`{}`), negative/invalid values (`{ "distance": -5.0 }`), HTTP 500 server errors, network connectivity failures (`SocketException`), and request timeouts (`TimeoutException`).
* **Retry Behavior**: Includes an interactive **Retry** option. Tapping retry sets loading state, calls the repository layer again, renders the valid distance if retrieved, or maintains the error/unavailable UI state upon persistent failure.
* **Enterprise Structured Logging**: Includes a `LoggerService` at the repository/service layer recording actions, error types, exceptions, and timestamps without logging sensitive user location information unnecessarily.

---

## Architecture & Layers

```
UI Widgets (ApiDistanceCard, OfflineSyncCard)
       │
       ▼
Controllers / ViewModels (DistanceProvider, TrackingProvider)
       │
       ▼
Repositories (DistanceRepository, SyncService)
       │
       ▼
API Services (DistanceApiService -> MockDistanceApiService, MockServerService)
```

---

## Running Tests

Run the complete unit & integration test suite (28 test cases):

```bash
flutter test
```
