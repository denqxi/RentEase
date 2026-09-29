import '../../../../core/firestore/models/models.dart';
import '../repositories/inquiry_repository.dart';

/// A rule the inquiry flow refused — the message is safe to show the user.
class InquiryException implements Exception {
  const InquiryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The structured two-phase inquiry (CLAUDE.md "Structured Two-Phase
/// Inquiry"):
///
/// - Phase 1 (`stage` 1): the tenant sends an inquiry for a bScore = 1
///   match. No free chat — both sides see an auto-generated summary
///   (rendered live from the property / tenant profile docs, not stored as
///   messages). The owner must Accept or Decline.
/// - Phase 2 (`stage` 2): after Accept, open chat. The owner can mark the
///   booking, after which both sides can rate each other.
///
/// Every check here is mirrored by firestore.rules — the rules are the real
/// enforcement (a modified client skips this class entirely); these checks
/// exist so the UI fails fast with a readable message instead of a
/// permission-denied.
class InquiryService {
  InquiryService({required InquiryRepository repository})
    : _repository = repository;

  final InquiryRepository _repository;

  // ── Pure rules (unit-tested directly) ───────────────────────────────────

  static bool isPhase1Pending(InquiryDoc i) =>
      i.stage == 1 && i.ownerDecision == 'pending' && i.status == 'pending';

  static bool canChat(InquiryDoc i) =>
      i.stage == 2 && i.ownerDecision == 'accepted' && i.status == 'active';

  static bool isResolved(InquiryDoc i) =>
      i.status == 'booked' || i.status == 'declined' || i.status == 'closed';

  /// The party the rater is rating: tenants rate the owner, owners rate the
  /// tenant.
  static String ratedIdFor(InquiryDoc i, {required bool raterIsOwner}) =>
      raterIsOwner ? i.tenantId : i.ownerId;

  // ── Phase 1 ─────────────────────────────────────────────────────────────

  /// Opens (or reopens) the tenant's inquiry for [matchId] and returns its
  /// ID. One inquiry per tenant–property pairing: the document ID is the
  /// match ID, and an existing open inquiry is reused rather than duplicated.
  Future<String> sendInquiry({
    required String tenantId,
    required String matchId,
  }) async {
    final existing = await _repository.findTenantInquiryForMatch(
      tenantId: tenantId,
      matchId: matchId,
    );
    if (existing != null) {
      if (existing.ownerDecision == 'declined') {
        throw const InquiryException(
          'The owner declined your earlier inquiry for this property.',
        );
      }
      if (existing.status == 'closed') {
        throw const InquiryException(
          'This listing is fully booked and no longer taking inquiries.',
        );
      }
      return existing.inquiryId;
    }

    final match = await _repository.fetchMatch(matchId);
    if (match == null || match.tenantId != tenantId || match.bScore != 1) {
      // CLAUDE.md: communication only after bilateral compatibility.
      throw const InquiryException(
        "You can only send inquiries to properties you're compatible with.",
      );
    }
    // The match row can outlive a booking until the tenant's next filtering
    // pass; firestore.rules checks this too, so it's not UI-only.
    final property = await _repository.fetchProperty(match.propertyId);
    if (property == null || !property.isAvailable) {
      throw const InquiryException(
        'This listing is fully booked and no longer taking inquiries.',
      );
    }

    final inquiry = InquiryDoc(
      inquiryId: match.matchId,
      matchId: match.matchId,
      tenantId: tenantId,
      ownerId: match.ownerId,
      propertyId: match.propertyId,
      tenantCiSnapshot: match.tenantCi ?? 0,
      stage: 1,
      initiatedBy: 'tenant',
      status: 'pending',
      ownerDecision: 'pending',
      autoInfoSent: true,
    );
    await _repository.createInquiry(inquiry);
    return inquiry.inquiryId;
  }

  Future<void> accept({
    required InquiryDoc inquiry,
    required String ownerId,
  }) async {
    _requireOwner(inquiry, ownerId);
    if (!isPhase1Pending(inquiry)) {
      throw const InquiryException('This inquiry has already been answered.');
    }
    await _repository.updateInquiry(inquiry.inquiryId, {
      'stage': 2,
      'ownerDecision': 'accepted',
      'status': 'active',
    });
  }

  Future<void> decline({
    required InquiryDoc inquiry,
    required String ownerId,
    String? reason,
  }) async {
    _requireOwner(inquiry, ownerId);
    if (!isPhase1Pending(inquiry)) {
      throw const InquiryException('This inquiry has already been answered.');
    }
    final trimmed = reason?.trim() ?? '';
    await _repository.updateInquiry(inquiry.inquiryId, {
      'ownerDecision': 'declined',
      'status': 'declined',
      if (trimmed.isNotEmpty) 'declineReason': trimmed,
    });
  }

  // ── Phase 2 ─────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required InquiryDoc inquiry,
    required String senderId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;
    if (!canChat(inquiry)) {
      throw const InquiryException(
        'Chat opens once the owner accepts this inquiry.',
      );
    }
    final isOwner = senderId == inquiry.ownerId;
    if (!isOwner && senderId != inquiry.tenantId) {
      throw const InquiryException('You are not part of this inquiry.');
    }
    await _repository.addMessage(
      inquiry.inquiryId,
      MessageDoc(
        messageId: '',
        senderId: senderId,
        senderRole: isOwner ? 'owner' : 'tenant',
        content: text,
        isAutoGenerated: false,
      ),
    );
  }

  /// Confirms the booking. A boarding house usually has several vacancies,
  /// so the listing stays up by default; pass [fillsLastVacancy] when this
  /// booking fills the last one — the same atomic write then takes the
  /// listing off the market (FilteringService drops it from every tenant's
  /// matches on their next pass) and closes the property's other open
  /// inquiries.
  Future<void> markBooked({
    required InquiryDoc inquiry,
    required String ownerId,
    bool fillsLastVacancy = false,
  }) async {
    _requireOwner(inquiry, ownerId);
    if (!canChat(inquiry)) {
      throw const InquiryException(
        'Only an accepted, active inquiry can be marked as booked.',
      );
    }
    final others = fillsLastVacancy
        ? (await _repository.fetchOpenInquiriesForProperty(
            ownerId: ownerId,
            propertyId: inquiry.propertyId,
          )).where((i) => i.inquiryId != inquiry.inquiryId)
        : const <InquiryDoc>[];
    await _repository.commitBooking(
      inquiryId: inquiry.inquiryId,
      propertyId: inquiry.propertyId,
      fillsLastVacancy: fillsLastVacancy,
      otherInquiryIds: [for (final i in others) i.inquiryId],
    );
  }

  // ── Rating ──────────────────────────────────────────────────────────────

  Future<void> submitRating({
    required InquiryDoc inquiry,
    required String raterId,
    required int stars,
    String? review,
  }) async {
    if (inquiry.status != 'booked') {
      throw const InquiryException('You can rate once the booking is confirmed.');
    }
    if (stars < 1 || stars > 5) {
      throw const InquiryException('Pick between 1 and 5 stars.');
    }
    final raterIsOwner = raterId == inquiry.ownerId;
    if (!raterIsOwner && raterId != inquiry.tenantId) {
      throw const InquiryException('You are not part of this inquiry.');
    }
    if (await _repository.hasRated(
      inquiryId: inquiry.inquiryId,
      raterId: raterId,
    )) {
      throw const InquiryException('You already rated this booking.');
    }
    final trimmed = review?.trim() ?? '';
    await _repository.createRating(
      RatingDoc(
        ratingId: '',
        inquiryId: inquiry.inquiryId,
        raterId: raterId,
        ratedId: ratedIdFor(inquiry, raterIsOwner: raterIsOwner),
        raterRole: raterIsOwner ? 'owner' : 'tenant',
        stars: stars,
        review: trimmed.isEmpty ? null : trimmed,
      ),
    );
  }

  void _requireOwner(InquiryDoc inquiry, String ownerId) {
    if (inquiry.ownerId != ownerId) {
      throw const InquiryException('Only the property owner can do this.');
    }
  }
}
