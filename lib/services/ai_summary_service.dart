import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../models/tracking_session.dart';
import 'geocoding_service.dart';

class AiSummaryService {
  /// Generate a natural language visit summary of today's location tracking activity.
  static Future<String> generateDailySummary(
    List<TrackingSession> allSessions, {
    String? apiKey,
  }) async {
    final todaySessions = _getTodaySessions(allSessions);
    if (todaySessions.isEmpty) {
      return 'No tracking activity recorded for today yet. Start a session to generate an AI summary.';
    }

    final summaryData = await _prepareContextData(todaySessions);

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );

        final prompt = '''
You are a helpful AI travel assistant analyzing the user's location tracking data for today.

Here is the visit data collected by the application today:
- Check-in Time: ${summaryData.startTimeStr}
- Completion Time: ${summaryData.endTimeStr}
- Total Distance Travelled: ${summaryData.totalDistanceKm.toStringAsFixed(1)} km
- Number of Locations Visited: ${summaryData.locationCount}
- First Location (Start): ${summaryData.firstAddress}
- Last Location (End): ${summaryData.lastAddress}
- Total Duration: ${summaryData.formattedDuration}

Generate a concise, clear, 2-3 sentence AI summary of today's activity matching this example tone:
"Today the user checked in at 9:45 AM, travelled approximately 18.4 km, visited three locations, and completed the journey at 5:20 PM."
''';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!.trim();
        }
      } catch (e) {
        debugPrint('Gemini API call error: $e. Falling back to local AI summary.');
      }
    }

    // Default Smart Natural Language Output (Proof of Concept)
    return 'Today the user checked in at ${summaryData.startTimeStr}, travelled approximately ${summaryData.totalDistanceKm.toStringAsFixed(1)} km across ${summaryData.locationCount} location(s) from ${summaryData.firstAddress} to ${summaryData.lastAddress}, and completed the journey at ${summaryData.endTimeStr}.';
  }

  /// Answer specific user questions using AI reasoning over location history.
  static Future<String> answerQuestion(
    String question,
    List<TrackingSession> allSessions, {
    String? apiKey,
  }) async {
    final todaySessions = _getTodaySessions(allSessions);
    if (todaySessions.isEmpty) {
      return 'No travel data recorded today. Please check in and track a trip first.';
    }

    final summaryData = await _prepareContextData(todaySessions);
    final lowerQ = question.toLowerCase().trim();

    // If Gemini API Key is provided, use LLM for response
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );

        final contextPrompt = '''
You are an AI assistant answering questions about the user's travel and visit data today.

Context Data:
- Check-in Time: ${summaryData.startTimeStr}
- Completion / End Time: ${summaryData.endTimeStr}
- Total Distance Travelled: ${summaryData.totalDistanceKm.toStringAsFixed(2)} km
- Number of Locations Visited: ${summaryData.locationCount}
- First Location: ${summaryData.firstAddress} (Lat: ${summaryData.firstLat.toStringAsFixed(4)}, Lng: ${summaryData.firstLng.toStringAsFixed(4)})
- Last Location: ${summaryData.lastAddress} (Lat: ${summaryData.lastLat.toStringAsFixed(4)}, Lng: ${summaryData.lastLng.toStringAsFixed(4)})
- Total Travel Duration: ${summaryData.formattedDuration}
- Number of Waypoints Recorded: ${summaryData.totalPoints}

User Question: "$question"

Provide a direct, friendly, and precise response based strictly on the context data above.
''';

        final response = await model.generateContent([Content.text(contextPrompt)]);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!.trim();
        }
      } catch (e) {
        debugPrint('Gemini question processing error: $e');
      }
    }

    // Smart Local Rule-based NLP Query Engine (Fallback / Zero API key)
    if (lowerQ.contains('what time did i start') ||
        lowerQ.contains('when did i start') ||
        lowerQ.contains('start time') ||
        lowerQ.contains('check in time') ||
        lowerQ.contains('check-in time') ||
        lowerQ.contains('start my journey') ||
        lowerQ.contains('start journey') ||
        lowerQ.contains('started')) {
      return 'You started your journey (checked in) at ${summaryData.startTimeStr} at ${summaryData.firstAddress}.';
    } else if (lowerQ.contains('what time did i end') ||
        lowerQ.contains('what time did i finish') ||
        lowerQ.contains('when did i end') ||
        lowerQ.contains('when did i finish') ||
        lowerQ.contains('end time') ||
        lowerQ.contains('checkout time') ||
        lowerQ.contains('completed')) {
      return 'You completed your journey (checked out) at ${summaryData.endTimeStr} at ${summaryData.lastAddress}.';
    } else if (lowerQ.contains('where did i travel') ||
        lowerQ.contains('where did i go') ||
        lowerQ.contains('route') ||
        lowerQ.contains('places')) {
      return 'Today you travelled from ${summaryData.firstAddress} to ${summaryData.lastAddress}, covering a total distance of ${summaryData.totalDistanceKm.toStringAsFixed(2)} km.';
    } else if (lowerQ.contains('how many') &&
        (lowerQ.contains('km') || lowerQ.contains('kilomet') || lowerQ.contains('distance') || lowerQ.contains('meters'))) {
      return 'You travelled approximately ${summaryData.totalDistanceKm.toStringAsFixed(2)} kilometres today across ${summaryData.tripCount} trip session(s).';
    } else if (lowerQ.contains('first location') ||
        lowerQ.contains('start location') ||
        lowerQ.contains('starting location') ||
        lowerQ.contains('where did i start')) {
      return 'Your first location was ${summaryData.firstAddress} (Coordinates: ${summaryData.firstLat.toStringAsFixed(5)}, ${summaryData.firstLng.toStringAsFixed(5)}), recorded at ${summaryData.startTimeStr}.';
    } else if (lowerQ.contains('last location') ||
        lowerQ.contains('end location') ||
        lowerQ.contains('final location') ||
        lowerQ.contains('destination')) {
      return 'Your last location was ${summaryData.lastAddress} (Coordinates: ${summaryData.lastLat.toStringAsFixed(5)}, ${summaryData.lastLng.toStringAsFixed(5)}), recorded at ${summaryData.endTimeStr}.';
    } else if (lowerQ.contains('how long') ||
        lowerQ.contains('duration') ||
        lowerQ.contains('travel time') ||
        lowerQ.contains('time travelling') ||
        lowerQ.contains('time traveling')) {
      return 'You were travelling for a total of ${summaryData.formattedDuration} today (Checked in at ${summaryData.startTimeStr}, completed at ${summaryData.endTimeStr}).';
    } else if (lowerQ.contains('summary') ||
        lowerQ.contains('activity') ||
        lowerQ.contains('overview')) {
      return 'Today the user checked in at ${summaryData.startTimeStr}, travelled approximately ${summaryData.totalDistanceKm.toStringAsFixed(1)} km, visited ${summaryData.locationCount} locations, and completed the journey at ${summaryData.endTimeStr}.';
    } else {
      return 'Your trip started at ${summaryData.startTimeStr} (${summaryData.firstAddress}) and ended at ${summaryData.endTimeStr} (${summaryData.lastAddress}), covering ${summaryData.totalDistanceKm.toStringAsFixed(2)} km in total.';
    }
  }

  static List<TrackingSession> _getTodaySessions(List<TrackingSession> sessions) {
    final now = DateTime.now();
    final todayList = sessions.where((s) {
      return s.startTime.year == now.year &&
          s.startTime.month == now.month &&
          s.startTime.day == now.day;
    }).toList();

    // If no sessions today, return all sessions as fallback for demonstration
    if (todayList.isEmpty) {
      return sessions;
    }
    return todayList;
  }

  static Future<_ContextData> _prepareContextData(List<TrackingSession> sessions) async {
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    final firstSession = sessions.first;
    final lastSession = sessions.last;

    final firstPt = firstSession.startLocation ?? firstSession.points.firstOrNull;
    final lastPt = lastSession.endLocation ?? lastSession.points.lastOrNull ?? firstPt;

    final double firstLat = firstPt?.latitude ?? 0.0;
    final double firstLng = firstPt?.longitude ?? 0.0;
    final double lastLat = lastPt?.latitude ?? 0.0;
    final double lastLng = lastPt?.longitude ?? 0.0;

    String firstAddr = 'Start Location';
    String lastAddr = 'End Location';

    if (firstPt != null) {
      firstAddr = await GeocodingService.getAddressFromCoordinates(firstLat, firstLng);
    }
    if (lastPt != null) {
      lastAddr = await GeocodingService.getAddressFromCoordinates(lastLat, lastLng);
    }

    double totalMeters = 0.0;
    int totalPoints = 0;
    int locationCount = 0;

    for (var s in sessions) {
      totalMeters += s.totalDistanceMeters;
      totalPoints += s.points.length;
      if (s.startLocation != null) locationCount++;
      if (s.endLocation != null && s.endLocation != s.startLocation) locationCount++;
    }

    if (locationCount == 0) locationCount = 1;

    final startFormat = DateFormat('h:mm a').format(firstSession.startTime.toLocal());
    final endTime = lastSession.endTime ?? DateTime.now();
    final endFormat = DateFormat('h:mm a').format(endTime.toLocal());

    final totalDuration = endTime.difference(firstSession.startTime);
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    String formattedDur = '';
    if (hours > 0) {
      formattedDur = '$hours hrs $minutes mins';
    } else {
      formattedDur = '$minutes mins';
    }

    return _ContextData(
      tripCount: sessions.length,
      startTimeStr: startFormat,
      endTimeStr: endFormat,
      totalDistanceKm: totalMeters / 1000.0,
      locationCount: locationCount,
      firstAddress: firstAddr,
      lastAddress: lastAddr,
      firstLat: firstLat,
      firstLng: firstLng,
      lastLat: lastLat,
      lastLng: lastLng,
      formattedDuration: formattedDur,
      totalPoints: totalPoints,
    );
  }
}

class _ContextData {
  final int tripCount;
  final String startTimeStr;
  final String endTimeStr;
  final double totalDistanceKm;
  final int locationCount;
  final String firstAddress;
  final String lastAddress;
  final double firstLat;
  final double firstLng;
  final double lastLat;
  final double lastLng;
  final String formattedDuration;
  final int totalPoints;

  _ContextData({
    required this.tripCount,
    required this.startTimeStr,
    required this.endTimeStr,
    required this.totalDistanceKm,
    required this.locationCount,
    required this.firstAddress,
    required this.lastAddress,
    required this.firstLat,
    required this.firstLng,
    required this.lastLat,
    required this.lastLng,
    required this.formattedDuration,
    required this.totalPoints,
  });
}
