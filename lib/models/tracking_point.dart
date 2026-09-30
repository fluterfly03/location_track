class TrackingPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double speed; // in m/s

  TrackingPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy = 0.0,
    this.speed = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'accuracy': accuracy,
        'speed': speed,
      };

  factory TrackingPoint.fromJson(Map<String, dynamic> json) => TrackingPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode ^ timestamp.hashCode;
}
