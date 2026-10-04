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
