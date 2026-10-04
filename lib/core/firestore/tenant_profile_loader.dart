import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_collections.dart';
import 'models/models.dart';

/// Reference to a tenant's private prefs doc
/// (`tenantProfiles/{uid}/private/prefs`).
DocumentReference<Map<String, dynamic>> tenantPrefsRef(
  FirebaseFirestore firestore,
  String uid,
) => firestore
    .collection(FirestoreCollections.tenantProfiles)
    .doc(uid)
    .collection(FirestoreCollections.tenantPrivate)
    .doc(FirestoreCollections.tenantPrefs);

/// Loads the SIGNED-IN tenant's own profile merged with their private prefs
/// (map pin + weights). Only valid for the tenant themselves: owners cannot
/// read the prefs doc (firestore.rules), so owner-side screens must read
/// `tenantProfiles` directly instead. A missing or unreadable prefs doc
/// leaves the legacy fields (pre-migration) in place.
Future<TenantProfileDoc?> loadOwnTenantProfile(
  FirebaseFirestore firestore,
  String uid,
) async {
  final profileSnap = await firestore
      .collection(FirestoreCollections.tenantProfiles)
      .doc(uid)
      .get();
  if (!profileSnap.exists) return null;
  final profile = TenantProfileDoc.fromSnapshot(profileSnap);
  try {
    final prefsSnap = await tenantPrefsRef(firestore, uid).get();
    if (!prefsSnap.exists) return profile;
    return profile.withPrefs(TenantPrivatePrefsDoc.fromSnapshot(prefsSnap));
  } on FirebaseException {
    return profile;
  }
}
