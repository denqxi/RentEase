import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../domain/repositories/owner_property_repository.dart';

class OwnerPropertyRepositoryImpl implements OwnerPropertyRepository {
  OwnerPropertyRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Covered by the (ownerId, createdAt desc) index in firestore.indexes.json.
  @override
  Stream<List<PropertyDoc>> watchOwnerProperties(String ownerId) => _firestore
      .collection(FirestoreCollections.properties)
      .where('ownerId', isEqualTo: ownerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PropertyDoc.fromSnapshot).toList());

  @override
  Stream<String> watchVerificationStatus(String ownerId) => _firestore
      .collection(FirestoreCollections.ownerProfiles)
      .doc(ownerId)
      .snapshots()
      .map((s) => s.data()?['verificationStatus'] as String? ?? 'none');

  @override
  Future<UserDoc?> fetchUser(String uid) async {
    final snap =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    return snap.exists ? UserDoc.fromSnapshot(snap) : null;
  }

  @override
  Future<void> publishListings(Iterable<String> propertyIds) async {
    final batch = _firestore.batch();
    for (final id in propertyIds) {
      batch.update(
        _firestore.collection(FirestoreCollections.properties).doc(id),
        {'isVerified': true, 'updatedAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  @override
  Stream<int> watchOpenInquiryCount(String ownerId) => _firestore
      .collection(FirestoreCollections.inquiries)
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map(
        (s) => s.docs.where((d) {
          final status = d.data()['status'];
          return status == 'pending' || status == 'active';
        }).length,
      );

  @override
  Future<void> updateProperty(
    String propertyId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _firestore
          .collection(FirestoreCollections.properties)
          .doc(propertyId)
          .update({...fields, 'updatedAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      throw Exception(ownerPropertyErrorMessage(e.code, fields));
    }
  }
}
