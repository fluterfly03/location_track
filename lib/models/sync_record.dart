enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

extension SyncStatusExtension on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.pending:
        return 'Pending Sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Sync Failed';
    }
  }
}

class SyncRecord {
  final String id;
  final String idempotencyKey;
  final String sessionId;
  final String recordType; // 'session_start', 'location_update', 'session_checkout'
  final Map<String, dynamic> payload;
  SyncStatus status;
  int retryCount;
  final DateTime createdAt;
  DateTime? lastAttemptTime;
  String? errorMessage;
  String? serverRecordId;

  SyncRecord({
    required this.id,
    required this.idempotencyKey,
    required this.sessionId,
    required this.recordType,
    required this.payload,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    required this.createdAt,
    this.lastAttemptTime,
    this.errorMessage,
    this.serverRecordId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'idempotencyKey': idempotencyKey,
        'sessionId': sessionId,
        'recordType': recordType,
        'payload': payload,
        'status': status.name,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
        'lastAttemptTime': lastAttemptTime?.toIso8601String(),
        'errorMessage': errorMessage,
        'serverRecordId': serverRecordId,
      };

  factory SyncRecord.fromJson(Map<String, dynamic> json) => SyncRecord(
        id: json['id'] as String,
        idempotencyKey: json['idempotencyKey'] as String,
        sessionId: json['sessionId'] as String,
        recordType: json['recordType'] as String? ?? 'session_checkout',
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        status: SyncStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncStatus.pending,
        ),
        retryCount: json['retryCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastAttemptTime: json['lastAttemptTime'] != null
            ? DateTime.parse(json['lastAttemptTime'] as String)
            : null,
        errorMessage: json['errorMessage'] as String?,
        serverRecordId: json['serverRecordId'] as String?,
      );
}
