import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/repositories/inquiry_repository.dart';
import '../domain/services/inquiry_service.dart';
import '../model/inquiry_summary.dart';

part 'inquiry_list_state.dart';

/// Live inquiry inbox for one user — the tenant's own inquiries, or the
/// owner's incoming ones. Re-emits whenever any inquiry changes (e.g. an
/// owner accepting flips the tenant's row to "Chat open" without a refresh).
class InquiryListCubit extends Cubit<InquiryListState> {
  InquiryListCubit({
    required this.uid,
    required this.isOwner,
    required this._repository,
  }) : super(const InquiryListState()) {
    _subscription =
        (isOwner
                ? _repository.watchOwnerInquiries(uid)
                : _repository.watchTenantInquiries(uid))
            .listen(_onInquiries, onError: _onError);
  }

  final String uid;
  final bool isOwner;
  final InquiryRepository _repository;
  StreamSubscription<List<InquiryDoc>>? _subscription;

  // Names don't change while the inbox is open — cache per ID so every
  // snapshot doesn't re-fetch every row's property and counterpart.
  final Map<String, String> _propertyTitles = {};
  final Map<String, String> _userNames = {};

  Future<void> _onInquiries(List<InquiryDoc> inquiries) async {
    try {
      final summaries = await Future.wait(inquiries.map(_summarize));
      summaries.sort(
        (a, b) => (b.inquiry.updatedAt?.millisecondsSinceEpoch ?? 1 << 62)
            .compareTo(a.inquiry.updatedAt?.millisecondsSinceEpoch ?? 1 << 62),
      );
      if (isClosed) return;
      emit(InquiryListState(isLoading: false, items: summaries));
    } catch (e) {
      _onError(e);
    }
  }

  Future<InquirySummary> _summarize(InquiryDoc inquiry) async {
    final title = _propertyTitles[inquiry.propertyId] ??= await _repository
        .fetchProperty(inquiry.propertyId)
        .then((p) => p?.title ?? 'Listing removed');
    final counterpartId = isOwner ? inquiry.tenantId : inquiry.ownerId;
    final name = _userNames[counterpartId] ??= await _repository
        .fetchUser(counterpartId)
        .then(
          (u) => fullNameOf(u, fallback: isOwner ? 'Tenant' : 'Property owner'),
        );
    return InquirySummary(
      inquiry: inquiry,
      propertyTitle: title,
      counterpartName: name,
    );
  }

  void _onError(Object e) {
    if (isClosed) return;
    emit(
      InquiryListState(
        isLoading: false,
        items: state.items,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
