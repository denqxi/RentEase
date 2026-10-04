import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';

class InquiryRemoteDataSource {
  InquiryRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _inquiries =>
      _firestore.collection(FirestoreCollections.inquiries);

  CollectionReference<Map<String, dynamic>> _messages(String inquiryId) =>
      _inquiries.doc(inquiryId).collection(FirestoreCollections.messages);

  Future<InquiryDoc?> findTenantInquiryForMatch({
    required String tenantId,
    required String matchId,
  }) async {
    final snap = await _inquiries
        .where('tenantId', isEqualTo: tenantId)
        .where('matchId', isEqualTo: matchId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return InquiryDoc.fromSnapshot(snap.docs.first);
  }

  Future<MatchDoc?> fetchMatch(String matchId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.matches)
        .doc(matchId)
        .get();
    return snap.exists ? MatchDoc.fromSnapshot(snap) : null;
  }

  Future<List<MatchDoc>> fetchCompatibleMatchesWithTenant({
    required String ownerId,
    required String tenantId,
  }) async {
    final snap = await _firestore
        .collection(FirestoreCollections.matches)
        .where('ownerId', isEqualTo: ownerId)
        .where('tenantId', isEqualTo: tenantId)
        .where('bScore', isEqualTo: 1)
        .get();
    return snap.docs.map(MatchDoc.fromSnapshot).toList();
  }

  Future<List<InquiryDoc>> fetchInquiriesBetween({
    required String ownerId,
    required String tenantId,
  }) async {
    final snap = await _inquiries
        .where('ownerId', isEqualTo: ownerId)
        .where('tenantId', isEqualTo: tenantId)
        .get();
    return snap.docs.map(InquiryDoc.fromSnapshot).toList();
  }

  Future<void> createInquiry(InquiryDoc inquiry) =>
      _inquiries.doc(inquiry.inquiryId).set(inquiry.toMap());

  Future<void> updateInquiry(String inquiryId, Map<String, dynamic> fields) =>
      _inquiries.doc(inquiryId).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<List<InquiryDoc>> fetchOpenInquiriesForProperty({
    required String ownerId,
    required String propertyId,
  }) async {
    // ownerId in the query is what lets the inquiries read rule accept it.
    final snap = await _inquiries
        .where('ownerId', isEqualTo: ownerId)
        .where('propertyId', isEqualTo: propertyId)
        .get();
    return snap.docs
        .map(InquiryDoc.fromSnapshot)
        .where((i) => i.status == 'pending' || i.status == 'active')
        .toList();
  }

  Future<void> commitBooking({
    required String inquiryId,
    required String propertyId,
    required bool fillsLastVacancy,
    required List<String> otherInquiryIds,
  }) {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    batch.update(_inquiries.doc(inquiryId), {
      'status': 'booked',
      'updatedAt': now,
    });
    if (fillsLastVacancy) {
      batch.update(
        _firestore.collection(FirestoreCollections.properties).doc(propertyId),
        {'vacancyStatus': 'booked', 'isAvailable': false, 'updatedAt': now},
      );
      for (final id in otherInquiryIds) {
        batch.update(_inquiries.doc(id), {'status': 'closed', 'updatedAt': now});
      }
    }
    return batch.commit();
  }

  Stream<InquiryDoc?> watchInquiry(String inquiryId) => _inquiries
      .doc(inquiryId)
      .snapshots()
      .map((s) => s.exists ? InquiryDoc.fromSnapshot(s) : null);

  // Equality-only queries (no orderBy) so no composite index is needed;
  // callers sort by updatedAt client-side.
  Stream<List<InquiryDoc>> watchTenantInquiries(String tenantId) => _inquiries
      .where('tenantId', isEqualTo: tenantId)
      .snapshots()
      .map((s) => s.docs.map(InquiryDoc.fromSnapshot).toList());

  Stream<List<InquiryDoc>> watchOwnerInquiries(String ownerId) => _inquiries
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) => s.docs.map(InquiryDoc.fromSnapshot).toList());

  Stream<List<MessageDoc>> watchMessages(String inquiryId) =>
      _messages(inquiryId).snapshots().map(
        (s) => s.docs.map(MessageDoc.fromSnapshot).toList(),
      );

  Future<void> addMessage(String inquiryId, MessageDoc message) =>
      _messages(inquiryId).add(message.toMap());

  // Deterministic ID (one rating per inquiry + rater): a double-tap that slips
  // past the hasRated check becomes an update, which firestore.rules deny.
  Future<void> createRating(RatingDoc rating) => _firestore
      .collection(FirestoreCollections.ratings)
      .doc('${rating.inquiryId}_${rating.raterId}')
      .set(rating.toMap());

  Future<bool> hasRated({
    required String inquiryId,
    required String raterId,
  }) async {
    final snap = await _firestore
        .collection(FirestoreCollections.ratings)
        .where('inquiryId', isEqualTo: inquiryId)
        .where('raterId', isEqualTo: raterId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  DocumentReference<Map<String, dynamic>> _share(String inquiryId, String role) =>
      _inquiries
          .doc(inquiryId)
          .collection(FirestoreCollections.inquiryContact)
          .doc(role);

  Future<UserContactDoc?> fetchOwnContact(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.userPrivate)
        .doc(FirestoreCollections.userContact)
        .get();
    return snap.exists ? UserContactDoc.fromSnapshot(snap) : null;
  }

  Future<ContactShareDoc?> fetchContactShare(String inquiryId, String role) async {
    final snap = await _share(inquiryId, role).get();
    return snap.exists ? ContactShareDoc.fromSnapshot(snap) : null;
  }

  Stream<ContactShareDoc?> watchContactShare(String inquiryId, String role) =>
      _share(inquiryId, role).snapshots().map(
        (s) => s.exists ? ContactShareDoc.fromSnapshot(s) : null,
      );

  Future<void> writeContactShare(
    String inquiryId,
    String role,
    ContactShareDoc share,
  ) => _share(inquiryId, role).set(share.toMap());

  Future<PropertyDoc?> fetchProperty(String propertyId) async {
    final snap = await _firestore
        .collection(FirestoreCollections.properties)
        .doc(propertyId)
        .get();
    return snap.exists ? PropertyDoc.fromSnapshot(snap) : null;
  }

  Future<UserDoc?> fetchUser(String uid) async {
    final snap =
        await _firestore.collection(FirestoreCollections.users).doc(uid).get();
    return snap.exists ? UserDoc.fromSnapshot(snap) : null;
  }

  Future<TenantProfileDoc?> fetchTenantProfile(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.tenantProfiles)
        .doc(uid)
        .get();
    return snap.exists ? TenantProfileDoc.fromSnapshot(snap) : null;
  }

  Future<OwnerProfileDoc?> fetchOwnerProfile(String uid) async {
    final snap = await _firestore
        .collection(FirestoreCollections.ownerProfiles)
        .doc(uid)
        .get();
    return snap.exists ? OwnerProfileDoc.fromSnapshot(snap) : null;
  }
}
