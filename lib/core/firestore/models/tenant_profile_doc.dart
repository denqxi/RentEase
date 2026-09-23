import 'package:cloud_firestore/cloud_firestore.dart';

/// `tenantProfiles/{userId}` — tenant matching preferences and profile.
/// Document ID references `users/{userId}`.
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
    this.emergencyContact,
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
  final String? emergencyContact;
  final bool isSeeking;

  /// TOPSIS weights — wRent + wDistance + wAmenities must equal 1.0.
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
        emergencyContact: map['emergencyContact'] as String?,
        isSeeking: map['isSeeking'] as bool? ?? true,
        wRent: map['wRent'] as num? ?? 0.5,
        wDistance: map['wDistance'] as num? ?? 0.3,
        wAmenities: map['wAmenities'] as num? ?? 0.2,
        avgRating: map['avgRating'] as num?,
        totalRatings: map['totalRatings'] as num?,
        profileCompleteness: map['profileCompleteness'] as num?,
        credibilityScore: map['credibilityScore'] as num?,
        updatedAt: map['updatedAt'] as Timestamp?,
      );

  factory TenantProfileDoc.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => TenantProfileDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
    'maxBudget': maxBudget,
    'requiredGender': requiredGender,
    'needsWifi': needsWifi,
    'maxDistanceKm': maxDistanceKm,
    'poiLatLng': poiLatLng,
    'poiLabel': poiLabel,
    if (poiType != null) 'poiType': poiType,
    if (roomType != null) 'roomType': roomType,
    if (preferredAmenities != null) 'preferredAmenities': preferredAmenities,
    'isSmoker': isSmoker,
    'hasPet': hasPet,
    'groupSize': groupSize,
    if (school != null) 'school': school,
    if (occupation != null) 'occupation': occupation,
    if (moveInDate != null) 'moveInDate': moveInDate,
    if (emergencyContact != null) 'emergencyContact': emergencyContact,
    'isSeeking': isSeeking,
    'wRent': wRent,
    'wDistance': wDistance,
    'wAmenities': wAmenities,
    if (avgRating != null) 'avgRating': avgRating,
    if (totalRatings != null) 'totalRatings': totalRatings,
    if (profileCompleteness != null) 'profileCompleteness': profileCompleteness,
    if (credibilityScore != null) 'credibilityScore': credibilityScore,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
