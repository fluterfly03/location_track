import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracking_session.dart';

class StorageService {
  static const String _activeSessionKey = 'active_location_session';
  static const String _historyKey = 'location_sessions_history';

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

  static Future<void> saveSessionToHistory(TrackingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    // Insert newest first
    history.insert(0, session);
    
    final jsonList = history.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_historyKey, jsonList);
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
}
