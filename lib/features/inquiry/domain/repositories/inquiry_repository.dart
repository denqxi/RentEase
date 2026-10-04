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

  /// Cached bScore = 1 match rows between this owner and [tenantId] (one per
  /// property). The `ownerId` filter is what lets the matches read rule
  /// accept the query.
  Future<List<MatchDoc>> fetchCompatibleMatchesWithTenant({
    required String ownerId,
    required String tenantId,
  });

  /// Every inquiry/invitation thread (any status) between this owner and
  /// tenant. Filtered on `ownerId` so the inquiries read rule accepts it.
  Future<List<InquiryDoc>> fetchInquiriesBetween({
    required String ownerId,
    required String tenantId,
  });

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

  // ── Contact sharing (after acceptance only) ─────────────────────────────

  /// The signed-in user's own private contact (`users/{uid}/private/contact`).
  Future<UserContactDoc?> fetchOwnContact(String uid);

  /// `inquiries/{id}/contact/{role}` ('tenant' | 'owner'), or null if that
  /// participant has not shared yet.
  Future<ContactShareDoc?> fetchContactShare(String inquiryId, String role);

  /// Live view of [role]'s share; emits null until it exists.
  Stream<ContactShareDoc?> watchContactShare(String inquiryId, String role);

  /// Writes the caller's OWN share (doc ID = their role). firestore.rules
  /// only allow this after the inquiry is accepted.
  Future<void> writeContactShare(
    String inquiryId,
    String role,
    ContactShareDoc share,
  );

  // ── Enrichment reads for display ────────────────────────────────────────

  Future<PropertyDoc?> fetchProperty(String propertyId);

  Future<UserDoc?> fetchUser(String uid);

  Future<TenantProfileDoc?> fetchTenantProfile(String uid);

  Future<OwnerProfileDoc?> fetchOwnerProfile(String uid);
}
