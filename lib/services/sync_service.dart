import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sync_record.dart';
import '../models/tracking_session.dart';
import 'storage_service.dart';
import 'network_service.dart';
import 'mock_server_service.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;

  final NetworkService _networkService = NetworkService();
  final MockServerService _serverService = MockServerService();

  List<SyncRecord> _queue = [];
  bool _isSyncing = false;
  String _syncStatusMessage = 'Idle';
  StreamSubscription<bool>? _networkSubscription;

  List<SyncRecord> get queue => List.unmodifiable(_queue);
  bool get isSyncing => _isSyncing;
  String get syncStatusMessage => _syncStatusMessage;

  int get pendingCount => _queue.where((r) => r.status == SyncStatus.pending).length;
  int get syncingCount => _queue.where((r) => r.status == SyncStatus.syncing).length;
  int get syncedCount => _queue.where((r) => r.status == SyncStatus.synced).length;
  int get failedCount => _queue.where((r) => r.status == SyncStatus.failed).length;

  SyncService._internal() {
    _init();
  }

  Future<void> _init() async {
    _queue = await StorageService.getSyncQueue();

    // Listen to network status changes to trigger auto-sync on reconnection
    _networkSubscription = _networkService.onConnectivityChanged.listen((isOnline) {
      if (isOnline && pendingCount + failedCount > 0) {
        debugPrint('SYNC SERVICE: Network connection restored! Triggering automatic synchronization...');
        syncPendingRecords();
      }
    });

    notifyListeners();
  }

  /// Adds a tracking session payload to the pending sync queue
  Future<SyncRecord> enqueueSession(TrackingSession session, {String recordType = 'session_checkout'}) async {
    final record = SyncRecord(
      id: 'sync_${session.id}_${DateTime.now().millisecondsSinceEpoch}',
      idempotencyKey: session.idempotencyKey,
      sessionId: session.id,
      recordType: recordType,
      payload: session.toJson(),
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    // Save record to local queue
    _queue.add(record);
    await StorageService.saveSyncQueue(_queue);

    // Update session status to pending
    session.syncStatus = SyncStatus.pending;
    await StorageService.updateSessionInHistory(session);

    notifyListeners();

    // Trigger auto-sync if currently online
    if (_networkService.isOnline) {
      unawaited(syncPendingRecords());
    }

    return record;
  }

  /// Process all pending and failed records in queue with retry mechanism
  Future<void> syncPendingRecords({bool forceRetryFailed = false}) async {
    if (_isSyncing) return;
    if (!_networkService.isOnline) {
      _syncStatusMessage = 'Cannot sync: Network connectivity unavailable (Offline)';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _syncStatusMessage = 'Synchronizing pending location records...';
    notifyListeners();

    try {
      final recordsToProcess = _queue.where((r) {
        if (r.status == SyncStatus.pending) return true;
        if (r.status == SyncStatus.failed && (forceRetryFailed || r.retryCount < 5)) return true;
        return false;
      }).toList();

      if (recordsToProcess.isEmpty) {
        _syncStatusMessage = 'All records are up to date';
        _isSyncing = false;
        notifyListeners();
        return;
      }

      for (var record in recordsToProcess) {
        if (!_networkService.isOnline) {
          debugPrint('SYNC SERVICE: Network lost mid-sync process.');
          break;
        }

        record.status = SyncStatus.syncing;
        record.lastAttemptTime = DateTime.now();
        await StorageService.saveSyncQueue(_queue);
        notifyListeners();

        // Also update parent session status if matching session exists in history
        await _updateHistorySessionStatus(record.sessionId, SyncStatus.syncing);

        try {
          // Attempt sync with server (passes idempotencyKey)
          final response = await _serverService.syncRecord(record);

          if (response.success) {
            record.status = SyncStatus.synced;
            record.serverRecordId = response.serverRecordId;
            record.errorMessage = null;

            await StorageService.saveSyncQueue(_queue);
            await _updateHistorySessionStatus(
              record.sessionId,
              SyncStatus.synced,
              syncedAt: DateTime.now(),
            );

            debugPrint('SYNC SERVICE: Sync succeeded for session ${record.sessionId}. Server ID: ${response.serverRecordId} (Duplicate: ${response.isDuplicate})');
          } else {
            _handleSyncFailure(record, response.message);
          }
        } catch (e) {
          _handleSyncFailure(record, e.toString());
        }

        notifyListeners();
      }
    } finally {
      _isSyncing = false;
      if (failedCount > 0) {
        _syncStatusMessage = 'Sync finished with $failedCount failed items';
      } else if (syncedCount > 0) {
        _syncStatusMessage = 'Synchronization complete! ($syncedCount items synced)';
      } else {
        _syncStatusMessage = 'Idle';
      }
      notifyListeners();
    }
  }

  void _handleSyncFailure(SyncRecord record, String errorMsg) {
    record.retryCount += 1;
    record.status = SyncStatus.failed;
    record.errorMessage = errorMsg;

    debugPrint('SYNC SERVICE: Sync failed for record ${record.id}. Retry attempt #${record.retryCount}. Error: $errorMsg');

    StorageService.saveSyncQueue(_queue);
    _updateHistorySessionStatus(
      record.sessionId,
      SyncStatus.failed,
      errorMsg: errorMsg,
    );
  }

  Future<void> _updateHistorySessionStatus(
    String sessionId,
    SyncStatus status, {
    DateTime? syncedAt,
    String? errorMsg,
  }) async {
    final history = await StorageService.getHistory();
    final index = history.indexWhere((s) => s.id == sessionId);
    if (index >= 0) {
      final session = history[index];
      session.syncStatus = status;
      if (syncedAt != null) session.lastSyncedAt = syncedAt;
      if (errorMsg != null) session.syncErrorMessage = errorMsg;
      await StorageService.saveSessionToHistory(session);
    }
  }

  /// Reset or retry a single record manually
  Future<void> retrySingleRecord(SyncRecord record) async {
    record.status = SyncStatus.pending;
    await StorageService.saveSyncQueue(_queue);
    notifyListeners();
    await syncPendingRecords(forceRetryFailed: true);
  }

  /// Clear synced history queue
  Future<void> clearCompletedSyncQueue() async {
    _queue.removeWhere((r) => r.status == SyncStatus.synced);
    await StorageService.saveSyncQueue(_queue);
    notifyListeners();
  }

  Future<void> clearAllSyncQueue() async {
    _queue.clear();
    _isSyncing = false;
    await StorageService.clearSyncQueue();
    notifyListeners();
  }

  void disposeService() {
    _networkSubscription?.cancel();
  }
}
