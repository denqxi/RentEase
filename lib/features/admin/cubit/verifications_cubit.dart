import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/admin_entities.dart';
import '../domain/repositories/admin_repository.dart';

class VerificationsState extends Equatable {
  const VerificationsState({
    this.isLoading = true,
    this.items = const [],
    this.filter = 'pending',
    this.busyIds = const {},
    this.documents = const {},
    this.errorMessage,
    this.notice,
    this.noticeSeq = 0,
  });

  final bool isLoading;
  final List<VerificationItem> items;

  /// 'pending' | 'verified' | 'rejected' | 'all'
  final String filter;
  final Set<String> busyIds;
  final Map<String, VerificationDocuments> documents;
  final String? errorMessage;

  /// One-shot action feedback for a SnackBar; [noticeSeq] makes repeats unique.
  final String? notice;
  final int noticeSeq;

  int countOf(String status) => items.where((i) => i.status == status).length;

  List<VerificationItem> get visible =>
      filter == 'all' ? items : items.where((i) => i.status == filter).toList();

  VerificationsState copyWith({
    bool? isLoading,
    List<VerificationItem>? items,
    String? filter,
    Set<String>? busyIds,
    Map<String, VerificationDocuments>? documents,
    String? errorMessage,
    bool clearError = false,
    String? notice,
  }) => VerificationsState(
    isLoading: isLoading ?? this.isLoading,
    items: items ?? this.items,
    filter: filter ?? this.filter,
    busyIds: busyIds ?? this.busyIds,
    documents: documents ?? this.documents,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    isLoading,
    items,
    filter,
    busyIds,
    documents,
    errorMessage,
    noticeSeq,
  ];
}

class VerificationsCubit extends Cubit<VerificationsState> {
  VerificationsCubit(this._repo) : super(const VerificationsState());

  final AdminRepository _repo;
  StreamSubscription<List<VerificationItem>>? _sub;

  void start() {
    _sub?.cancel();
    emit(state.copyWith(isLoading: true, clearError: true));
    _sub = _repo.watchVerifications().listen(
      (items) => emit(
        state.copyWith(isLoading: false, items: items, clearError: true),
      ),
      onError: (Object e) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e is AdminException ? e.message : 'Could not load.',
        ),
      ),
    );
  }

  void setFilter(String filter) => emit(state.copyWith(filter: filter));

  Future<void> loadDocuments(String ownerId) async {
    if (state.documents.containsKey(ownerId)) return;
    try {
      final docs = await _repo.fetchDocuments(ownerId);
      emit(state.copyWith(documents: {...state.documents, ownerId: docs}));
    } on AdminException catch (e) {
      emit(state.copyWith(notice: e.message));
    }
  }

  Future<void> approve(String ownerId) => _act(
    ownerId,
    () => _repo.approveOwner(ownerId),
    'Owner approved. Their listings now show the Verified badge.',
  );

  Future<void> reject(String ownerId, {String? reason}) => _act(
    ownerId,
    () => _repo.rejectOwner(ownerId, reason: reason),
    'Verification rejected.',
  );

  Future<void> _act(
    String ownerId,
    Future<void> Function() action,
    String success,
  ) async {
    if (state.busyIds.contains(ownerId)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, ownerId}));
    String message = success;
    try {
      await action();
    } on AdminException catch (e) {
      message = e.message;
    } catch (_) {
      message = 'Something went wrong. Please try again.';
    }
    emit(
      state.copyWith(
        busyIds: {...state.busyIds}..remove(ownerId),
        notice: message,
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
