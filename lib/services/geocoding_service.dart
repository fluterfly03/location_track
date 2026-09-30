import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static final Map<String, String> _addressCache = {};

  /// Convert latitude & longitude into a human-readable location description.
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    // Try native geocoding package first
    try {
      final geocoding = Geocoding();
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        List<String> parts = [];
        if (place.name != null && place.name!.isNotEmpty && place.name != place.street) {
          parts.add(place.name!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }

        if (parts.isNotEmpty) {
          final result = parts.join(', ');
          _addressCache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('Native geocoding failed: $e, falling back to Nominatim API');
    }

    // Fallback to OpenStreetMap Nominatim reverse geocoding API
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=16',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'LocationTrackerApp/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final parts = displayName.split(',');
          final shortName = parts.take(3).join(',').trim();
          _addressCache[cacheKey] = shortName;
          return shortName;
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding failed: $e');
    }

    // Default fallback
    final fallback = 'Loc (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    _addressCache[cacheKey] = fallback;
    return fallback;
  }
}
