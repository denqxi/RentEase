import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/firestore/firestore_collections.dart';
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

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Reloads the current Firebase user and returns the fresh instance
  /// (reload() mutates in place, so re-read `currentUser` afterwards).
  Future<fb.User?> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  Future<void> createUserDoc(UserDoc doc) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(doc.userId)
        .set(doc.toMap());
  }

  Future<UserDoc?> fetchUserDoc(String uid) async {
    final snap =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    if (!snap.exists) return null;
    return UserDoc.fromSnapshot(snap);
  }

  Future<void> touchLastLogin(String uid) {
    return _firestore.collection(FirestoreCollections.users).doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }
}
