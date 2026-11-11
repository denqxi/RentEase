import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_options.dart';

/// One place found by a search: a label and where it is.
class GeocodingResult {
  const GeocodingResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });

  /// Short label, e.g. "Matina".
  final String name;

  /// Full address line, e.g. "Matina, Davao City".
  final String address;
  final double lat;
  final double lng;
}

/// Thrown when an online search could not be completed (offline, timeout,
/// or a server error). "No results" is an empty list, not this.
class GeocodingException implements Exception {
  const GeocodingException();
}

/// Service for forward and reverse geocoding with OpenStreetMap Nominatim
/// and offline fallback for Davao City landmarks.
///
/// Follows the public Nominatim usage policy
/// (https://operations.osmfoundation.org/policies/nominatim/):
///  * at most one request per second, app-wide ([minRequestInterval]);
///  * no search-as-you-type: [searchOnline] must only be called from an
///    explicit user action (a search button), never from onChanged. Use
///    [searchOffline] for suggestions while typing;
///  * results are cached, so a repeated query or pin sends no request;
///  * an identifying User-Agent is sent.
class GeocodingService {
  const GeocodingService({this.httpClient});

  final http.Client? httpClient;

  static const _headers = {
    'User-Agent': 'RentEase/1.0 (com.rentease.app)',
    'Accept': 'application/json',
  };
  static const _timeout = Duration(seconds: 4);
  static const _maxCacheEntries = 100;

  /// Davao City bounding box for searches: left, top, right, bottom.
  static const _davaoViewbox = '125.20,7.60,125.75,6.95';

  /// Nominatim allows an absolute maximum of 1 request per second.
  @visibleForTesting
  static Duration minRequestInterval = const Duration(seconds: 1);

  // Shared by every instance (the service is created per screen).
  static final Map<String, String> _reverseCache = {};
  static final Map<String, List<GeocodingResult>> _searchCache = {};
  static Future<void> _gate = Future.value();
  static DateTime? _lastRequestAt;

  @visibleForTesting
  static void resetForTest() {
    _reverseCache.clear();
    _searchCache.clear();
    _gate = Future.value();
    _lastRequestAt = null;
  }

  /// Completes when this caller may send its request: requests run one at a
  /// time, at least [minRequestInterval] apart.
  static Future<void> _waitForSlot() {
    final previous = _gate;
    final done = Completer<void>();
    _gate = done.future;
    return previous.then((_) async {
      final last = _lastRequestAt;
      if (last != null) {
        final wait = minRequestInterval - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequestAt = DateTime.now();
      done.complete();
    });
  }

  static void _remember<V>(Map<String, V> cache, String key, V value) {
    if (cache.length >= _maxCacheEntries) cache.remove(cache.keys.first);
    cache[key] = value;
  }

  static String _withoutCountry(String displayName) {
    final s = displayName.trim();
    const suffix = ', Philippines';
    return s.endsWith(suffix)
        ? s.substring(0, s.length - suffix.length).trim()
        : s;
  }

  Future<http.Response> _get(Uri uri) async {
    final client = httpClient ?? http.Client();
    try {
      await _waitForSlot();
      return await client.get(uri, headers: _headers).timeout(_timeout);
    } finally {
      if (httpClient == null) client.close();
    }
  }

  /// Reverse-geocodes [lat] and [lng] into a human-readable full address string.
  ///
  /// Uses OpenStreetMap's Nominatim API with a fallback to offline Davao City reference
  /// landmarks if the network request fails or times out.
  Future<String> reverseGeocode(double lat, double lng) async {
    // ~1 m precision: the same pin never asks twice.
    final key = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
    final cached = _reverseCache[key];
    if (cached != null) return cached;

    try {
      final response = await _get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.trim().isNotEmpty) {
          final formatted = _withoutCountry(displayName);
          _remember(_reverseCache, key, formatted);
          return formatted;
        }
      }
    } catch (_) {
      // Network failure, timeout, or invalid response — fall back gracefully.
    }

    return fallbackAddressFor(lat, lng);
  }

  /// Instant, offline suggestions from the bundled Davao City places and
  /// areas. Safe to call on every keystroke (no network).
  static List<GeocodingResult> searchOffline(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    return [
      for (final p in [...AppOptions.davaoPlaces, ...AppOptions.davaoAreas])
        if ((p['name'] as String).toLowerCase().contains(q))
          GeocodingResult(
            name: p['name'] as String,
            address: '${p['name']}, Davao City',
            lat: p['lat'] as double,
            lng: p['lng'] as double,
          ),
    ];
  }

  /// Searches Nominatim for [query] within Davao City. Call only from an
  /// explicit user action (see the class comment). Returns an empty list
  /// when nothing matches; throws [GeocodingException] when the search
  /// could not be completed.
  Future<List<GeocodingResult>> searchOnline(String query) async {
    final key = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (key.length < 3) return const [];
    final cached = _searchCache[key];
    if (cached != null) return cached;

    final http.Response response;
    try {
      response = await _get(
        Uri.https('nominatim.openstreetmap.org', '/search', {
          'format': 'jsonv2',
          'q': key,
          'countrycodes': 'ph',
          'viewbox': _davaoViewbox,
          'bounded': '1',
          'limit': '5',
        }),
      );
    } catch (_) {
      throw const GeocodingException();
    }
    if (response.statusCode != 200) throw const GeocodingException();

    final List<GeocodingResult> results;
    try {
      results = [
        for (final item in jsonDecode(response.body) as List)
          if (item is Map<String, dynamic>) ?_parseResult(item),
      ];
    } catch (_) {
      throw const GeocodingException();
    }
    _remember(_searchCache, key, results);
    return results;
  }

  static GeocodingResult? _parseResult(Map<String, dynamic> item) {
    final lat = double.tryParse('${item['lat']}');
    final lng = double.tryParse('${item['lon']}');
    final display = (item['display_name'] as String?)?.trim() ?? '';
    if (lat == null || lng == null || display.isEmpty) return null;
    final address = _withoutCountry(display);
    final name = (item['name'] as String?)?.trim() ?? '';
    return GeocodingResult(
      name: name.isNotEmpty ? name : address.split(',').first.trim(),
      address: address,
      lat: lat,
      lng: lng,
    );
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
