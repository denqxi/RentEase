import 'package:cloud_firestore/cloud_firestore.dart';

/// `tenantProfiles/{userId}/private/prefs` — the tenant's map pin (POI) and
/// TOPSIS weights. Readable and writable only by that tenant (and admins);
/// owners reading `tenantProfiles/{uid}` for Find Tenants never see them.
class TenantPrivatePrefsDoc {
  const TenantPrivatePrefsDoc({
    this.poiLatLng,
    this.poiLabel,
    this.poiType,
    this.wRent,
    this.wDistance,
    this.wAmenities,
    this.updatedAt,
  });

  /// Pre-privacy field names that used to live on `tenantProfiles/{uid}`.
  static const legacyProfileKeys = [
    'poiLatLng',
    'poiLabel',
    'poiType',
    'wRent',
    'wDistance',
    'wAmenities',
  ];

  final GeoPoint? poiLatLng;
  final String? poiLabel;

  /// 'School' | 'Workplace' | 'Other'.
  final String? poiType;
  final num? wRent;
  final num? wDistance;
  final num? wAmenities;
  final Timestamp? updatedAt;

  factory TenantPrivatePrefsDoc.fromMap(Map<String, dynamic> map) =>
      TenantPrivatePrefsDoc(
        poiLatLng: map['poiLatLng'] as GeoPoint?,
        poiLabel: map['poiLabel'] as String?,
        poiType: map['poiType'] as String?,
        wRent: map['wRent'] as num?,
        wDistance: map['wDistance'] as num?,
        wAmenities: map['wAmenities'] as num?,
        updatedAt: map['updatedAt'] as Timestamp?,
      );

  factory TenantPrivatePrefsDoc.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => TenantPrivatePrefsDoc.fromMap(doc.data() ?? const {});

  /// Whether a raw `tenantProfiles/{uid}` map still holds legacy private
  /// fields (the self-migration trigger).
  static bool hasLegacyFields(Map<String, dynamic> profileMap) =>
      legacyProfileKeys.any(profileMap.containsKey);

  /// What the self-migration writes and deletes. [copy] holds the legacy
  /// values to merge into the prefs doc (an existing prefs value always wins,
  /// so re-running never overwrites newer data); [remove] lists every legacy
  /// key still on the profile doc, to be deleted in the same batch. Both are
  /// empty once the profile is clean, which makes the migration idempotent.
  static ({Map<String, dynamic> copy, List<String> remove}) legacyMigrationPlan(
    Map<String, dynamic> profileMap,
    Map<String, dynamic> existingPrefs,
  ) {
    final copy = <String, dynamic>{};
    final remove = <String>[];
    for (final key in legacyProfileKeys) {
      if (!profileMap.containsKey(key)) continue;
      remove.add(key);
      final value = profileMap[key];
      if (value != null && !existingPrefs.containsKey(key)) copy[key] = value;
    }
    return (copy: copy, remove: remove);
  }

  /// Only the non-null fields, so a merge write never wipes the others.
  Map<String, dynamic> toMap() => {
    if (poiLatLng != null) 'poiLatLng': poiLatLng,
    if (poiLabel != null) 'poiLabel': poiLabel,
    if (poiType != null) 'poiType': poiType,
    if (wRent != null) 'wRent': wRent,
    if (wDistance != null) 'wDistance': wDistance,
    if (wAmenities != null) 'wAmenities': wAmenities,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
