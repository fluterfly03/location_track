import 'package:flutter_test/flutter_test.dart';
import 'package:task1/models/tracking_point.dart';
import 'package:task1/models/tracking_session.dart';
import 'package:task1/services/ai_summary_service.dart';

void main() {
  group('AiSummaryService Tests', () {
    final startTime = DateTime(2026, 9, 30, 9, 45, 0);
    final endTime = DateTime(2026, 9, 30, 17, 20, 0);

    final session = TrackingSession(
      id: 'session_ai_1',
      startTime: startTime,
      endTime: endTime,
      startLocation: TrackingPoint(
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: startTime,
      ),
      endLocation: TrackingPoint(
        latitude: 12.9352,
        longitude: 77.6245,
        timestamp: endTime,
      ),
      totalDistanceMeters: 18400.0, // 18.4 km
      isTracking: false,
    );

    test('Generates daily summary matching example format', () async {
      final summary = await AiSummaryService.generateDailySummary([session]);
      expect(summary, contains('checked in at'));
      expect(summary, contains('18.4 km'));
      expect(summary, contains('completed the journey at'));
    });

    test('Answers "What time did I start my journey?"', () async {
      final answer = await AiSummaryService.answerQuestion(
        'What time did I start my journey?',
        [session],
      );
      expect(answer, contains('started your journey'));
      expect(answer, contains('9:45 AM'));
    });

    test('Answers "Where did I travel today?"', () async {
      final answer = await AiSummaryService.answerQuestion(
        'Where did I travel today?',
        [session],
      );
      expect(answer, contains('travelled from'));
      expect(answer, contains('18.40 km'));
    });

    test('Answers "How many kilometres did I travel?"', () async {
      final answer = await AiSummaryService.answerQuestion(
        'How many kilometres did I travel?',
        [session],
      );
      expect(answer, contains('18.40 kilometres'));
    });

    test('Answers "What was my first location?"', () async {
      final answer = await AiSummaryService.answerQuestion(
        'What was my first location?',
        [session],
      );
      expect(answer, contains('first location'));
      expect(answer, contains('12.97160'));
    });

    test('Answers "What was my last location?"', () async {
      final answer = await AiSummaryService.answerQuestion(
        'What was my last location?',
        [session],
      );
      expect(answer, contains('last location'));
      expect(answer, contains('12.93520'));
    });

    test('Answers "How long was I travelling?"', () async {
      final answer = await AiSummaryService.answerQuestion(
        'How long was I travelling?',
        [session],
      );
      expect(answer, contains('travelling for a total of'));
    });
  });
}
