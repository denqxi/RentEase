import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Straight-line (Haversine) distance — see CLAUDE.md "Distance
/// Calculation". Runs entirely on-device as part of the client-side
/// matching engine (no Cloud Functions, no Maps Distance Matrix API).
class DistanceUtils {
  DistanceUtils._();

  // `Distance()`'s defaults are wrong for this use case: `roundResult: true`
  // rounds to the nearest whole *requested unit* (km here — turning e.g.
  // 5.556 km into 6.0, degrading LocationMatch's <= comparison to
  // kilometer-level precision), and the default calculator is Vincenty, not
  // Haversine, despite CLAUDE.md documenting Haversine specifically.
  static const Distance _distance = Distance(
    roundResult: false,
    calculator: Haversine(),
  );

  /// Like [kmBetween], but a missing coordinate yields [double.infinity].
  /// Models default an absent pin to `GeoPoint(0, 0)` (Gulf of Guinea), so two
  /// missing pins would otherwise read as "0 km apart" and pass LocationMatch.
  static double kmBetweenOrInfinity(GeoPoint a, GeoPoint b) {
    bool missing(GeoPoint p) =>
        (p.latitude == 0 && p.longitude == 0) ||
        !p.latitude.isFinite ||
        !p.longitude.isFinite;
    if (missing(a) || missing(b)) return double.infinity;
    return kmBetween(a, b);
  }

  /// Distance in kilometers between two Firestore [GeoPoint]s.
  static double kmBetween(GeoPoint a, GeoPoint b) {
    return _distance.as(
      LengthUnit.Kilometer,
      LatLng(a.latitude, a.longitude),
      LatLng(b.latitude, b.longitude),
    );
  }
}
