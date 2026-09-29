import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/models/models.dart';
import '../../domain/repositories/inquiry_repository.dart';
import '../datasources/inquiry_remote_datasource.dart';

class InquiryRepositoryImpl implements InquiryRepository {
  InquiryRepositoryImpl({InquiryRemoteDataSource? remote})
    : _remote = remote ?? InquiryRemoteDataSource();

  final InquiryRemoteDataSource _remote;

  @override
  Future<InquiryDoc?> findTenantInquiryForMatch({
    required String tenantId,
    required String matchId,
  }) => _guard(
    () => _remote.findTenantInquiryForMatch(
      tenantId: tenantId,
      matchId: matchId,
    ),
  );

  @override
  Future<MatchDoc?> fetchMatch(String matchId) =>
      _guard(() => _remote.fetchMatch(matchId));

  @override
  Future<void> createInquiry(InquiryDoc inquiry) =>
      _guard(() => _remote.createInquiry(inquiry));

  @override
  Future<void> updateInquiry(String inquiryId, Map<String, dynamic> fields) =>
      _guard(() => _remote.updateInquiry(inquiryId, fields));

  @override
  Future<List<InquiryDoc>> fetchOpenInquiriesForProperty({
    required String ownerId,
    required String propertyId,
  }) => _guard(
    () => _remote.fetchOpenInquiriesForProperty(
      ownerId: ownerId,
      propertyId: propertyId,
    ),
  );

  @override
  Future<void> commitBooking({
    required String inquiryId,
    required String propertyId,
    required bool fillsLastVacancy,
    required List<String> otherInquiryIds,
  }) => _guard(
    () => _remote.commitBooking(
      inquiryId: inquiryId,
      propertyId: propertyId,
      fillsLastVacancy: fillsLastVacancy,
      otherInquiryIds: otherInquiryIds,
    ),
  );

  @override
  Stream<InquiryDoc?> watchInquiry(String inquiryId) =>
      _remote.watchInquiry(inquiryId);

  @override
  Stream<List<InquiryDoc>> watchTenantInquiries(String tenantId) =>
      _remote.watchTenantInquiries(tenantId);

  @override
  Stream<List<InquiryDoc>> watchOwnerInquiries(String ownerId) =>
      _remote.watchOwnerInquiries(ownerId);

  @override
  Stream<List<MessageDoc>> watchMessages(String inquiryId) =>
      _remote.watchMessages(inquiryId);

  @override
  Future<void> addMessage(String inquiryId, MessageDoc message) =>
      _guard(() => _remote.addMessage(inquiryId, message));

  @override
  Future<void> createRating(RatingDoc rating) =>
      _guard(() => _remote.createRating(rating));

  @override
  Future<bool> hasRated({required String inquiryId, required String raterId}) =>
      _guard(() => _remote.hasRated(inquiryId: inquiryId, raterId: raterId));

  @override
  Future<PropertyDoc?> fetchProperty(String propertyId) =>
      _guard(() => _remote.fetchProperty(propertyId));

  @override
  Future<UserDoc?> fetchUser(String uid) => _guard(() => _remote.fetchUser(uid));

  @override
  Future<TenantProfileDoc?> fetchTenantProfile(String uid) =>
      _guard(() => _remote.fetchTenantProfile(uid));

  @override
  Future<OwnerProfileDoc?> fetchOwnerProfile(String uid) =>
      _guard(() => _remote.fetchOwnerProfile(uid));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (e) {
      throw Exception(switch (e.code) {
        'permission-denied' =>
          "You don't have permission to do this. Inquiries are only open "
              'between compatible tenants and owners.',
        'unavailable' => 'Network error. Check your connection and try again.',
        _ => e.message ?? 'Something went wrong. Please try again.',
      });
    }
  }
}
