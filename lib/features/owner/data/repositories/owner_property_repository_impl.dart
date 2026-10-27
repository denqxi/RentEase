import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../../../core/firestore/property_ratings_aggregator.dart';
import '../../domain/repositories/owner_property_repository.dart';

class OwnerPropertyRepositoryImpl implements OwnerPropertyRepository {
  OwnerPropertyRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Equality-only query (no orderBy) so no composite index is needed.
  /// Properties are sorted by createdAt descending in memory.
  @override
  Stream<List<PropertyDoc>> watchOwnerProperties(String ownerId) => _firestore
      .collection(FirestoreCollections.properties)
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .asyncMap((s) async {
        final list = <PropertyDoc>[];
        for (final doc in s.docs) {
          try {
            list.add(PropertyDoc.fromSnapshot(doc));
          } catch (e, stack) {
            debugPrint('Failed to parse property doc ${doc.id}: $e\n$stack');
          }
        }
        list.sort((a, b) {
          final at = a.createdAt;
          final bt = b.createdAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });
        return PropertyRatingsAggregator.hydrateProperties(_firestore, list);
      });

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

  @override
  Future<void> deleteProperty(String propertyId) async {
    try {
      final docRef = _firestore
          .collection(FirestoreCollections.properties)
          .doc(propertyId);
      final roomsSnap = await docRef.collection('rooms').get();
      for (final roomDoc in roomsSnap.docs) {
        await roomDoc.reference.delete();
      }
      await docRef.delete();
    } on FirebaseException catch (e) {
      throw Exception(ownerPropertyErrorMessage(e.code, const {}));
    }
  }
}
