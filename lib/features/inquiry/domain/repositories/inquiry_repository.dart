import '../../../../core/firestore/models/models.dart';

/// Firestore access for the structured two-phase inquiry flow
/// (`inquiries/{id}` + `inquiries/{id}/messages`). Business rules — who may
/// do what, and when — live in `InquiryService`, not here.
abstract class InquiryRepository {
  /// The tenant's existing inquiry for [matchId], if any (queried, not a
  /// direct get — the read rule needs `tenantId` in the query to accept it).
  Future<InquiryDoc?> findTenantInquiryForMatch({
    required String tenantId,
    required String matchId,
  });

  Future<MatchDoc?> fetchMatch(String matchId);

  /// Creates the inquiry with [InquiryDoc.inquiryId] as its document ID.
  Future<void> createInquiry(InquiryDoc inquiry);

  Future<void> updateInquiry(String inquiryId, Map<String, dynamic> fields);

  /// This owner's inquiries for one property that are still open (not
  /// booked / declined / closed).
  Future<List<InquiryDoc>> fetchOpenInquiriesForProperty({
    required String ownerId,
    required String propertyId,
  });

  /// Atomically marks [inquiryId] booked. When [fillsLastVacancy], the same
  /// batch also takes [propertyId] off the market and closes
  /// [otherInquiryIds] — all or nothing.
  Future<void> commitBooking({
    required String inquiryId,
    required String propertyId,
    required bool fillsLastVacancy,
    required List<String> otherInquiryIds,
  });

  Stream<InquiryDoc?> watchInquiry(String inquiryId);

  Stream<List<InquiryDoc>> watchTenantInquiries(String tenantId);

  Stream<List<InquiryDoc>> watchOwnerInquiries(String ownerId);

  Stream<List<MessageDoc>> watchMessages(String inquiryId);

  Future<void> addMessage(String inquiryId, MessageDoc message);

  Future<void> createRating(RatingDoc rating);

  /// Whether [raterId] already rated this inquiry.
  Future<bool> hasRated({required String inquiryId, required String raterId});

  // ── Enrichment reads for display ────────────────────────────────────────

  Future<PropertyDoc?> fetchProperty(String propertyId);

  Future<UserDoc?> fetchUser(String uid);

  Future<TenantProfileDoc?> fetchTenantProfile(String uid);

  Future<OwnerProfileDoc?> fetchOwnerProfile(String uid);
}
