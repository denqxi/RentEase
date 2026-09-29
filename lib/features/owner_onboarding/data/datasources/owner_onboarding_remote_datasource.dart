import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';

class OwnerOnboardingRemoteDataSource {
  OwnerOnboardingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ownerProfile(String uid) =>
      _firestore.collection(FirestoreCollections.ownerProfiles).doc(uid);

  Future<String> submitForVerification(String uid) async {
    final ref = _ownerProfile(uid);
    final snap = await ref.get();
    final current = snap.data()?['verificationStatus'] as String?;
    if (current == 'verified' || current == 'pending') return current!;
    if (current == 'rejected') {
      // The security rules only let an owner move none → pending; reopening
      // a rejected application is an admin action.
      throw Exception(
        'Your verification was not approved. Please contact support to '
        'resubmit your documents.',
      );
    }

    // No document files yet — Firebase Storage needs the Blaze plan on this
    // project, so `documentUrls` stays empty and the admin verifies the
    // owner out-of-band. The status transition is what gates listing.
    final data = <String, dynamic>{
      'verificationStatus': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (snap.exists) {
      await ref.update(data);
    } else {
      await ref.set({...data, 'documentUrls': <String>[]});
    }
    return 'pending';
  }

  Stream<String> watchVerificationStatus(String uid) => _ownerProfile(uid)
      .snapshots()
      .map((s) => s.data()?['verificationStatus'] as String? ?? 'none');

  Future<String> createProperty(PropertyDoc property) async {
    final ref = _firestore.collection(FirestoreCollections.properties).doc();
    await ref.set(property.toMap());
    return ref.id;
  }
}
