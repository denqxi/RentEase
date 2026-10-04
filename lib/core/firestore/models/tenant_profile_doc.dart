import 'package:cloud_firestore/cloud_firestore.dart';

import 'tenant_private_prefs_doc.dart';

/// `tenantProfiles/{userId}` — tenant matching preferences and profile.
/// Document ID references `users/{userId}`.
///
/// The map pin ([poiLatLng], [poiLabel], [poiType]) and TOPSIS weights
/// ([wRent], [wDistance], [wAmenities]) are PRIVATE: they are stored in
/// `tenantProfiles/{uid}/private/prefs` ([TenantPrivatePrefsDoc]) and are NOT
/// part of [toMap]. They are populated in memory only for the signed-in
/// tenant via [withPrefs]; on an owner-side read they hold defaults (the
/// pin is (0, 0)) and must not be used.
class TenantProfileDoc {
  const TenantProfileDoc({
    required this.userId,
    required this.maxBudget,
    required this.requiredGender,
    required this.needsWifi,
    required this.maxDistanceKm,
    required this.poiLatLng,
    required this.poiLabel,
    this.poiType,
    this.roomType,
    this.preferredAmenities,
    required this.isSmoker,
    required this.hasPet,
    required this.groupSize,
    this.school,
    this.occupation,
    this.moveInDate,
    this.isSeeking = true,
    required this.wRent,
    required this.wDistance,
    required this.wAmenities,
    this.avgRating,
    this.totalRatings,
    this.profileCompleteness,
    this.credibilityScore,
    this.updatedAt,
  });

  /// Merges the tenant's own private prefs over this profile. Fields missing
  /// from [prefs] (or a null [prefs]) keep the current values, which for a
  /// not-yet-migrated account are the legacy ones read from the profile doc.
  TenantProfileDoc withPrefs(TenantPrivatePrefsDoc? prefs) {
    if (prefs == null) return this;
    return TenantProfileDoc(
      userId: userId,
      maxBudget: maxBudget,
      requiredGender: requiredGender,
      needsWifi: needsWifi,
      maxDistanceKm: maxDistanceKm,
      poiLatLng: prefs.poiLatLng ?? poiLatLng,
      poiLabel: prefs.poiLabel ?? poiLabel,
      poiType: prefs.poiType ?? poiType,
      roomType: roomType,
      preferredAmenities: preferredAmenities,
      isSmoker: isSmoker,
      hasPet: hasPet,
      groupSize: groupSize,
      school: school,
      occupation: occupation,
      moveInDate: moveInDate,
      isSeeking: isSeeking,
      wRent: prefs.wRent ?? wRent,
      wDistance: prefs.wDistance ?? wDistance,
      wAmenities: prefs.wAmenities ?? wAmenities,
      avgRating: avgRating,
      totalRatings: totalRatings,
      profileCompleteness: profileCompleteness,
      credibilityScore: credibilityScore,
      updatedAt: updatedAt,
    );
  }

  /// The private half of this profile, written to `private/prefs`.
  TenantPrivatePrefsDoc toPrefs() => TenantPrivatePrefsDoc(
    poiLatLng: poiLatLng,
    poiLabel: poiLabel,
    poiType: poiType,
    wRent: wRent,
    wDistance: wDistance,
    wAmenities: wAmenities,
  );

  /// Document ID, references users.
  final String userId;
  final num maxBudget;
  final String requiredGender;
  final bool needsWifi;
  final num maxDistanceKm;
  final GeoPoint poiLatLng;
  final String poiLabel;

  /// 'School' | 'Workplace' | 'Other' — chosen on the POI onboarding step.
  final String? poiType;


  // Soft preferences (onboarding Step 2). These never remove a property from
  // the pool — they only refine ranking — and are editable from Profile.
  final String? roomType;
  final List<String>? preferredAmenities;
  final bool isSmoker;
  final bool hasPet;

  final num groupSize;

  // Optional profile details shown in Find Tenants cards and the Phase 1
  // auto-info summary; they also feed profileCompleteness.
  final String? school;
  final String? occupation;
  final Timestamp? moveInDate;
  // emergencyContact is PRIVATE: it lives in users/{uid}/private/contact
  // (UserContactDoc), never on this world-readable-by-owners doc.
  final bool isSeeking;

  /// TOPSIS weights — wRent + wDistance + wAmenities must equal 1.0.
  /// Private (see class doc).
  final num wRent;
  final num wDistance;
  final num wAmenities;

  // Computed server-side.
  final num? avgRating;
  final num? totalRatings;
  final num? profileCompleteness;
  final num? credibilityScore;
  final Timestamp? updatedAt;

  factory TenantProfileDoc.fromMap(String id, Map<String, dynamic> map) =>
      TenantProfileDoc(
        userId: id,
        maxBudget: map['maxBudget'] as num? ?? 0,
        requiredGender: map['requiredGender'] as String? ?? '',
        needsWifi: map['needsWifi'] as bool? ?? false,
        maxDistanceKm: map['maxDistanceKm'] as num? ?? 0,
        poiLatLng: map['poiLatLng'] as GeoPoint? ?? const GeoPoint(0, 0),
        poiLabel: map['poiLabel'] as String? ?? '',
        poiType: map['poiType'] as String?,
        roomType: map['roomType'] as String?,
        preferredAmenities: (map['preferredAmenities'] as List?)
            ?.cast<String>(),
        isSmoker: map['isSmoker'] as bool? ?? false,
        hasPet: map['hasPet'] as bool? ?? false,
        groupSize: map['groupSize'] as num? ?? 1,
        school: map['school'] as String?,
        occupation: map['occupation'] as String?,
        moveInDate: map['moveInDate'] as Timestamp?,
        isSeeking: map['isSeeking'] as bool? ?? true,
        wRent: map['wRent'] as num? ?? 0.35,
        wDistance: map['wDistance'] as num? ?? 0.35,
        wAmenities: map['wAmenities'] as num? ?? 0.30,
        avgRating: map['avgRating'] as num?,
        totalRatings: map['totalRatings'] as num?,
        profileCompleteness: map['profileCompleteness'] as num?,
        credibilityScore: map['credibilityScore'] as num?,
        updatedAt: map['updatedAt'] as Timestamp?,
      );

  factory TenantProfileDoc.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => TenantProfileDoc.fromMap(doc.id, doc.data() ?? const {});

  /// The PUBLIC (owner-readable) fields only — never the pin or weights.
  Map<String, dynamic> toMap() => {
    'maxBudget': maxBudget,
    'requiredGender': requiredGender,
    'needsWifi': needsWifi,
    'maxDistanceKm': maxDistanceKm,
    if (roomType != null) 'roomType': roomType,
    if (preferredAmenities != null) 'preferredAmenities': preferredAmenities,
    'isSmoker': isSmoker,
    'hasPet': hasPet,
    'groupSize': groupSize,
    if (school != null) 'school': school,
    if (occupation != null) 'occupation': occupation,
    if (moveInDate != null) 'moveInDate': moveInDate,
    'isSeeking': isSeeking,
    if (avgRating != null) 'avgRating': avgRating,
    if (totalRatings != null) 'totalRatings': totalRatings,
    if (profileCompleteness != null) 'profileCompleteness': profileCompleteness,
    if (credibilityScore != null) 'credibilityScore': credibilityScore,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
