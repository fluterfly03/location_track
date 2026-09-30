import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tracking_point.dart';

class LocationService {
  /// Check if GPS location services are enabled on the device.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request or check location permission state.
  static Future<LocationPermission> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Get current exact user location once.
  static Future<TrackingPoint?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return TrackingPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        accuracy: position.accuracy,
        speed: position.speed,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Create a continuous background-capable position stream configured appropriately.
  static Stream<Position> getPositionStream() {
    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3, // Minimum displacement in meters before update event
        intervalDuration: const Duration(seconds: 2),
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Location Tracker Active",
          notificationText: "Tracking your movement in background",
          notificationIcon: AndroidResource(name: 'ic_launcher'),
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance between two coordinate pairs in meters using standard geodesic formula.
  static double calculateDistanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Evaluates whether a new point should be recorded to avoid duplicates & bad accuracy.
  /// Returns null if point should be ignored, or distance in meters if valid.
  static double? processNewLocationPoint({
    required TrackingPoint? lastRecordedPoint,
    required Position newPosition,
    double maxAllowedAccuracyMeters = 35.0,
    double minDistanceThresholdMeters = 3.0,
  }) {
    // 1. Accuracy Check: Ignore points with poor GPS accuracy
    if (newPosition.accuracy > maxAllowedAccuracyMeters) {
      debugPrint(
          'Skipped point due to poor accuracy (${newPosition.accuracy}m > ${maxAllowedAccuracyMeters}m)');
      return null;
    }

    if (lastRecordedPoint == null) {
      // First point is always valid
      return 0.0;
    }

    // 2. Duplicate / Stationary Check
    double distanceMeters = calculateDistanceMeters(
      lastRecordedPoint.latitude,
      lastRecordedPoint.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // If moved less than threshold (e.g. 3m), treat as noise / standing still
    if (distanceMeters < minDistanceThresholdMeters) {
      debugPrint(
          'Skipped duplicate/stationary point ($distanceMeters m < $minDistanceThresholdMeters m)');
      return null;
    }

    // 3. Plausibility / Speed Spike Filter
    DateTime newTime = newPosition.timestamp;
    double timeDiffSeconds =
        newTime.difference(lastRecordedPoint.timestamp).inMilliseconds / 1000.0;
    if (timeDiffSeconds > 0) {
      double calculatedSpeedMps = distanceMeters / timeDiffSeconds; // m/s
      // Speed threshold: 42 m/s (~150 km/h). Skips impossible teleport jumps
      if (calculatedSpeedMps > 42.0) {
        debugPrint('Skipped GPS glitch jump (speed $calculatedSpeedMps m/s too high)');
        return null;
      }
    }

    return distanceMeters;
  }
}
