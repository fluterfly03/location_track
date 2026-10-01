import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracking_session.dart';
import '../models/sync_record.dart';

class StorageService {
  static const String _activeSessionKey = 'active_location_session';
  static const String _historyKey = 'location_sessions_history';
  static const String _syncQueueKey = 'location_sync_queue';

  // ACTIVE SESSION
  static Future<void> saveActiveSession(TrackingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionKey, jsonEncode(session.toJson()));
  }

  static Future<TrackingSession?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_activeSessionKey);
    if (data == null || data.isEmpty) return null;
    try {
      return TrackingSession.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey);
  }

  // HISTORY SESSIONS
  static Future<void> saveSessionToHistory(TrackingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    // Check if exists to update or insert
    final index = history.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      history[index] = session;
    } else {
      history.insert(0, session);
    }
    
    final jsonList = history.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  static Future<void> updateSessionInHistory(TrackingSession session) async {
    await saveSessionToHistory(session);
  }

  static Future<List<TrackingSession>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey) ?? [];
    List<TrackingSession> list = [];
    for (var str in jsonList) {
      try {
        list.add(TrackingSession.fromJson(jsonDecode(str) as Map<String, dynamic>));
      } catch (_) {}
    }
    return list;
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // SYNC QUEUE PERSISTENCE
  static Future<void> saveSyncQueue(List<SyncRecord> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = queue.map((rec) => jsonEncode(rec.toJson())).toList();
    await prefs.setStringList(_syncQueueKey, jsonList);
  }

  static Future<List<SyncRecord>> getSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_syncQueueKey) ?? [];
    List<SyncRecord> queue = [];
    for (var str in jsonList) {
      try {
        queue.add(SyncRecord.fromJson(jsonDecode(str) as Map<String, dynamic>));
      } catch (_) {}
    }
    return queue;
  }

  static Future<void> saveSyncRecord(SyncRecord record) async {
    final queue = await getSyncQueue();
    final index = queue.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      queue[index] = record;
    } else {
      queue.add(record);
    }
    await saveSyncQueue(queue);
  }

  static Future<void> clearSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncQueueKey);
  }
}
