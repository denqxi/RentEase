import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Straight-line (Haversine) distance — see CLAUDE.md "Distance
/// Calculation". Runs entirely on-device as part of the client-side
/// matching engine (no Cloud Functions, no Maps Distance Matrix API).
class DistanceUtils {
  DistanceUtils._();

  static const Distance _distance = Distance();

  /// Distance in kilometers between two Firestore [GeoPoint]s.
  static double kmBetween(GeoPoint a, GeoPoint b) {
    return _distance.as(
      LengthUnit.Kilometer,
      LatLng(a.latitude, a.longitude),
      LatLng(b.latitude, b.longitude),
    );
  }
}
