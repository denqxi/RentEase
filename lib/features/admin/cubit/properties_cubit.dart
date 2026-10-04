import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/admin_entities.dart';
import '../domain/repositories/admin_repository.dart';

class AdminPropertiesState extends Equatable {
  const AdminPropertiesState({
    this.isLoading = true,
    this.items = const [],
    this.query = '',
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
    this.noticeSeq = 0,
  });

  final bool isLoading;
  final List<AdminPropertyItem> items;
  final String query;
  final Set<String> busyIds;
  final String? errorMessage;
  final String? notice;
  final int noticeSeq;

  /// [tab]: 'all' | 'active' | 'unlisted'. Active = available to tenants;
  /// unlisted = hidden by an admin.
  List<AdminPropertyItem> filtered(String tab) {
    final q = query.trim().toLowerCase();
    return items.where((i) {
      final p = i.property;
      final inTab = switch (tab) {
        'active' => p.isAvailable,
        'unlisted' => i.adminUnlisted,
        _ => true,
      };
      if (!inTab) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          i.ownerName.toLowerCase().contains(q);
    }).toList();
  }

  AdminPropertiesState copyWith({
    bool? isLoading,
    List<AdminPropertyItem>? items,
    String? query,
    Set<String>? busyIds,
    String? errorMessage,
    bool clearError = false,
    String? notice,
  }) => AdminPropertiesState(
    isLoading: isLoading ?? this.isLoading,
    items: items ?? this.items,
    query: query ?? this.query,
    busyIds: busyIds ?? this.busyIds,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    isLoading,
    items,
    query,
    busyIds,
    errorMessage,
    noticeSeq,
  ];
}

class AdminPropertiesCubit extends Cubit<AdminPropertiesState> {
  AdminPropertiesCubit(this._repo) : super(const AdminPropertiesState());

  final AdminRepository _repo;
  StreamSubscription<List<AdminPropertyItem>>? _sub;

  void start() {
    _sub?.cancel();
    emit(state.copyWith(isLoading: true, clearError: true));
    _sub = _repo.watchProperties().listen(
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

  void setQuery(String query) => emit(state.copyWith(query: query));

  Future<void> setListed(String propertyId, {required bool listed}) async {
    if (state.busyIds.contains(propertyId)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, propertyId}));
    String message = listed ? 'Listing relisted.' : 'Listing unlisted.';
    try {
      await _repo.setPropertyListed(propertyId, listed: listed);
    } on AdminException catch (e) {
      message = e.message;
    } catch (_) {
      message = 'Something went wrong. Please try again.';
    }
    emit(
      state.copyWith(
        busyIds: {...state.busyIds}..remove(propertyId),
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
