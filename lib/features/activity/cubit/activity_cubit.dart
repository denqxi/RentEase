import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/repositories/notification_repository.dart';
import '../model/activity_item.dart';

part 'activity_state.dart';

/// Activity feed and unread counts, backed by the user's `notifications`.
///
/// Two listeners: the recent feed (capped at
/// [NotificationRepository.feedLimit]) and the unread subset (uncapped, used
/// for every badge). Without a [repository] it just holds [initialItems]
/// (offline screenshot / debug harnesses).
class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({
    List<ActivityItem>? initialItems,
    NotificationRepository? repository,
    String? uid,
  }) : _repository = repository,
       super(
         repository != null && uid != null
             ? const ActivityState(isLoading: true)
             : ActivityState(
                 items: initialItems ?? const <ActivityItem>[],
                 unreadItems: [
                   for (final i in initialItems ?? const <ActivityItem>[])
                     if (!i.isRead) i,
                 ],
               ),
       ) {
    if (repository != null && uid != null) _watch(uid);
  }

  static const String _loadError = "Couldn't load your notifications.";

  final NotificationRepository? _repository;
  String? _uid;
  StreamSubscription<dynamic>? _feedSub;
  StreamSubscription<dynamic>? _unreadSub;

  static List<ActivityItem> _map(List<NotificationDoc> docs) => [
    for (final d in docs) ActivityItem.fromNotification(d),
  ];

  void _watch(String uid) {
    _uid = uid;
    _feedSub?.cancel();
    _unreadSub?.cancel();
    emit(const ActivityState(isLoading: true));
    final repo = _repository!;
    _feedSub = repo
        .watchForUser(uid)
        .listen(
          (docs) => emit(
            state.copyWith(
              items: _map(docs),
              isLoading: false,
              clearError: true,
            ),
          ),
          onError: (Object _) => emit(
            const ActivityState(errorMessage: _loadError),
          ),
        );
    _unreadSub = repo
        .watchUnreadForUser(uid)
        .listen(
          (docs) => emit(state.copyWith(unreadItems: _map(docs))),
          onError: (Object _) => emit(
            const ActivityState(errorMessage: _loadError),
          ),
        );
  }

  /// Re-subscribes after a load failure.
  void retry() {
    final uid = _uid;
    if (_repository != null && uid != null) _watch(uid);
  }

  /// Optimistically marks items matching [match] read in both lists.
  void _applyRead(bool Function(ActivityItem) match) {
    emit(
      state.copyWith(
        items: [
          for (final i in state.items) match(i) ? i.copyWith(isRead: true) : i,
        ],
        unreadItems: [
          for (final i in state.unreadItems)
            if (!match(i)) i,
        ],
      ),
    );
  }

  /// Marks a single item as read immediately.
  Future<void> markItemRead(String notifId) async {
    if (notifId.isEmpty) return;
    final isUnread = state.unreadItems.any((i) => i.id == notifId) ||
        state.items.any((i) => i.id == notifId && !i.isRead);
    if (!isUnread) return;
    _applyRead((i) => i.id == notifId);
    try {
      await _repository?.markRead([notifId]);
    } catch (_) {
      // The live stream restores the true state if the write failed.
    }
  }

  /// Marks all unread notifications of an inquiry as read immediately.
  /// Uses the uncapped unread set so older alerts are cleared too.
  Future<void> markInquiryRead(String inquiryId) async {
    if (inquiryId.isEmpty) return;
    final unreadNotifIds = {
      for (final i in state.unreadItems)
        if (i.relatedId == inquiryId) i.id,
      for (final i in state.items)
        if (i.relatedId == inquiryId && !i.isRead) i.id,
    }.toList();
    if (unreadNotifIds.isEmpty) return;
    _applyRead((i) => i.relatedId == inquiryId);
    try {
      await _repository?.markRead(unreadNotifIds);
    } catch (_) {
      // The live stream restores the true state if the write failed.
    }
  }

  /// Marks every unread notification read (server-side unread query, not the
  /// capped feed) and clears the badges.
  Future<void> markAllRead() async {
    final hasUnread = state.unreadItems.isNotEmpty ||
        state.items.any((i) => !i.isRead);
    if (!hasUnread) return;
    _applyRead((_) => true);
    final repo = _repository;
    final uid = _uid;
    if (repo == null || uid == null) return;
    try {
      await repo.markAllRead(uid);
    } catch (_) {
      // The live stream restores the true state if the write failed.
    }
  }

  @override
  void emit(ActivityState state) {
    if (isClosed) return; // async work may outlive the cubit
    super.emit(state);
  }

  @override
  Future<void> close() {
    _feedSub?.cancel();
    _unreadSub?.cancel();
    return super.close();
  }
}
