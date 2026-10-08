import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/tenant_private_prefs_doc.dart';
import '../../../../core/firestore/models/user_contact_doc.dart';
import '../../../../core/firestore/tenant_profile_loader.dart';
import '../../../../core/firestore/models/user_doc.dart';

/// Thin wrapper around the Firebase Auth + Firestore SDKs. No business
/// logic lives here — [AuthRepositoryImpl] maps results/errors.
class AuthRemoteDataSource {
  AuthRemoteDataSource({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  fb.User? get currentFirebaseUser => _auth.currentUser;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<fb.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<fb.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  /// Deletes the signed-in user's profile docs, then the Auth account itself
  /// (frees the email). Profile docs go first: once the Auth user is gone
  /// the rules no longer let us delete them.
  Future<void> deleteCurrentAccountAndProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userRef =
        _firestore.collection(FirestoreCollections.users).doc(user.uid);
    try {
      final batch = _firestore.batch();
      batch.delete(_contactRef(user.uid));
      batch.delete(userRef);
      await batch.commit();
    } on FirebaseException {
      // A half-created signup may have no profile doc (rules can't evaluate
      // a delete on it); only fail when a doc is really still there.
      if ((await userRef.get()).exists) rethrow;
    }
    await user.delete();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Reloads the current Firebase user and returns the fresh instance
  /// (reload() mutates in place, so re-read `currentUser` afterwards).
  ///
  /// Also force-refreshes the ID token: `firestore.rules` gates inquiries,
  /// chat, ratings and listings on the token's `email_verified` claim, which
  /// otherwise stays false for up to an hour after the user verifies.
  Future<fb.User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    await user?.reload();
    final reloaded = _auth.currentUser;
    if (reloaded != null && reloaded.emailVerified) {
      try {
        await reloaded.getIdToken(true);
      } catch (_) {
        // Best effort: the claim refreshes on the next automatic token renewal.
      }
    }
    return reloaded;
  }

  DocumentReference<Map<String, dynamic>> _contactRef(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.userPrivate)
      .doc(FirestoreCollections.userContact);

  /// Writes the public users doc and the private contact doc (email + phone)
  /// in one batch; email/phone are never written to users/{uid}.
  Future<void> createUserDoc(UserDoc doc, {required UserContactDoc contact}) {
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection(FirestoreCollections.users).doc(doc.userId),
      doc.toMap(),
    );
    batch.set(_contactRef(doc.userId), contact.toMap());
    return batch.commit();
  }

  /// Self-migration of a pre-privacy account: copies the legacy `phone` /
  /// `email` still on users/{uid} into users/{uid}/private/contact and
  /// deletes them from the public doc, in one batch. Idempotent (merge +
  /// field delete); only non-empty legacy values overwrite the private doc.
  Future<void> migrateLegacyContact(UserDoc doc) {
    final batch = _firestore.batch();
    final moved = <String, dynamic>{
      if (doc.phone.isNotEmpty) 'phone': doc.phone,
      if (doc.email.isNotEmpty) 'email': doc.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.set(_contactRef(doc.userId), moved, SetOptions(merge: true));
    batch.update(
      _firestore.collection(FirestoreCollections.users).doc(doc.userId),
      {'phone': FieldValue.delete(), 'email': FieldValue.delete()},
    );
    return batch.commit();
  }

  /// Self-migration of a tenant's legacy `tenantProfiles.emergencyContact`
  /// into users/{uid}/private/contact, deleting it from the profile in the
  /// same batch. Idempotent: does nothing when the field is absent/empty
  /// (an empty legacy value is just deleted).
  Future<void> migrateLegacyEmergencyContact(String uid) async {
    final profileRef =
        _firestore.collection(FirestoreCollections.tenantProfiles).doc(uid);
    final snap = await profileRef.get();
    final data = snap.data();
    if (data == null || !data.containsKey('emergencyContact')) return;
    final value = (data['emergencyContact'] as String?)?.trim() ?? '';
    final batch = _firestore.batch();
    if (value.isNotEmpty) {
      batch.set(
        _contactRef(uid),
        {
          'emergencyContact': value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    batch.update(profileRef, {'emergencyContact': FieldValue.delete()});
    await batch.commit();
  }

  /// Self-migration of a tenant's legacy map pin + TOPSIS weights from
  /// `tenantProfiles/{uid}` into `tenantProfiles/{uid}/private/prefs`,
  /// deleting them from the (owner-readable) profile in the same batch.
  /// Idempotent: does nothing once the profile holds none of the legacy
  /// fields, and an existing prefs value is never overwritten.
  Future<void> migrateLegacyTenantPrefs(String uid) async {
    final profileRef =
        _firestore.collection(FirestoreCollections.tenantProfiles).doc(uid);
    final data = (await profileRef.get()).data();
    if (data == null || !TenantPrivatePrefsDoc.hasLegacyFields(data)) return;
    final prefsRef = tenantPrefsRef(_firestore, uid);
    final existing = (await prefsRef.get()).data() ?? const <String, dynamic>{};
    final plan = TenantPrivatePrefsDoc.legacyMigrationPlan(data, existing);
    final batch = _firestore.batch();
    if (plan.copy.isNotEmpty) {
      batch.set(prefsRef, {
        ...plan.copy,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    batch.update(profileRef, {
      for (final key in plan.remove) key: FieldValue.delete(),
    });
    await batch.commit();
  }

  Future<UserDoc?> fetchUserDoc(String uid) async {
    final snap =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (!snap.exists) return null;
    return UserDoc.fromSnapshot(snap);
  }

  /// Emits the user's `status` whenever their users doc changes; errors
  /// (e.g. after sign-out) end the stream quietly.
  Stream<String?> watchUserStatus(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()?['status'] as String?)
      .handleError((_) {});

  Future<void> touchLastLogin(String uid) {
    return _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }
}
