import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../../../../core/firestore/models/models.dart';
import '../../../activity/domain/repositories/notification_repository.dart';
import '../../model/invite_option.dart';
import '../repositories/inquiry_repository.dart';

/// A rule the inquiry flow refused — the message is safe to show the user.
class InquiryException implements Exception {
  const InquiryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A user-safe message for any error thrown by an inquiry action. Rule
/// refusals ([InquiryException]) pass through; anything else (Firestore
/// paths, SDK text) is replaced by a generic message instead of leaking.
String inquiryErrorMessage(Object e) {
  if (e is InquiryException) return e.message;
  if (e is FirebaseException && e.code == 'permission-denied') {
    return "You don't have permission to do that.";
  }
  return 'Something went wrong. Please try again.';
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
/// Owner invitations reuse the same thread: an owner invites a
/// compatible (bScore = 1) tenant, creating an inquiry with
/// `initiatedBy: 'owner'` at stage 1. Here the TENANT is the recipient, so
/// `ownerDecision` holds the tenant's decision (pending / accepted /
/// declined); accepting opens Phase 2 chat, declining closes the thread.
///
/// Every check here is mirrored by firestore.rules — the rules are the real
/// enforcement (a modified client skips this class entirely); these checks
/// exist so the UI fails fast with a readable message instead of a
/// permission-denied.
class InquiryService {
  InquiryService({
    required this._repository,
    this._notifications,
  });

  final InquiryRepository _repository;
  final NotificationRepository? _notifications;

  /// Best-effort in-app notification for [recipientId]; a failure here never
  /// affects the inquiry action that triggered it.
  Future<void> _notify({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    required String inquiryId,
    String? notifId,
  }) async {
    final repo = _notifications;
    if (repo == null) return;
    try {
      final doc = NotificationDoc(
        notifId: notifId ?? '',
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        relatedId: inquiryId,
        relatedType: 'inquiry',
        isRead: false,
      );
      if (notifId == null) {
        await repo.create(doc);
      } else {
        await repo.upsert(doc);
      }
    } catch (_) {
      // Intentionally swallowed — see above.
    }
  }

  /// Client-side caps for free text (firestore.rules adds no size limit).
  static const maxMessageLength = 1000;
  static const maxReasonLength = 500;
  static const maxReviewLength = 500;

  /// Shown to an owner whose verification was rejected (mirrors the
  /// `ownerNotRejected` rule in firestore.rules).
  static const rejectedOwnerMessage =
      "Your verification was not approved, so you can't send invitations or "
      'messages. Contact support to resubmit.';

  /// Shown to the tenant in a thread whose owner was rejected.
  static const rejectedOwnerTenantNote =
      "This owner can't reply right now.";

  /// Whether [ownerId]'s verification was rejected. A missing profile or a
  /// failed read counts as not rejected (firestore.rules is the enforcement).
  Future<bool> isOwnerRejected(String ownerId) async {
    try {
      final profile = await _repository.fetchOwnerProfile(ownerId);
      return profile?.verificationStatus == 'rejected';
    } catch (_) {
      return false;
    }
  }

  Future<void> _requireOwnerNotRejected(String ownerId) async {
    if (await isOwnerRejected(ownerId)) {
      throw const InquiryException(rejectedOwnerMessage);
    }
  }

  // ── Pure rules (unit-tested directly) ───────────────────────────────────

  static bool isPhase1Pending(InquiryDoc i) =>
      i.stage == 1 && i.ownerDecision == 'pending' && i.status == 'pending';

  static bool isInvite(InquiryDoc i) => i.initiatedBy == 'owner';

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
    await _notify(
      recipientId: inquiry.ownerId,
      type: 'inquiry',
      title: 'New inquiry from a compatible tenant',
      body: 'A tenant who passes all your rules sent an inquiry.',
      inquiryId: inquiry.inquiryId,
    );
    return inquiry.inquiryId;
  }

  Future<void> accept({
    required InquiryDoc inquiry,
    required String ownerId,
  }) async {
    _requireOwner(inquiry, ownerId);
    _requireTenantInitiated(inquiry);
    await _requireOwnerNotRejected(ownerId);
    if (!isPhase1Pending(inquiry)) {
      throw const InquiryException('This inquiry has already been answered.');
    }
    await _repository.updateInquiry(inquiry.inquiryId, {
      'stage': 2,
      'ownerDecision': 'accepted',
      'status': 'active',
    });
    // The owner's phone is shared on acceptance (consent notice shown first).
    await shareMyContact(inquiry: inquiry, uid: ownerId, accepted: true);
    await _notify(
      recipientId: inquiry.tenantId,
      type: 'inquiry_accepted',
      title: 'Your inquiry was accepted',
      body: 'Chat is now open with the owner.',
      inquiryId: inquiry.inquiryId,
    );
  }

  Future<void> decline({
    required InquiryDoc inquiry,
    required String ownerId,
    String? reason,
  }) async {
    _requireOwner(inquiry, ownerId);
    _requireTenantInitiated(inquiry);
    await _requireOwnerNotRejected(ownerId);
    if (!isPhase1Pending(inquiry)) {
      throw const InquiryException('This inquiry has already been answered.');
    }
    final trimmed = _capped(reason, maxReasonLength);
    await _repository.updateInquiry(inquiry.inquiryId, {
      'ownerDecision': 'declined',
      'status': 'declined',
      if (trimmed.isNotEmpty) 'declineReason': trimmed,
    });
    await _notify(
      recipientId: inquiry.tenantId,
      type: 'inquiry_declined',
      title: 'Your inquiry was declined',
      body: 'The owner declined your inquiry.',
      inquiryId: inquiry.inquiryId,
    );
  }

  // ── Owner invitations ───────────────────────────────────────────────────

  /// The properties this owner can still invite [tenantId] to: one
  /// per bScore = 1 match whose property is available and has no thread with
  /// this tenant yet (any status — a declined or booked thread is final).
  /// Owner verification is a badge only and does not gate this. [propertyId] narrows it to one
  /// property (Find Tenants is already scoped to the selected one).
  Future<List<InviteOption>> inviteOptions({
    required String ownerId,
    required String tenantId,
    String? propertyId,
  }) async {
    // Rejected owners get no invite options (button absent).
    if (await isOwnerRejected(ownerId)) return const [];
    final (matches, threads) = await (
      _repository.fetchCompatibleMatchesWithTenant(
        ownerId: ownerId,
        tenantId: tenantId,
      ),
      _repository.fetchInquiriesBetween(ownerId: ownerId, tenantId: tenantId),
    ).wait;
    final taken = {for (final t in threads) t.propertyId};

    final options = <InviteOption>[];
    for (final m in matches) {
      if (m.bScore != 1 || m.ownerId != ownerId || m.tenantId != tenantId) {
        continue;
      }
      if (propertyId != null && m.propertyId != propertyId) continue;
      if (taken.contains(m.propertyId)) continue;
      final property = await _repository.fetchProperty(m.propertyId);
      if (property == null ||
          !property.isAvailable ||
          property.ownerId != ownerId) {
        continue;
      }
      options.add(
        InviteOption(
          matchId: m.matchId,
          propertyId: m.propertyId,
          propertyTitle: property.title,
        ),
      );
    }
    return options;
  }

  /// Invites the match's tenant to the match's property and returns the new
  /// thread's ID (the match ID).
  Future<String> sendInvite({
    required String ownerId,
    required String matchId,
  }) async {
    await _requireOwnerNotRejected(ownerId);
    final match = await _repository.fetchMatch(matchId);
    if (match == null || match.ownerId != ownerId || match.bScore != 1) {
      // CLAUDE.md: communication only after bilateral compatibility.
      throw const InquiryException(
        'You can only invite tenants who are compatible with your property.',
      );
    }
    final property = await _repository.fetchProperty(match.propertyId);
    if (property == null ||
        !property.isAvailable ||
        property.ownerId != ownerId) {
      throw const InquiryException(
        'This listing is fully booked and no longer taking tenants.',
      );
    }
    final threads = await _repository.fetchInquiriesBetween(
      ownerId: ownerId,
      tenantId: match.tenantId,
    );
    if (threads.any((t) => t.propertyId == match.propertyId)) {
      throw const InquiryException(
        'This tenant already has an inquiry or invitation for this property.',
      );
    }

    final invitation = InquiryDoc(
      inquiryId: match.matchId,
      matchId: match.matchId,
      tenantId: match.tenantId,
      ownerId: ownerId,
      propertyId: match.propertyId,
      tenantCiSnapshot: match.tenantCi ?? 0,
      stage: 1,
      initiatedBy: 'owner',
      status: 'pending',
      ownerDecision: 'pending',
      autoInfoSent: true,
    );
    await _repository.createInquiry(invitation);
    await _notify(
      recipientId: invitation.tenantId,
      type: 'invitation',
      title: 'You were invited to a property',
      body: 'An owner invited you to ${property.title}.',
      inquiryId: invitation.inquiryId,
    );
    return invitation.inquiryId;
  }

  /// The invited tenant accepts: Phase 2 chat opens.
  Future<void> acceptInvite({
    required InquiryDoc inquiry,
    required String tenantId,
  }) async {
    _requireInvitedTenant(inquiry, tenantId);
    await _repository.updateInquiry(inquiry.inquiryId, {
      'stage': 2,
      'ownerDecision': 'accepted',
      'status': 'active',
    });
    // The tenant's phone is shared on acceptance (consent notice shown first).
    await shareMyContact(inquiry: inquiry, uid: tenantId, accepted: true);
    await _notify(
      recipientId: inquiry.ownerId,
      type: 'invitation_accepted',
      title: 'Your invitation was accepted',
      body: 'Chat is now open with the tenant.',
      inquiryId: inquiry.inquiryId,
    );
  }

  /// The invited tenant declines: the thread closes.
  Future<void> declineInvite({
    required InquiryDoc inquiry,
    required String tenantId,
    String? reason,
  }) async {
    _requireInvitedTenant(inquiry, tenantId);
    final trimmed = _capped(reason, maxReasonLength);
    await _repository.updateInquiry(inquiry.inquiryId, {
      'ownerDecision': 'declined',
      'status': 'declined',
      if (trimmed.isNotEmpty) 'declineReason': trimmed,
    });
    await _notify(
      recipientId: inquiry.ownerId,
      type: 'invitation_declined',
      title: 'Your invitation was declined',
      body: 'The tenant declined your invitation.',
      inquiryId: inquiry.inquiryId,
    );
  }

  // ── Contact sharing ─────────────────────────────────────────────────────

  /// Consent copy shown before a phone number can be shared; [other] is
  /// 'the owner' or 'the tenant'.
  static String contactConsentMessage(String other) =>
      'Your phone number will be shared with $other once the inquiry is '
      'accepted.';

  /// Accepted threads (active or booked) may exchange phone numbers.
  static bool canShareContact(InquiryDoc i) =>
      i.stage == 2 &&
      i.ownerDecision == 'accepted' &&
      (i.status == 'active' || i.status == 'booked');

  /// Writes [uid]'s own phone to `inquiries/{id}/contact/{role}` so the other
  /// participant can see it. Each participant can only write their own doc
  /// (firestore.rules), so the counterpart shares theirs when they next open
  /// the thread. Idempotent, best effort and never throws: a failure must not
  /// break accepting or opening a thread. Never shares an email.
  ///
  /// [accepted] lets accept()/acceptInvite() pass the post-update state, since
  /// the [inquiry] they hold is the pre-accept snapshot.
  Future<void> shareMyContact({
    required InquiryDoc inquiry,
    required String uid,
    bool accepted = false,
  }) async {
    try {
      if (!accepted && !canShareContact(inquiry)) return;
      final role = uid == inquiry.ownerId
          ? 'owner'
          : uid == inquiry.tenantId
          ? 'tenant'
          : null;
      if (role == null) return;
      if (role == 'owner' && await isOwnerRejected(uid)) return;
      if (await _repository.fetchContactShare(inquiry.inquiryId, role) != null) {
        return;
      }
      final phone = (await _repository.fetchOwnContact(uid))?.phone.trim() ?? '';
      if (phone.isEmpty) return;
      await _repository.writeContactShare(
        inquiry.inquiryId,
        role,
        ContactShareDoc(phone: phone),
      );
    } catch (_) {
      // Intentionally swallowed — see above.
    }
  }

  // ── Phase 2 ─────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required InquiryDoc inquiry,
    required String senderId,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return;
    if (text.length > maxMessageLength) {
      throw const InquiryException(
        'Messages can be at most $maxMessageLength characters.',
      );
    }
    if (!canChat(inquiry)) {
      throw const InquiryException(
        'Chat opens once the owner accepts this inquiry.',
      );
    }
    final isOwner = senderId == inquiry.ownerId;
    if (!isOwner && senderId != inquiry.tenantId) {
      throw const InquiryException('You are not part of this inquiry.');
    }
    if (await isOwnerRejected(inquiry.ownerId)) {
      throw InquiryException(
        isOwner ? rejectedOwnerMessage : rejectedOwnerTenantNote,
      );
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
    // Chat text lives only in inquiries/{id}/messages: the alert is one
    // rolling, content-free doc per inquiry + recipient.
    final recipientId = isOwner ? inquiry.tenantId : inquiry.ownerId;
    await _notify(
      recipientId: recipientId,
      type: 'message',
      title: 'New message',
      body: isOwner
          ? 'The owner sent you a new message.'
          : 'The tenant sent you a new message.',
      inquiryId: inquiry.inquiryId,
      notifId: 'msg_${inquiry.inquiryId}_$recipientId',
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
    await _requireOwnerNotRejected(ownerId);
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
    final trimmed = _capped(review, maxReviewLength);
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

  static String _capped(String? v, int max) {
    final t = v?.trim() ?? '';
    return t.length > max ? t.substring(0, max) : t;
  }

  void _requireTenantInitiated(InquiryDoc inquiry) {
    if (isInvite(inquiry)) {
      throw const InquiryException(
        'Only the invited tenant can answer an invitation.',
      );
    }
  }

  void _requireInvitedTenant(InquiryDoc inquiry, String tenantId) {
    if (!isInvite(inquiry) || inquiry.tenantId != tenantId) {
      throw const InquiryException('Only the invited tenant can do this.');
    }
    if (!isPhase1Pending(inquiry)) {
      throw const InquiryException('This invitation has already been answered.');
    }
  }

  void _requireOwner(InquiryDoc inquiry, String ownerId) {
    if (inquiry.ownerId != ownerId) {
      throw const InquiryException('Only the property owner can do this.');
    }
  }
}
