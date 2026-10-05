import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../../home/model/listing.dart';
import '../../domain/repositories/saved_listings_repository.dart';

class SavedListingsRepositoryImpl implements SavedListingsRepository {
  SavedListingsRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _whereInLimit = 30;

  CollectionReference<Map<String, dynamic>> _saved(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.savedListings);

  @override
  Stream<Set<String>> watchSavedIds(String uid) =>
      _saved(uid).snapshots().map((s) => {for (final d in s.docs) d.id});

  @override
  Future<void> save(String uid, String propertyId) => _saved(uid)
      .doc(propertyId)
      .set({'propertyId': propertyId, 'savedAt': FieldValue.serverTimestamp()});

  @override
  Future<void> unsave(String uid, String propertyId) =>
      _saved(uid).doc(propertyId).delete();

  @override
  Future<List<Listing>> fetchSavedListings(List<String> propertyIds) async {
    final byId = <String, PropertyDoc>{};
    for (var i = 0; i < propertyIds.length; i += _whereInLimit) {
      final chunk = propertyIds.sublist(
        i,
        i + _whereInLimit > propertyIds.length
            ? propertyIds.length
            : i + _whereInLimit,
      );
      final snap = await _firestore
          .collection(FirestoreCollections.properties)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        final p = PropertyDoc.fromSnapshot(d);
        if (p.isAvailable) byId[p.propertyId] = p;
      }
    }
    return [
      for (final (i, id) in propertyIds.indexed)
        if (byId[id] case final p?)
          Listing.fromProperty(
            property: p,
            imageSeed: i % 5 + 1,
          ).copyWith(isSaved: true),
    ];
  }
}
