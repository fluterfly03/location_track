import 'package:intl/intl.dart';
import 'tracking_point.dart';

class TrackingSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  TrackingPoint? startLocation;
  TrackingPoint? endLocation;
  final List<TrackingPoint> points;
  double totalDistanceMeters;
  bool isTracking;

  TrackingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.startLocation,
    this.endLocation,
    List<TrackingPoint>? points,
    this.totalDistanceMeters = 0.0,
    this.isTracking = true,
  }) : points = points ?? [];

  /// Distance in Kilometres rounded to 3 decimals
  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  String get formattedDistanceKm => '${totalDistanceKm.toStringAsFixed(3)} km';

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get formattedDuration {
    final d = duration;
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String get formattedStartTime {
    return DateFormat('MMM dd, yyyy - hh:mm:ss a').format(startTime.toLocal());
  }

  String get formattedEndTime {
    if (endTime == null) return 'Active Session';
    return DateFormat('MMM dd, yyyy - hh:mm:ss a').format(endTime!.toLocal());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'startLocation': startLocation?.toJson(),
        'endLocation': endLocation?.toJson(),
        'points': points.map((p) => p.toJson()).toList(),
        'totalDistanceMeters': totalDistanceMeters,
        'isTracking': isTracking,
      };

  factory TrackingSession.fromJson(Map<String, dynamic> json) {
    return TrackingSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      startLocation: json['startLocation'] != null
          ? TrackingPoint.fromJson(json['startLocation'] as Map<String, dynamic>)
          : null,
      endLocation: json['endLocation'] != null
          ? TrackingPoint.fromJson(json['endLocation'] as Map<String, dynamic>)
          : null,
      points: (json['points'] as List<dynamic>?)
              ?.map((p) => TrackingPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      totalDistanceMeters: (json['totalDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      isTracking: json['isTracking'] as bool? ?? false,
    );
  }
}
