import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../../../core/firestore/tenant_profile_loader.dart';

/// Raw Firestore access for `tenantProfiles/{uid}`.
class TenantProfileRemoteDataSource {
  TenantProfileRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestoreCollections.tenantProfiles).doc(uid);

  /// Merge-writes so a later partial update (e.g. from the Profile edit
  /// screens) never wipes fields it didn't touch. The public profile and the
  /// private prefs (map pin + weights) are written in ONE batch, and any
  /// legacy private fields still on the public doc are deleted with it.
  Future<void> setProfile(TenantProfileDoc profile) {
    final batch = _firestore.batch();
    batch.set(
      _doc(profile.userId),
      {
        ...profile.toMap(),
        for (final key in TenantPrivatePrefsDoc.legacyProfileKeys)
          key: FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      tenantPrefsRef(_firestore, profile.userId),
      profile.toPrefs().toMap(),
      SetOptions(merge: true),
    );
    return batch.commit();
  }

  /// Merge-writes only [fields] (plus updatedAt) of the private prefs doc.
  Future<void> updatePrefs(String uid, Map<String, dynamic> fields) {
    return tenantPrefsRef(_firestore, uid).set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Partial update — touches only [fields] (plus updatedAt), so an edit
  /// screen can never clobber anything it doesn't own.
  Future<void> updateFields(String uid, Map<String, dynamic> fields) {
    return _doc(uid).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// The tenant's own profile merged with their private prefs.
  Future<TenantProfileDoc?> getProfile(String uid) =>
      loadOwnTenantProfile(_firestore, uid);
}
