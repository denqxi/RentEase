import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../domain/services/topsis_service.dart' show TopsisResult;

/// Raw Firestore access backing [FilteringRepository].
class MatchingRemoteDataSource {
  MatchingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String?> fetchUserGender(String uid) async {
    final snap =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (!snap.exists) return null;
    return snap.data()?['gender'] as String?;
  }

  Future<TenantProfileDoc?> fetchTenantProfile(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.tenantProfiles)
        .doc(uid)
        .get();
    if (!snap.exists) return null;
    return TenantProfileDoc.fromSnapshot(snap);
  }

  /// Only listings a tenant could actually book: available and admin-
  /// verified. Matches the composite index already declared in
  /// firestore.indexes.json (isAvailable, isVerified, monthlyRent).
  Future<List<PropertyDoc>> fetchAvailableVerifiedProperties() async {
    final snap = await _firestore
        .collection(FirestoreCollections.properties)
        .where('isAvailable', isEqualTo: true)
        .where('isVerified', isEqualTo: true)
        .get();
    return snap.docs.map(PropertyDoc.fromSnapshot).toList();
  }

  /// This tenant's eligible (bScore = 1) matches — covered by the existing
  /// (tenantId, bScore, tenantCi) composite index in firestore.indexes.json.
  Future<List<MatchDoc>> fetchEligibleMatches(String tenantId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.matches)
        .where('tenantId', isEqualTo: tenantId)
        .where('bScore', isEqualTo: 1)
        .get();
    return snap.docs.map(MatchDoc.fromSnapshot).toList();
  }

  /// Individual gets rather than a single `whereIn` — Firestore caps
  /// `whereIn` at 30 values, which a tenant's eligible-property count could
  /// plausibly exceed even at alpha scale.
  Future<Map<String, PropertyDoc>> fetchPropertiesByIds(
    Set<String> propertyIds,
  ) async {
    final entries = await Future.wait(
      propertyIds.map((id) async {
        final snap = await _firestore
            .collection(FirestoreCollections.properties)
            .doc(id)
            .get();
        return snap.exists ? MapEntry(id, PropertyDoc.fromSnapshot(snap)) : null;
      }),
    );
    return Map.fromEntries(entries.whereType<MapEntry<String, PropertyDoc>>());
  }

  /// Firestore batches cap at 500 writes; chunk defensively even though a
  /// single tenant's candidate pool is unlikely to approach that at alpha
  /// scale.
  static const _maxBatchSize = 450;

  /// Partial update — only tenantCi/tenantRank change, so the pairing and
  /// bilateral scores FilteringService wrote are left untouched (and the
  /// `matches.update` security rule, which forbids those fields from
  /// changing, is satisfied automatically).
  Future<void> writeTopsisResults(List<TopsisResult> results) async {
    final collection = _firestore.collection(FirestoreCollections.matches);
    for (var i = 0; i < results.length; i += _maxBatchSize) {
      final batch = _firestore.batch();
      for (final result in results.skip(i).take(_maxBatchSize)) {
        batch.update(collection.doc(result.matchId), {
          'tenantCi': result.ci,
          'tenantRank': result.rank,
        });
      }
      await batch.commit();
    }
  }

  Future<void> writeFilterResults({
    required String tenantId,
    required List<MatchDoc> eligibleMatches,
    required List<String> ineligiblePropertyIds,
  }) async {
    final collection = _firestore.collection(FirestoreCollections.matches);
    final ops = <void Function(WriteBatch)>[
      for (final match in eligibleMatches)
        (batch) => batch.set(
          collection.doc(match.matchId),
          match.toMap(),
          SetOptions(merge: true),
        ),
      for (final propertyId in ineligiblePropertyIds)
        (batch) => batch.delete(collection.doc('${tenantId}_$propertyId')),
    ];

    for (var i = 0; i < ops.length; i += _maxBatchSize) {
      final batch = _firestore.batch();
      final chunk = ops.skip(i).take(_maxBatchSize);
      for (final op in chunk) {
        op(batch);
      }
      await batch.commit();
    }
  }
}
