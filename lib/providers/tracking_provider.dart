import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tracking_point.dart';
import '../models/tracking_session.dart';
import '../models/sync_record.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/network_service.dart';
import '../services/sync_service.dart';
import '../services/mock_server_service.dart';

class TrackingProvider extends ChangeNotifier {
  TrackingSession? _activeSession;
  TrackingSession? _lastCompletedSession;
  List<TrackingSession> _history = [];
  TrackingPoint? _currentPoint;

  bool _isGpsEnabled = true;
  LocationPermission _permission = LocationPermission.denied;
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';

  StreamSubscription<Position>? _positionSubscription;
  Timer? _durationTimer;

  // Services
  final NetworkService _networkService = NetworkService();
  final SyncService _syncService = SyncService();
  final MockServerService _serverService = MockServerService();

  // Getters
  TrackingSession? get activeSession => _activeSession;
  TrackingSession? get lastCompletedSession => _lastCompletedSession;
  List<TrackingSession> get history => _history;
  TrackingPoint? get currentPoint => _currentPoint;
  bool get isGpsEnabled => _isGpsEnabled;
  LocationPermission get permission => _permission;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  bool get isTracking => _activeSession != null && _activeSession!.isTracking;

  // Sync & Network Getters
  NetworkService get networkService => _networkService;
  SyncService get syncService => _syncService;
  MockServerService get serverService => _serverService;

  bool get isOnline => _networkService.isOnline;
  bool get isSimulatingOffline => _networkService.isSimulatingOffline;
  List<SyncRecord> get syncQueue => _syncService.queue;
  bool get isSyncing => _syncService.isSyncing;
  String get syncStatusMessage => _syncService.syncStatusMessage;

  TrackingProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    _statusMessage = 'Checking location permissions...';
    notifyListeners();

    // Attach listeners to update UI on network or sync state changes
    _networkService.addListener(_onServiceStateChanged);
    _syncService.addListener(_onServiceStateChanged);

    await refreshPermissions();
    _history = await StorageService.getHistory();

    // Check if there was an ongoing session saved
    final restoredSession = await StorageService.getActiveSession();
    if (restoredSession != null && restoredSession.isTracking) {
      _activeSession = restoredSession;
      if (restoredSession.points.isNotEmpty) {
        _currentPoint = restoredSession.points.last;
      }
      _startPositionStream();
      _startDurationTimer();
    }

