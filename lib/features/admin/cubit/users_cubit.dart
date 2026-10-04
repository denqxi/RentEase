import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/entities/admin_entities.dart';
import '../domain/repositories/admin_repository.dart';

class UsersState extends Equatable {
  const UsersState({
    this.isLoading = true,
    this.users = const [],
    this.query = '',
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
    this.noticeSeq = 0,
  });

  final bool isLoading;
  final List<UserDoc> users;
  final String query;
  final Set<String> busyIds;
  final String? errorMessage;
  final String? notice;
  final int noticeSeq;

  /// [tab]: 'all' | 'tenant' | 'owner' | 'suspended'.
  List<UserDoc> filtered(String tab) {
    final q = query.trim().toLowerCase();
    return users.where((u) {
      final inTab = switch (tab) {
        'tenant' => u.role == 'tenant',
        'owner' => u.role == 'owner',
        'suspended' => u.status == 'suspended',
        _ => true,
      };
      if (!inTab) return false;
      if (q.isEmpty) return true;
      return '${u.firstName} ${u.lastName}'.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  UsersState copyWith({
    bool? isLoading,
    List<UserDoc>? users,
    String? query,
    Set<String>? busyIds,
    String? errorMessage,
    bool clearError = false,
    String? notice,
  }) => UsersState(
    isLoading: isLoading ?? this.isLoading,
    users: users ?? this.users,
    query: query ?? this.query,
    busyIds: busyIds ?? this.busyIds,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    isLoading,
    users,
    query,
    busyIds,
    errorMessage,
    noticeSeq,
  ];
}

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repo) : super(const UsersState());

  final AdminRepository _repo;
  StreamSubscription<List<UserDoc>>? _sub;

  void start() {
    _sub?.cancel();
    emit(state.copyWith(isLoading: true, clearError: true));
    _sub = _repo.watchUsers().listen(
      (users) => emit(
        state.copyWith(isLoading: false, users: users, clearError: true),
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

  Future<void> setSuspended(String userId, {required bool suspended}) async {
    if (state.busyIds.contains(userId)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, userId}));
    String message = suspended ? 'Account suspended.' : 'Account reactivated.';
    try {
      await _repo.setUserSuspended(userId, suspended: suspended);
    } on AdminException catch (e) {
      message = e.message;
    } catch (_) {
      message = 'Something went wrong. Please try again.';
    }
    emit(
      state.copyWith(
        busyIds: {...state.busyIds}..remove(userId),
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
