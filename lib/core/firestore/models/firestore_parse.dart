import 'package:cloud_firestore/cloud_firestore.dart';

/// Lenient field readers for Firestore maps. A field with an unexpected type
/// (legacy docs, manual console edits, num stored as String) falls back to a
/// default instead of throwing a TypeError that would break a whole list.

num parseNum(dynamic v, [num fallback = 0]) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim()) ?? fallback;
  return fallback;
}

num? parseNumOrNull(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim());
  return null;
}

bool parseBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
  }
  return fallback;
}

Timestamp? parseTimestamp(dynamic v) {
  if (v is Timestamp) return v;
  if (v is DateTime) return Timestamp.fromDate(v);
  if (v is String) {
    final dt = DateTime.tryParse(v);
    return dt == null ? null : Timestamp.fromDate(dt);
  }
  if (v is int) return Timestamp.fromMillisecondsSinceEpoch(v);
  return null;
}

GeoPoint? parseGeoPoint(dynamic v) {
  if (v is GeoPoint) return v;
  if (v is Map) {
    final lat = parseNumOrNull(v['latitude']);
    final lng = parseNumOrNull(v['longitude']);
    if (lat != null && lng != null) {
      return GeoPoint(lat.toDouble(), lng.toDouble());
    }
  }
  return null;
}

List<String> parseStringList(dynamic v) => v is List
    ? [for (final e in v) if (e != null) e.toString()]
    : const [];

List<String>? parseStringListOrNull(dynamic v) =>
    v is List ? parseStringList(v) : null;
