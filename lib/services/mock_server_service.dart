import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sync_record.dart';

class ServerSyncResponse {
  final bool success;
  final int statusCode;
  final String message;
  final String? serverRecordId;
  final bool isDuplicate;

  ServerSyncResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.serverRecordId,
    this.isDuplicate = false,
  });
}

class MockServerService {
  static final MockServerService _instance = MockServerService._internal();
  factory MockServerService() => _instance;

  MockServerService._internal();

  /// Server database storing records by idempotencyKey
  final Map<String, Map<String, dynamic>> _serverDatabase = {};

  /// Flag to simulate response loss (server creates record, but network drops before response reaches client)
  final Set<String> _idempotencyKeysToDropResponse = {};
  bool _globalDropResponseOnce = false;

  /// Server-side recorded entries count
  int get serverRecordCount => _serverDatabase.length;
  List<Map<String, dynamic>> get serverRecords => _serverDatabase.values.toList();

  /// Enables network response drop simulation for a specific idempotency key or next call
  void enableResponseDropSimulation(String idempotencyKey) {
    _idempotencyKeysToDropResponse.add(idempotencyKey);
  }

  void enableGlobalNextResponseDrop() {
    _globalDropResponseOnce = true;
  }

  void clearServerDatabase() {
    _serverDatabase.clear();
    _idempotencyKeysToDropResponse.clear();
    _globalDropResponseOnce = false;
  }

  /// Simulates HTTP POST /api/v1/sync-location
  Future<ServerSyncResponse> syncRecord(SyncRecord record) async {
    // Artificial latency (300ms)
    await Future.delayed(const Duration(milliseconds: 300));

    final key = record.idempotencyKey;

    // Check if network response drop simulation is enabled for this key/request
    final shouldDropResponse = _idempotencyKeysToDropResponse.contains(key) || _globalDropResponseOnce;
    if (shouldDropResponse) {
      _idempotencyKeysToDropResponse.remove(key);
      _globalDropResponseOnce = false;

      // 1. Server STILL creates the record in its database!
      if (!_serverDatabase.containsKey(key)) {
        final serverId = 'srv_${DateTime.now().millisecondsSinceEpoch}_${record.id}';
        _serverDatabase[key] = {
          'serverRecordId': serverId,
          'idempotencyKey': key,
          'sessionId': record.sessionId,
          'payload': record.payload,
          'receivedAt': DateTime.now().toIso8601String(),
          'attemptCount': 1,
        };
        debugPrint('SERVER MOCK: Successfully created record $serverId for key $key (Response will be dropped!)');
      }

      // 2. Mobile drops connection right before receiving HTTP response
      throw TimeoutException('Network connection dropped before receiving server HTTP 200 response.');
    }

    // DUPLICATE CHECK (Idempotency Engine)
    if (_serverDatabase.containsKey(key)) {
      final existing = _serverDatabase[key]!;
      existing['attemptCount'] = (existing['attemptCount'] as int? ?? 1) + 1;
      
      debugPrint('SERVER MOCK: Duplicate sync request detected for key: $key. Preventing duplicate creation!');
      
      return ServerSyncResponse(
        success: true,
        statusCode: 200,
        message: 'Record already exists on server (Duplicate prevented via idempotency key)',
        serverRecordId: existing['serverRecordId'] as String,
        isDuplicate: true,
      );
    }

    // NEW RECORD CREATION
    final serverId = 'srv_${DateTime.now().millisecondsSinceEpoch}_${record.id}';
    _serverDatabase[key] = {
      'serverRecordId': serverId,
      'idempotencyKey': key,
      'sessionId': record.sessionId,
      'payload': record.payload,
      'receivedAt': DateTime.now().toIso8601String(),
      'attemptCount': 1,
    };

    debugPrint('SERVER MOCK: Successfully created new record $serverId on server for key $key');

    return ServerSyncResponse(
      success: true,
      statusCode: 201,
      message: 'Record synced successfully',
      serverRecordId: serverId,
      isDuplicate: false,
    );
  }
}
