import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';

class FindTenantsRemoteDataSource {
  FindTenantsRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Covered by the (ownerId, createdAt desc) index in firestore.indexes.json.
  Future<List<PropertyDoc>> fetchOwnerProperties(String ownerId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.properties)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(PropertyDoc.fromSnapshot).toList();
  }

  /// Equality-only filters — no composite index needed. The `ownerId`
  /// filter is also what lets the `matches` read rule accept the query.
  Future<List<MatchDoc>> fetchEligibleMatches({
    required String ownerId,
    required String propertyId,
  }) async {
    final snap = await _firestore
        .collection(FirestoreCollections.matches)
        .where('ownerId', isEqualTo: ownerId)
        .where('propertyId', isEqualTo: propertyId)
        .where('bScore', isEqualTo: 1)
        .get();
    return snap.docs.map(MatchDoc.fromSnapshot).toList();
  }

  Future<UserDoc?> fetchUser(String uid) async {
    final snap =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    return snap.exists ? UserDoc.fromSnapshot(snap) : null;
  }

  Future<TenantProfileDoc?> fetchTenantProfile(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.tenantProfiles)
        .doc(uid)
        .get();
    return snap.exists ? TenantProfileDoc.fromSnapshot(snap) : null;
  }
}
