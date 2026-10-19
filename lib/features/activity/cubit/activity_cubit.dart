import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/repositories/notification_repository.dart';
import '../model/activity_item.dart';

part 'activity_state.dart';

/// Activity feed and unread count for the Alerts tab badge, backed by the
/// user's `notifications`. Without a [repository] it just holds
/// [initialItems] (offline screenshot / debug harnesses).
class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({
    List<ActivityItem>? initialItems,
    NotificationRepository? repository,
    String? uid,
  }) : _repository = repository,
       super(
         repository != null && uid != null
             ? const ActivityState(isLoading: true)
             : ActivityState(items: initialItems ?? const <ActivityItem>[]),
       ) {
    if (repository != null && uid != null) _watch(uid);
  }

  final NotificationRepository? _repository;
  String? _uid;
  StreamSubscription<dynamic>? _subscription;

  void _watch(String uid) {
    _uid = uid;
    _subscription?.cancel();
    emit(const ActivityState(isLoading: true));
    _subscription = _repository!
        .watchForUser(uid)
        .listen(
          (docs) => emit(
            ActivityState(
              items: [for (final d in docs) ActivityItem.fromNotification(d)],
            ),
          ),
          onError: (Object _) => emit(
            const ActivityState(
              errorMessage: "Couldn't load your notifications.",
            ),
          ),
        );
  }

  /// Re-subscribes after a load failure.
  void retry() {
    final uid = _uid;
    if (_repository != null && uid != null) _watch(uid);
  }

  /// Marks a single item as read immediately.
  Future<void> markItemRead(String notifId) async {
    if (notifId.isEmpty) return;
    final item = state.items.where((i) => i.id == notifId).firstOrNull;
    if (item == null || item.isRead) return;
    emit(
      state.copyWith(
        items: state.items.map((i) => i.id == notifId ? i.copyWith(isRead: true) : i).toList(),
      ),
    );
    try {
      await _repository?.markRead([notifId]);
    } catch (_) {
      // Stream restores if write fails
    }
  }

  /// Marks all notifications associated with an inquiry as read immediately.
  Future<void> markInquiryRead(String inquiryId) async {
    if (inquiryId.isEmpty) return;
    final unreadNotifIds = state.items
        .where((i) => i.relatedId == inquiryId && !i.isRead)
        .map((i) => i.id)
        .toList();
    if (unreadNotifIds.isEmpty) return;
    emit(
      state.copyWith(
        items: state.items
            .map((i) => i.relatedId == inquiryId ? i.copyWith(isRead: true) : i)
            .toList(),
      ),
    );
    try {
      await _repository?.markRead(unreadNotifIds);
    } catch (_) {
      // Stream restores if write fails
    }
  }

  /// Marks every item as read and clears the bell badge.
  Future<void> markAllRead() async {
    final unreadIds = [
      for (final i in state.items)
        if (!i.isRead) i.id,
    ];
    if (unreadIds.isEmpty) return;
    emit(
      state.copyWith(
        items: state.items.map((i) => i.copyWith(isRead: true)).toList(),
      ),
    );
    try {
      await _repository?.markRead(unreadIds);
    } catch (_) {
      // The live stream restores the true state if the write failed.
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
