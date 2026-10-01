/// Model representing distance data returned by an API response.
/// Safely handles valid numbers, null values, negative/invalid values, and missing fields.
class DistanceResponse {
  final double? rawDistance;
  final bool hasDistanceField;
  final String? message;

  const DistanceResponse({
    this.rawDistance,
    this.hasDistanceField = false,
    this.message,
  });

  /// Indicates if a distance value was present in the response (non-null).
  bool get isPresent => hasDistanceField && rawDistance != null;

  /// Strict validation: Distance must be present, non-null, non-NaN, non-infinite, and non-negative (>= 0.0).
  bool get isValid =>
      isPresent &&
      !rawDistance!.isNaN &&
      !rawDistance!.isInfinite &&
      rawDistance! >= 0.0;

  /// Returns the valid distance ONLY if it passes strict validation.
  /// Returns `null` if the distance is missing, null, negative, or invalid.
  /// NO ARBITRARY FALLBACK VALUE (e.g. 0.88) IS EVER USED HERE.
  double? get validDistance => isValid ? rawDistance : null;

  factory DistanceResponse.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('distance')) {
      return const DistanceResponse(
        rawDistance: null,
        hasDistanceField: false,
        message: 'Field "distance" is missing in API response',
      );
    }

    final value = json['distance'];
    if (value == null) {
      return const DistanceResponse(
        rawDistance: null,
        hasDistanceField: true,
        message: 'Field "distance" is explicitly null',
      );
    }

    if (value is num) {
      return DistanceResponse(
        rawDistance: value.toDouble(),
        hasDistanceField: true,
      );
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      return DistanceResponse(
        rawDistance: parsed,
        hasDistanceField: true,
        message: parsed == null ? 'Failed to parse distance string' : null,
      );
    }

    return const DistanceResponse(
      rawDistance: null,
      hasDistanceField: true,
      message: 'Distance field contains invalid data type',
    );
  }

  Map<String, dynamic> toJson() => {
        'distance': rawDistance,
        'hasDistanceField': hasDistanceField,
        if (message != null) 'message': message,
      };

  @override
  String toString() =>
      'DistanceResponse(rawDistance: $rawDistance, isPresent: $isPresent, isValid: $isValid)';
}