    // Try fetching current location for map centering
    if (_permission == LocationPermission.always ||
        _permission == LocationPermission.whileInUse) {
      final loc = await LocationService.getCurrentLocation();
      if (loc != null) {
        _currentPoint = loc;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _onServiceStateChanged() {
    _refreshHistory();
    notifyListeners();
  }

  Future<void> _refreshHistory() async {
    _history = await StorageService.getHistory();
    notifyListeners();
  }

  Future<void> refreshPermissions() async {
    _isGpsEnabled = await LocationService.isLocationServiceEnabled();
    _permission = await Geolocator.checkPermission();
    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    _isGpsEnabled = await LocationService.isLocationServiceEnabled();
    if (!_isGpsEnabled) {
      _statusMessage = 'GPS Location services are turned off.';
      notifyListeners();
      return false;
    }

    _permission = await LocationService.checkAndRequestPermission();
    notifyListeners();
    return _permission == LocationPermission.always ||
        _permission == LocationPermission.whileInUse;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await refreshPermissions();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
    await refreshPermissions();
  }

  /// Toggle Simulated Offline Mode for testing network loss and reconnection
  void toggleSimulatedOffline() {
    _networkService.toggleSimulatedOffline();
    notifyListeners();
  }

  /// Trigger manual synchronization of pending/failed records
  Future<void> triggerManualSync() async {
    await _syncService.syncPendingRecords(forceRetryFailed: true);
    await _refreshHistory();
  }

  /// START / CHECK IN
  Future<bool> checkIn() async {
    final granted = await requestPermissions();
    if (!granted) {
      return false;
    }

    _isLoading = true;
    _statusMessage = 'Recording starting location...';
    notifyListeners();

    // Capture precise initial location
    final startLoc = await LocationService.getCurrentLocation();
    if (startLoc == null) {
      _isLoading = false;
      _statusMessage = 'Failed to acquire initial location fix.';
      notifyListeners();
      return false;
    }

    final timestampStr = DateTime.now().millisecondsSinceEpoch.toString();
    final newSession = TrackingSession(
      id: timestampStr,
      idempotencyKey: 'idemp_session_$timestampStr',
      startTime: DateTime.now(),
      startLocation: startLoc,
      points: [startLoc],
      totalDistanceMeters: 0.0,
      isTracking: true,
      syncStatus: SyncStatus.pending,
    );

    _activeSession = newSession;
    _lastCompletedSession = null;
    _currentPoint = startLoc;

    await StorageService.saveActiveSession(newSession);

    _startPositionStream();
    _startDurationTimer();

    _isLoading = false;
    _statusMessage = 'Tracking active';
    notifyListeners();
    return true;
  }

  /// STOP / CHECK OUT
  Future<void> checkOut() async {
    if (_activeSession == null) return;

    _isLoading = true;
    _statusMessage = 'Recording checkout location...';
    notifyListeners();

    _stopPositionStream();
    _stopDurationTimer();

    // Try capturing exact checkout position
    final finalLoc = await LocationService.getCurrentLocation();
    TrackingPoint? checkoutPoint = finalLoc ?? _currentPoint;

    if (checkoutPoint != null && _activeSession!.points.isNotEmpty) {
      // Process distance between last point and checkout location
      final lastPoint = _activeSession!.points.last;
      double? lastDistance = LocationService.processNewLocationPoint(
        lastRecordedPoint: lastPoint,
        newPosition: Position(
          longitude: checkoutPoint.longitude,
          latitude: checkoutPoint.latitude,
          timestamp: checkoutPoint.timestamp,
          accuracy: checkoutPoint.accuracy,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: checkoutPoint.speed,
          speedAccuracy: 0,
        ),
      );

      if (lastDistance != null && lastDistance > 0) {
        _activeSession!.points.add(checkoutPoint);
        _activeSession!.totalDistanceMeters += lastDistance;
      }
    }

    _activeSession!.endLocation = checkoutPoint;
    _activeSession!.endTime = DateTime.now();
    _activeSession!.isTracking = false;
    _activeSession!.syncStatus = SyncStatus.pending;

    _lastCompletedSession = _activeSession;

    // 1. Save completed session to local history
    await StorageService.saveSessionToHistory(_activeSession!);
    await StorageService.clearActiveSession();

    // 2. Enqueue session into SyncService for synchronization (handles offline / online / retry / idempotency)
    await _syncService.enqueueSession(_activeSession!);

    _history = await StorageService.getHistory();
    _activeSession = null;
    _isLoading = false;
    _statusMessage = 'Checked out successfully';
    notifyListeners();
  }

  /// SPECIAL TEST TOOL: Simulate the exact user scenario:
  /// Mobile sends data -> Server creates record -> Mobile loses connection before receiving HTTP response -> Mobile reconnects & retries -> Server prevents duplicate record!
  Future<void> simulateResponseLossScenario() async {
    if (_history.isEmpty) {
      // Create a dummy completed session for testing if none exists
      final dummySession = TrackingSession(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        idempotencyKey: 'test_key_${DateTime.now().millisecondsSinceEpoch}',
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
        endTime: DateTime.now(),
        totalDistanceMeters: 1500.0,
        isTracking: false,
        syncStatus: SyncStatus.pending,
      );
      await StorageService.saveSessionToHistory(dummySession);
      _history = await StorageService.getHistory();
    }

    final targetSession = _history.first;

    // Enable server-side response drop simulation for this idempotency key
    _serverService.enableResponseDropSimulation(targetSession.idempotencyKey);

    // Enqueue session into sync service
    await _syncService.enqueueSession(targetSession);

    await _refreshHistory();
  }

  void _startPositionStream() {
    _stopPositionStream();
    _positionSubscription = LocationService.getPositionStream().listen(
      (Position position) {
        _handleNewPosition(position);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  void _stopPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _handleNewPosition(Position position) {
    if (_activeSession == null || !_activeSession!.isTracking) return;

    final candidatePoint = TrackingPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
      speed: position.speed,
    );

    final lastPoint =
        _activeSession!.points.isNotEmpty ? _activeSession!.points.last : null;

    double? validDistance = LocationService.processNewLocationPoint(
      lastRecordedPoint: lastPoint,
      newPosition: position,
    );

    _currentPoint = candidatePoint;

    if (validDistance != null) {
      _activeSession!.points.add(candidatePoint);
      _activeSession!.totalDistanceMeters += validDistance;
      _activeSession!.endLocation = candidatePoint;

      // Save updated active session locally
      StorageService.saveActiveSession(_activeSession!);
    }

    notifyListeners();
  }

  void _startDurationTimer() {
    _stopDurationTimer();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession != null && _activeSession!.isTracking) {
        notifyListeners();
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> clearHistory() async {
    await StorageService.clearHistory();
    await _syncService.clearAllSyncQueue();
    _history = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _networkService.removeListener(_onServiceStateChanged);
    _syncService.removeListener(_onServiceStateChanged);
    _stopPositionStream();
    _stopDurationTimer();
    super.dispose();
  }
}
