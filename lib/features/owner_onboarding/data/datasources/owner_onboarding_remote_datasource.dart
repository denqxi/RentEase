import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../../uploads/domain/entities/uploaded_image.dart';

class OwnerOnboardingRemoteDataSource {
  OwnerOnboardingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ownerProfile(String uid) =>
      _firestore.collection(FirestoreCollections.ownerProfiles).doc(uid);

  Future<String> submitForVerification(
    String uid, {
    List<UploadedImage> documents = const [],
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
      'submittedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return 'pending';
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

