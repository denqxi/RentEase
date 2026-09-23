import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/tenant_profile_doc.dart';

/// Raw Firestore access for `tenantProfiles/{uid}`.
class TenantProfileRemoteDataSource {
  TenantProfileRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestoreCollections.tenantProfiles).doc(uid);

  /// Merge-writes so a later partial update (e.g. from the Profile edit
  /// screens) never wipes fields it didn't touch.
  Future<void> setProfile(TenantProfileDoc profile) {
    return _doc(profile.userId).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<TenantProfileDoc?> getProfile(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return TenantProfileDoc.fromSnapshot(snap);
  }
}
