import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/repositories/inquiry_repository.dart';
import '../domain/services/inquiry_service.dart';

part 'inquiry_thread_state.dart';

/// One inquiry thread, for either side. Follows the inquiry doc and its
/// messages live, so the tenant's locked Phase 1 view unlocks into chat the
/// moment the owner accepts — no refresh. Mutations go through
/// [InquiryService]; this only holds UI state.
class InquiryThreadCubit extends Cubit<InquiryThreadState> {
  InquiryThreadCubit({
    required this.inquiryId,
    required this.uid,
    required this._repository,
    required this._service,
  }) : super(const InquiryThreadState()) {
    _inquirySub = _repository.watchInquiry(inquiryId).listen(
      _onInquiry,
      onError: _onError,
    );
    _messagesSub = _repository.watchMessages(inquiryId).listen((messages) {
      if (isClosed) return;
      final sorted = [...messages]
        ..sort(
          (a, b) => (a.timeStamp?.millisecondsSinceEpoch ?? 1 << 62).compareTo(
            b.timeStamp?.millisecondsSinceEpoch ?? 1 << 62,
          ),
        );
      emit(state.copyWith(messages: sorted));
    }, onError: _onError);
  }

  final String inquiryId;
  final String uid;
  final InquiryRepository _repository;
  final InquiryService _service;
  StreamSubscription<InquiryDoc?>? _inquirySub;
  StreamSubscription<List<MessageDoc>>? _messagesSub;
  StreamSubscription<ContactShareDoc?>? _contactSub;
  bool _contextLoaded = false;
  bool _contactStarted = false;

  Future<void> _onInquiry(InquiryDoc? inquiry) async {
    if (isClosed) return;
    if (inquiry == null) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'This inquiry is no longer available.',
        ),
      );
      return;
    }
    emit(state.copyWith(inquiry: inquiry));
    _startContactSharing(inquiry);
    if (!_contextLoaded) {
      _contextLoaded = true;
      await _loadContext(inquiry);
    }
  }

  /// Once the inquiry is accepted: share my own phone (idempotent, best
  /// effort — covers the counterpart who could not write mine at accept time)
  /// and follow the counterpart's share live. Runs once per thread screen.
  void _startContactSharing(InquiryDoc inquiry) {
    if (_contactStarted || !InquiryService.canShareContact(inquiry)) return;
    _contactStarted = true;
    _service.shareMyContact(inquiry: inquiry, uid: uid);
    final counterpartRole = uid == inquiry.ownerId ? 'tenant' : 'owner';
    _contactSub = _repository
        .watchContactShare(inquiryId, counterpartRole)
        .listen((share) {
          if (isClosed) return;
          final phone = share?.phone.trim() ?? '';
          emit(state.copyWith(counterpartPhone: phone, clearPhone: phone.isEmpty));
        }, onError: (_) {});
  }

  /// The docs behind the Phase 1 auto-info summaries and the chat header —
  /// fetched once; they don't change while a thread is open.
  Future<void> _loadContext(InquiryDoc inquiry) async {
    try {
      final (property, tenant, tenantProfile, owner, ownerProfile) = await (
        _repository.fetchProperty(inquiry.propertyId),
        _repository.fetchUser(inquiry.tenantId),
        _repository.fetchTenantProfile(inquiry.tenantId),
        _repository.fetchUser(inquiry.ownerId),
        _repository.fetchOwnerProfile(inquiry.ownerId),
      ).wait;
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          property: property,
          tenant: tenant,
          tenantProfile: tenantProfile,
          owner: owner,
          ownerVerified: ownerProfile?.verificationStatus == 'verified',
          ownerRejected: ownerProfile?.verificationStatus == 'rejected',
        ),
      );
    } catch (e) {
      _onError(e);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────

  /// Phase 1 accept: the owner for a tenant's inquiry, or the invited tenant
  /// for an owner's invitation.
  Future<bool> accept() => _run(
    (i) => InquiryService.isInvite(i)
        ? _service.acceptInvite(inquiry: i, tenantId: uid)
        : _service.accept(inquiry: i, ownerId: uid),
  );

  Future<bool> decline(String? reason) => _run(
    (i) => InquiryService.isInvite(i)
        ? _service.declineInvite(inquiry: i, tenantId: uid, reason: reason)
        : _service.decline(inquiry: i, ownerId: uid, reason: reason),
  );

  Future<bool> markBooked({bool fillsLastVacancy = false}) => _run(
    (i) => _service.markBooked(
      inquiry: i,
      ownerId: uid,
      fillsLastVacancy: fillsLastVacancy,
    ),
  );

  Future<bool> sendMessage(String text) => _run(
    (i) => _service.sendMessage(inquiry: i, senderId: uid, content: text),
  );

  Future<bool> submitRating({required int stars, String? review}) => _run(
    (i) => _service.submitRating(
      inquiry: i,
      raterId: uid,
      stars: stars,
      review: review,
    ),
  );

  /// Runs [action] against the current inquiry; returns whether it
  /// succeeded. Failures land in [InquiryThreadState.errorMessage].
  Future<bool> _run(Future<void> Function(InquiryDoc inquiry) action) async {
    final inquiry = state.inquiry;
    if (inquiry == null || state.isBusy) return false;
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      await action(inquiry);
      if (!isClosed) emit(state.copyWith(isBusy: false));
      return true;
    } catch (e) {
      _onError(e);
      return false;
    }
  }

  void _onError(Object e) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        isBusy: false,
        errorMessage: inquiryErrorMessage(e),
      ),
    );
  }

  void clearError() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() {
    _inquirySub?.cancel();
    _messagesSub?.cancel();
    _contactSub?.cancel();
    return super.close();
  }
}
