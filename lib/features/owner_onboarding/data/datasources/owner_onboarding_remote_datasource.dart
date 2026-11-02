import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../../uploads/domain/entities/uploaded_image.dart';
import '../../domain/entities/owner_credentials.dart';

class OwnerOnboardingRemoteDataSource {
  OwnerOnboardingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ownerProfile(String uid) =>
      _firestore.collection(FirestoreCollections.ownerProfiles).doc(uid);

  Future<String> submitForVerification(
    String uid, {
    List<UploadedImage> documents = const [],
    UploadedImage? businessPermit,
    UploadedImage? ownershipDocument,
    String? diditSessionId,
    String idSource = 'upload',
  }) async {
    final ref = _ownerProfile(uid);
    final snap = await ref.get();
    final current = snap.data()?['verificationStatus'] as String?;
    if (current == 'verified' || current == 'pending') return current!;

    // Documents are uploaded to Cloudinary (Firebase Storage needs Blaze);
    // only their URLs/public_ids are stored. The status transition is what
    // gates listing.
    // Links go to the private subdocument (owner/admin read only); the
    // world-readable ownerProfiles doc carries only the status.
    final data = <String, dynamic>{
      'verificationStatus': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (snap.exists && snap.data()?['rejectionReason'] != null)
        'rejectionReason': FieldValue.delete(),
    };
    final privateRef = ref
        .collection(FirestoreCollections.ownerPrivate)
        .doc(FirestoreCollections.ownerPrivateDocuments);
    final batch = _firestore.batch();
    if (snap.exists) {
      batch.update(ref, data);
    } else {
      batch.set(ref, data);
    }
    batch.set(privateRef, {
      'documentUrls': [for (final d in documents) d.url],
      'documentPublicIds': [for (final d in documents) d.publicId],
      // Didit session only; the admin screen asks Didit for the result
      // directly, so the owner can't claim a pass.
      'diditSessionId': ?diditSessionId,
      // 'didit': ID checked by Didit, documentUrls = [ownership, permit?].
      // 'upload': documentUrls = [ID front, ID back, ownership, permit?].
      'idSource': idSource,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    // The business permit and ownership document are also copied to
    // tenant-readable docs, shown on the owner's profile once they are
    // verified and turn on "Show credentials". The ID never goes here.
    // A resubmission without one clears the old copy.
    void share(String docId, UploadedImage? image) {
      final docRef = ref.collection(FirestoreCollections.ownerPublic).doc(docId);
      if (image != null) {
        batch.set(docRef, {
          'url': image.url,
          'publicId': image.publicId,
          'submittedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.delete(docRef);
      }
    }

    share(FirestoreCollections.ownerPublicBusinessPermit, businessPermit);
    share(FirestoreCollections.ownerPublicOwnershipDocument, ownershipDocument);
    await batch.commit();
    return 'pending';
  }

  /// The documents [ownerId] shares with tenants. Both are null when the
  /// owner isn't verified or hasn't turned on "Show credentials"
  /// (firestore.rules deny the reads then).
  Future<OwnerCredentials> fetchCredentials(String ownerId) async {
    Future<String?> url(String docId) async {
      try {
        final snap = await _ownerProfile(ownerId)
            .collection(FirestoreCollections.ownerPublic)
            .doc(docId)
            .get();
        return snap.data()?['url'] as String?;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') return null;
        rethrow;
      }
    }

    final results = await Future.wait([
      url(FirestoreCollections.ownerPublicBusinessPermit),
      url(FirestoreCollections.ownerPublicOwnershipDocument),
    ]);
    return OwnerCredentials(
      businessPermitUrl: results[0],
      ownershipDocumentUrl: results[1],
    );
  }

  Future<void> setShowCredentials(String uid, bool value) async {
    await _ownerProfile(uid).update({
      'showCredentials': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (value) await syncSharedCredentials(uid);
  }

  /// Copies the business permit and ownership document from the owner's
  /// private (admin-reviewed) documents to the tenant-readable docs. Needed
  /// for owners who submitted before sharing existed; firestore.rules only
  /// accept links that are already in the private documents.
  Future<void> syncSharedCredentials(String uid) async {
    final snap = await _ownerProfile(uid)
        .collection(FirestoreCollections.ownerPrivate)
        .doc(FirestoreCollections.ownerPrivateDocuments)
        .get();
    final data = snap.data();
    if (data == null) return;
    final urls = [
      for (final u in (data['documentUrls'] as List? ?? const []))
        if (u is String) u,
    ];
    final ids = [
      for (final i in (data['documentPublicIds'] as List? ?? const []))
        if (i is String) i,
    ];
    // Same layout the admin screen reads: Didit = [ownership, permit?];
    // upload = [ID front, ID back, ownership, permit?] (older 2-document
    // submissions: [ID, ownership]).
    final int ownershipAt;
    final int permitAt;
    if (data['idSource'] == 'didit') {
      (ownershipAt, permitAt) = (0, 1);
    } else if (urls.length >= 3) {
      (ownershipAt, permitAt) = (2, 3);
    } else {
      (ownershipAt, permitAt) = (1, -1);
    }

    final batch = _firestore.batch();
    void share(String docId, int index) {
      final docRef = _ownerProfile(
        uid,
      ).collection(FirestoreCollections.ownerPublic).doc(docId);
      if (index >= 0 && index < urls.length) {
        batch.set(docRef, {
          'url': urls[index],
          'publicId': index < ids.length ? ids[index] : '',
          'submittedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.delete(docRef);
      }
    }

    share(FirestoreCollections.ownerPublicOwnershipDocument, ownershipAt);
    share(FirestoreCollections.ownerPublicBusinessPermit, permitAt);
    await batch.commit();
  }

  Stream<String> watchVerificationStatus(String uid) => _ownerProfile(uid)
      .snapshots()
      .map((s) => s.data()?['verificationStatus'] as String? ?? 'none');

  Stream<OwnerProfileDoc?> watchOwnerProfile(String uid) => _ownerProfile(uid)
      .snapshots()
      .map((s) => s.exists ? OwnerProfileDoc.fromSnapshot(s) : null);

  Future<String> createProperty(PropertyDoc property) async {
    final ref = _firestore.collection(FirestoreCollections.properties).doc();
    // Oct 2026: listings are live immediately, verified or not. `isVerified`
    // is only the badge flag; it mirrors the owner's real status, never the
    // client's claim — the rules reject `true` from anyone else anyway.
    final profile = await _ownerProfile(property.ownerId).get();
    final verified = profile.data()?['verificationStatus'] == 'verified';
    await ref.set({...property.toMap(), 'isVerified': verified});
    return ref.id;
  }

  Future<List<PropertyDoc>> fetchOwnerProperties(String ownerId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.properties)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return [for (final d in snap.docs) PropertyDoc.fromSnapshot(d)];
  }
}

