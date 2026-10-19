import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/navigation_models.dart';

/// Service responsible for fetching live road navigation routes from the OSRM
/// routing engine and launching external Google Maps navigation.
class NavigationService {
  final http.Client _client;

  NavigationService({http.Client? client}) : _client = client ?? http.Client();

  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1';

  /// Fetches turn-by-turn road geometry and maneuver steps between [origin] and [destination].
  Future<RoutePlan?> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    RouteProfile profile = RouteProfile.driving,
  }) async {
    final url = Uri.parse(
      '$_osrmBaseUrl/${profile.osrmKey}/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );

    try {
      final response = await _client.get(
        url,
        headers: {'User-Agent': 'RentEase-Navigation/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return _buildStraightLineFallback(origin, destination, profile);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok' || (data['routes'] as List?)?.isEmpty != false) {
        return _buildStraightLineFallback(origin, destination, profile);
      }

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final totalDistance = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final totalDuration = (route['duration'] as num?)?.toDouble() ?? 0.0;

      // Parse road coordinates from GeoJSON LineString [ [lng, lat], ... ]
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final rawCoords = (geometry?['coordinates'] as List?) ?? const [];
      final List<LatLng> points = [];
      for (final c in rawCoords) {
        if (c is List && c.length >= 2) {
          final lng = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }

      // Parse turn-by-turn steps
      final List<NavigationStep> steps = [];
      final legs = (route['legs'] as List?) ?? const [];
      if (legs.isNotEmpty) {
        final leg = legs.first as Map<String, dynamic>;
        final rawSteps = (leg['steps'] as List?) ?? const [];
        for (final s in rawSteps) {
          if (s is Map<String, dynamic>) {
            final sDist = (s['distance'] as num?)?.toDouble() ?? 0.0;
            final sDur = (s['duration'] as num?)?.toDouble() ?? 0.0;
            final sName = (s['name'] as String?)?.trim() ?? '';
            final maneuverMap = s['maneuver'] as Map<String, dynamic>?;

            final typeStr = maneuverMap?['type'] as String?;
            final modifier = maneuverMap?['modifier'] as String?;
            final locList = maneuverMap?['location'] as List?;
            LatLng loc = destination;
            if (locList != null && locList.length >= 2) {
              loc = LatLng((locList[1] as num).toDouble(), (locList[0] as num).toDouble());
            }

            final maneuver = NavigationManeuver(
              type: ManeuverType.fromString(typeStr),
              modifier: modifier,
              location: loc,
              instruction: sName.isNotEmpty ? sName : 'Continue along route',
            );

            steps.add(NavigationStep(
              distanceMeters: sDist,
              durationSeconds: sDur,
              roadName: sName,
              maneuver: maneuver,
            ));
          }
        }
      }

      return RoutePlan(
        points: points.isNotEmpty ? points : [origin, destination],
        totalDistanceMeters: totalDistance,
        totalDurationSeconds: totalDuration,
        steps: steps,
        profile: profile,
      );
    } catch (_) {
      return _buildStraightLineFallback(origin, destination, profile);
    }
  }

  /// Builds a straight-line fallback route if OSRM is unreachable (e.g. offline).
  RoutePlan _buildStraightLineFallback(
    LatLng origin,
    LatLng destination,
    RouteProfile profile,
  ) {
    const distCalc = Distance();
    final double distMeters = distCalc.as(LengthUnit.Meter, origin, destination);
    // Estimated speed: Driving ~30 km/h (8.33 m/s), Walking ~4.5 km/h (1.25 m/s)
    final double speedMps = profile == RouteProfile.driving ? 8.33 : 1.25;
    final double durationSeconds = distMeters / speedMps;

    final step = NavigationStep(
      distanceMeters: distMeters,
      durationSeconds: durationSeconds,
      roadName: 'Direct route to destination',
      maneuver: NavigationManeuver(
        type: ManeuverType.depart,
        modifier: null,
        location: origin,
        instruction: 'Head straight to destination',
      ),
    );

    return RoutePlan(
      points: [origin, destination],
      totalDistanceMeters: distMeters,
      totalDurationSeconds: durationSeconds,
      steps: [step],
      profile: profile,
    );
  }

  /// Launches external Google Maps turn-by-turn navigation via [url_launcher].
  Future<bool> launchExternalGoogleMaps({
    required LatLng destination,
    LatLng? origin,
    RouteProfile profile = RouteProfile.driving,
  }) async {
    final mode = profile == RouteProfile.walking ? 'walking' : 'driving';
    final originParam = origin != null ? '&origin=${origin.latitude},${origin.longitude}' : '';

    final Uri googleMapsWeb = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$originParam&destination=${destination.latitude},${destination.longitude}&travelmode=$mode',
    );

    try {
      return await launchUrl(googleMapsWeb, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
