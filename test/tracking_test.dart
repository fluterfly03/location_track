import 'package:flutter_test/flutter_test.dart';
import 'package:task1/models/tracking_point.dart';
import 'package:task1/models/tracking_session.dart';
import 'package:task1/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('TrackingPoint Tests', () {
    test('TrackingPoint serialization and deserialization', () {
      final now = DateTime.now();
      final point = TrackingPoint(
        latitude: 12.971598,
        longitude: 77.594566,
        timestamp: now,
        accuracy: 4.5,
        speed: 1.2,
      );

      final json = point.toJson();
      final restored = TrackingPoint.fromJson(json);

      expect(restored.latitude, 12.971598);
      expect(restored.longitude, 77.594566);
      expect(restored.accuracy, 4.5);
      expect(restored.speed, 1.2);
    });
  });

  group('TrackingSession Tests', () {
    test('Kilometres distance conversion', () {
      final start = DateTime.now();
      final session = TrackingSession(
        id: 'session_1',
        startTime: start,
        totalDistanceMeters: 2450.0, // 2.45 km
      );

      expect(session.totalDistanceKm, 2.45);
      expect(session.formattedDistanceKm, '2.450 km');
    });

    test('TrackingSession duration calculation', () {
      final start = DateTime(2026, 9, 30, 10, 0, 0);
      final end = DateTime(2026, 9, 30, 10, 45, 30);
      final session = TrackingSession(
        id: 'session_2',
        startTime: start,
        endTime: end,
        isTracking: false,
      );

      expect(session.duration.inMinutes, 45);
      expect(session.formattedDuration, '45:30');
    });
  });

  group('Location Filter Logic Tests', () {
    test('Rejects points with poor accuracy > 35m', () {
      final lastPoint = TrackingPoint(
        latitude: 12.971598,
        longitude: 77.594566,
        timestamp: DateTime.now(),
      );

      final noisyPos = Position(
        latitude: 12.971600,
        longitude: 77.594570,
        timestamp: DateTime.now(),
        accuracy: 50.0, // High error circle
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      final result = LocationService.processNewLocationPoint(
        lastRecordedPoint: lastPoint,
        newPosition: noisyPos,
      );

      expect(result, isNull);
    });

    test('Rejects duplicate/stationary points moved < 3.0m', () {
      final lastPoint = TrackingPoint(
        latitude: 12.971598,
        longitude: 77.594566,
        timestamp: DateTime.now(),
      );

      // Moved only ~0.1 meter (basically identical position)
      final duplicatePos = Position(
        latitude: 12.9715981,
        longitude: 77.5945661,
        timestamp: DateTime.now().add(const Duration(seconds: 2)),
        accuracy: 3.0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      final result = LocationService.processNewLocationPoint(
        lastRecordedPoint: lastPoint,
        newPosition: duplicatePos,
      );

      expect(result, isNull);
    });
  });
}
