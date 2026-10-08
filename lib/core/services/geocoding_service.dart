import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_options.dart';

/// Service for forward and reverse geocoding with OpenStreetMap Nominatim
/// and offline fallback for Davao City landmarks.
class GeocodingService {
  const GeocodingService({this.httpClient});

  final http.Client? httpClient;

  /// Reverse-geocodes [lat] and [lng] into a human-readable full address string.
  ///
  /// Uses OpenStreetMap's Nominatim API with a fallback to offline Davao City reference
  /// landmarks if the network request fails or times out.
  Future<String> reverseGeocode(double lat, double lng) async {
    final client = httpClient ?? http.Client();
    final shouldClose = httpClient == null;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1',
      );

      final response = await client.get(
        uri,
        headers: const {
          'User-Agent': 'RentEase/1.0 (com.rentease.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.trim().isNotEmpty) {
          var formatted = displayName.trim();
          if (formatted.endsWith(', Philippines')) {
            formatted = formatted
                .substring(0, formatted.length - ', Philippines'.length)
                .trim();
          }
          return formatted;
        }
      }
    } catch (_) {
      // Network failure, timeout, or invalid response — fall back gracefully.
    } finally {
      if (shouldClose) {
        client.close();
      }
    }

    return fallbackAddressFor(lat, lng);
  }

  /// Offline fallback reverse-geocoder that finds the closest named Davao City district.
  static String fallbackAddressFor(double lat, double lng) {
    Map<String, dynamic>? nearest;
    double best = double.infinity;
    for (final area in AppOptions.davaoAreas) {
      final aLat = area['lat'] as double;
      final aLng = area['lng'] as double;
      final dLat = lat - aLat;
      final dLng = lng - aLng;
      final d = dLat * dLat + dLng * dLng;
      if (d < best) {
        best = d;
        nearest = area;
      }
    }

    final name = nearest != null ? nearest['name'] as String : 'Davao City';
    return '$name, Davao City';
  }
}
