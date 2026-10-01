import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task1/models/tracking_session.dart';
import 'package:task1/models/sync_record.dart';
import 'package:task1/services/storage_service.dart';
import 'package:task1/services/network_service.dart';
import 'package:task1/services/mock_server_service.dart';
import 'package:task1/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MockServerService().clearServerDatabase();
    await SyncService().clearAllSyncQueue();
    await StorageService.clearSyncQueue();
    await StorageService.clearHistory();
    await StorageService.clearActiveSession();
    NetworkService().setSimulatedOffline(false);
  });

  group('Offline Storage & SyncQueue Persistence Tests', () {
    test('Saves and restores SyncRecord queue correctly', () async {
      final record1 = SyncRecord(
        id: 'sync_1',
        idempotencyKey: 'idemp_key_100',
        sessionId: 'session_100',
        recordType: 'session_checkout',
        payload: {'distance': 2500.0},
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
      );

      await StorageService.saveSyncRecord(record1);

      final queue = await StorageService.getSyncQueue();
      expect(queue.length, 1);
      expect(queue.first.id, 'sync_1');
      expect(queue.first.idempotencyKey, 'idemp_key_100');
      expect(queue.first.status, SyncStatus.pending);
    });

    test('TrackingSession serialization preserves idempotencyKey and syncStatus', () {
      final session = TrackingSession(
        id: 'session_abc',
        idempotencyKey: 'idemp_custom_abc',
        startTime: DateTime.now(),
        totalDistanceMeters: 5000.0,
        syncStatus: SyncStatus.pending,
      );

      final json = session.toJson();
      final restored = TrackingSession.fromJson(json);

      expect(restored.id, 'session_abc');
      expect(restored.idempotencyKey, 'idemp_custom_abc');
      expect(restored.syncStatus, SyncStatus.pending);
    });
  });

  group('Mock Server & Idempotency Duplicate Prevention Tests', () {
    test('Normal sync creates record on server and returns serverRecordId', () async {
      final server = MockServerService();
      final record = SyncRecord(
        id: 'sync_test_1',
        idempotencyKey: 'idemp_unique_999',
        sessionId: 'session_999',
        recordType: 'session_checkout',
        payload: {'points': 10},
        createdAt: DateTime.now(),
      );

      final response = await server.syncRecord(record);

      expect(response.success, true);
      expect(response.statusCode, 201);
      expect(response.isDuplicate, false);
      expect(response.serverRecordId, isNotNull);
      expect(server.serverRecordCount, 1);
    });

    test('Identical idempotencyKey prevents duplicate record creation on server', () async {
      final server = MockServerService();
      final record1 = SyncRecord(
        id: 'sync_test_a',
        idempotencyKey: 'idemp_same_key_123',
        sessionId: 'session_123',
        recordType: 'session_checkout',
        payload: {'points': 5},
        createdAt: DateTime.now(),
      );

      // First sync attempt
      final response1 = await server.syncRecord(record1);
      expect(response1.success, true);
      expect(response1.statusCode, 201);
      expect(server.serverRecordCount, 1);

      // Second sync attempt with SAME idempotencyKey
      final record2 = SyncRecord(
        id: 'sync_test_b',
        idempotencyKey: 'idemp_same_key_123',
        sessionId: 'session_123',
        recordType: 'session_checkout',
        payload: {'points': 5},
        createdAt: DateTime.now(),
      );

      final response2 = await server.syncRecord(record2);

      expect(response2.success, true);
      expect(response2.statusCode, 200);
      expect(response2.isDuplicate, true);
      expect(response2.serverRecordId, response1.serverRecordId);
      // Server record count remains 1 (No duplicate created!)
      expect(server.serverRecordCount, 1);
    });

    test('IMPORTANT CASE: Server creates record, response lost mid-flight, mobile retries -> Duplicate prevented!', () async {
      final server = MockServerService();
      final syncService = SyncService();
      final network = NetworkService();
      network.setSimulatedOffline(false);

      final idempotencyKey = 'idemp_response_drop_test_555';
      final session = TrackingSession(
        id: 'session_555',
        idempotencyKey: idempotencyKey,
        startTime: DateTime.now(),
        totalDistanceMeters: 4200.0,
        syncStatus: SyncStatus.pending,
      );

      // 1. Mobile sends data while offline, but server response will drop
      server.enableResponseDropSimulation(idempotencyKey);

      network.setSimulatedOffline(true);
      await syncService.enqueueSession(session, recordType: 'session_checkout');

      // 2. Mobile reconnects to internet and attempts synchronization
      network.setSimulatedOffline(false);
      await syncService.syncPendingRecords(forceRetryFailed: true);

      // Check state:
      // - Server SHOULD HAVE recorded the entry in server database (count = 1)
      expect(server.serverRecordCount, 1);

      // - Mobile received network drop error, so local queue status is FAILED with error message and retryCount = 1
      final queue1 = syncService.queue;
      expect(queue1.length, 1);
      expect(queue1.first.status, SyncStatus.failed);
      expect(queue1.first.retryCount, 1);

      // 3. Mobile retries sync again
      await syncService.syncPendingRecords(forceRetryFailed: true);

      // Verification:
      // - Mobile queue item is now SYNCED!
      final queue2 = syncService.queue;
      expect(queue2.first.status, SyncStatus.synced);
      expect(queue2.first.serverRecordId, isNotNull);

      // - Server DB still has EXACTLY 1 record! (NO DUPLICATE CREATED!)
      expect(server.serverRecordCount, 1);
    });
  });

  group('Offline Operations & Auto-Sync on Network Reconnect', () {
    test('Saves trip offline when simulated offline, then syncs automatically when reconnected', () async {
      final syncService = SyncService();
      final network = NetworkService();

      // Turn OFF internet (Simulate Offline mode)
      network.setSimulatedOffline(true);
      expect(network.isOnline, false);

      final session = TrackingSession(
        id: 'session_offline_777',
        idempotencyKey: 'idemp_offline_777',
        startTime: DateTime.now(),
        totalDistanceMeters: 8100.0,
        syncStatus: SyncStatus.pending,
      );

      // Employee completes trip while offline
      await syncService.enqueueSession(session);

      // Record is in queue as pending
      expect(syncService.pendingCount, 1);
      expect(syncService.syncedCount, 0);

      // Connection is restored! (Network transitions Offline -> Online)
      network.setSimulatedOffline(false);
      expect(network.isOnline, true);

      // Wait for auto sync on network reconnect
      await Future.delayed(const Duration(milliseconds: 600));

      // Record is now synced automatically
      expect(syncService.pendingCount, 0);
      expect(syncService.syncedCount, 1);
    });
  });
}
