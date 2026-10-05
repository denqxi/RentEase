import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/firestore/firestore_collections.dart';
import '../../domain/repositories/account_deletion_repository.dart';

/// Firebase implementation of [AccountDeletionRepository]. Deletes are done
/// in small chunks (the rules read the users doc and, for rooms, the
/// property, so chunks stay well under the per-request access-call limit).
class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  AccountDeletionRepositoryImpl({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? fb.FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const int _chunk = 20;

  AccountDeletionFailure _map(Object e) {
    if (e is AccountDeletionFailure) return e;
    final code = switch (e) {
      fb.FirebaseAuthException(:final code) => code,
      FirebaseException(:final code) => code,
      _ => '',
    };
    return AccountDeletionFailure(switch (code) {
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' => AccountDeletionFailureKind.wrongPassword,
      'requires-recent-login' => AccountDeletionFailureKind.requiresRecentLogin,
      'network-request-failed' ||
      'unavailable' ||
      'deadline-exceeded' => AccountDeletionFailureKind.network,
      'too-many-requests' ||
      'permission-denied' => AccountDeletionFailureKind.denied,
      _ => AccountDeletionFailureKind.unknown,
    });
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      throw _map(e);
    }
  }

  Future<void> _deleteAll(Iterable<DocumentReference<Object?>> refs) async {
    final list = refs.toList();
    for (var i = 0; i < list.length; i += _chunk) {
      final batch = _db.batch();
      for (final ref in list.skip(i).take(_chunk)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> c,
  ) async {
    final snap = await c.get();
    await _deleteAll(snap.docs.map((d) => d.reference));
  }

  @override
  Future<void> reauthenticate(String password) => _guard(() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AccountDeletionFailure(AccountDeletionFailureKind.unknown);
    }
    await user.reauthenticateWithCredential(
      fb.EmailAuthProvider.credential(email: email, password: password),
    );
  });

  @override
  Future<void> closeOwnerOpenInquiries(String uid) async {
    try {
      final snap = await _db
          .collection(FirestoreCollections.inquiries)
          .where('ownerId', isEqualTo: uid)
          .get();
      for (final doc in snap.docs) {
        final status = doc.data()['status'];
        if (status != 'pending' && status != 'active') continue;
        try {
          await doc.reference.update({
            'status': 'closed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          // Best effort: rules may refuse (e.g. a rejected owner).
        }
      }
    } catch (_) {
      // Best effort only; never blocks the deletion.
    }
  }

  @override
  Future<void> deleteOwnerProperties(String uid) => _guard(() async {
    final props = await _db
        .collection(FirestoreCollections.properties)
        .where('ownerId', isEqualTo: uid)
        .get();
    for (final p in props.docs) {
      // Rooms first: their delete rule reads the (still existing) property.
      await _deleteCollection(
        p.reference.collection(FirestoreCollections.rooms),
      );
      await p.reference.delete();
    }
  });

  @override
  Future<void> deleteNotifications(String uid) => _guard(() async {
    final snap = await _db
        .collection(FirestoreCollections.notifications)
        .where('recipientId', isEqualTo: uid)
        .get();
    await _deleteAll(snap.docs.map((d) => d.reference));
  });

  @override
  Future<void> deleteTenantMatches(String uid) => _guard(() async {
    final snap = await _db
        .collection(FirestoreCollections.matches)
        .where('tenantId', isEqualTo: uid)
        .get();
    await _deleteAll(snap.docs.map((d) => d.reference));
  });

  @override
  Future<void> deleteSavedListings(String uid) => _guard(
    () => _deleteCollection(
      _db
          .collection(FirestoreCollections.users)
          .doc(uid)
          .collection(FirestoreCollections.savedListings),
    ),
  );

  @override
  Future<void> deleteTenantProfile(String uid) => _guard(() async {
    final ref = _db.collection(FirestoreCollections.tenantProfiles).doc(uid);
    await _deleteCollection(ref.collection(FirestoreCollections.tenantPrivate));
    await ref.delete();
  });

  @override
  Future<void> deleteOwnerProfile(String uid) => _guard(() async {
    final ref = _db.collection(FirestoreCollections.ownerProfiles).doc(uid);
    await _deleteCollection(ref.collection(FirestoreCollections.ownerPrivate));
    await ref.delete();
  });

  @override
  Future<void> deleteUserPrivate(String uid) => _guard(
    () => _deleteCollection(
      _db
          .collection(FirestoreCollections.users)
          .doc(uid)
          .collection(FirestoreCollections.userPrivate),
    ),
  );

  @override
  Future<void> deleteUserDoc(String uid) => _guard(
    () => _db.collection(FirestoreCollections.users).doc(uid).delete(),
  );

  @override
  Future<void> deleteAuthAccount() => _guard(() async {
    await _auth.currentUser?.delete();
  });

  @override
  Future<void> signOut() => _auth.signOut();
}
