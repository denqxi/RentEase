import 'package:cloud_firestore/cloud_firestore.dart';

/// `matches/{matchId}` — bilateral filter + TOPSIS results.
/// Written by Cloud Functions only; the app reads cached scores.
class MatchDoc {
  const MatchDoc({
    required this.matchId,
    required this.tenantId,
    required this.ownerId,
    required this.propertyId,
    required this.pScore,
    required this.tScore,
    required this.bScore,
    this.distanceKm,
    this.tenantCi,
    this.ownerCi,
    this.tenantRank,
    this.ownerRank,
    this.computedAt,
    this.version,
  });

  /// Document ID (convention: `{tenantId}_{propertyId}`).
  final String matchId;
  final String tenantId;
  final String ownerId;
  final String propertyId;

  /// Layer 1: Gender × Smoking × Pet × Occupancy (0 or 1).
  final num pScore;

  /// Layer 2: Budget × GenderPolicy × WiFi × Location (0 or 1).
  final num tScore;

  /// pScore × tScore — 1 means eligible for TOPSIS ranking.
  final num bScore;

  /// Haversine distance (km) between property location and tenant POI,
  /// computed server-side at match time. Shown as "X km" in the UI.
  final num? distanceKm;

  /// TOPSIS Ci for tenant-side ranking (0.00–1.00).
  final num? tenantCi;

  /// TOPSIS Ci for owner-side ranking (0.00–1.00).
  final num? ownerCi;
  final num? tenantRank;
  final num? ownerRank;
  final Timestamp? computedAt;
  final num? version;

  factory MatchDoc.fromMap(String id, Map<String, dynamic> map) => MatchDoc(
        matchId: id,
        tenantId: map['tenantId'] as String? ?? '',
        ownerId: map['ownerId'] as String? ?? '',
        propertyId: map['propertyId'] as String? ?? '',
        pScore: map['pScore'] as num? ?? 0,
        tScore: map['tScore'] as num? ?? 0,
        bScore: map['bScore'] as num? ?? 0,
        distanceKm: map['distanceKm'] as num?,
        tenantCi: map['tenantCi'] as num?,
        ownerCi: map['ownerCi'] as num?,
        tenantRank: map['tenantRank'] as num?,
        ownerRank: map['ownerRank'] as num?,
        computedAt: map['computedAt'] as Timestamp?,
        version: map['version'] as num?,
      );

  factory MatchDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      MatchDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'tenantId': tenantId,
        'ownerId': ownerId,
        'propertyId': propertyId,
        'pScore': pScore,
        'tScore': tScore,
        'bScore': bScore,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (tenantCi != null) 'tenantCi': tenantCi,
        if (ownerCi != null) 'ownerCi': ownerCi,
        if (tenantRank != null) 'tenantRank': tenantRank,
        if (ownerRank != null) 'ownerRank': ownerRank,
        'computedAt': FieldValue.serverTimestamp(),
        if (version != null) 'version': version,
      };
}
