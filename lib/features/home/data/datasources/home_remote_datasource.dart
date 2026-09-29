import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Eligible matches for this tenant, ranked best-first. Ordered by
  /// tenantCi (not tenantRank) so this reuses the existing
  /// (tenantId, bScore, tenantCi) composite index — rank 1 and highest Ci
  /// are the same ordering by construction (TopsisService.computeCloseness).
  Future<List<MatchDoc>> fetchEligibleMatches(String tenantId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.matches)
        .where('tenantId', isEqualTo: tenantId)
        .where('bScore', isEqualTo: 1)
        .orderBy('tenantCi', descending: true)
        .get();
    return snap.docs.map(MatchDoc.fromSnapshot).toList();
  }

  Future<PropertyDoc?> fetchProperty(String propertyId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.properties)
        .doc(propertyId)
        .get();
    if (!snap.exists) return null;
    return PropertyDoc.fromSnapshot(snap);
  }

  Future<UserDoc?> fetchUser(String uid) async {
    final snap =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (!snap.exists) return null;
    return UserDoc.fromSnapshot(snap);
  }

  Future<OwnerProfileDoc?> fetchOwnerProfile(String ownerId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.ownerProfiles)
        .doc(ownerId)
        .get();
    if (!snap.exists) return null;
    return OwnerProfileDoc.fromSnapshot(snap);
  }
}
