import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/activity_item.dart';

part 'activity_state.dart';

/// Manages the activity feed and unread count for the Alerts tab badge.
class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit({List<ActivityItem>? initialItems})
      : super(ActivityState(items: initialItems ?? ActivityItem.samples));

  /// Marks every item as read and clears the bell badge.
  void markAllRead() {
    final updated = state.items.map((i) => i.copyWith(isRead: true)).toList();
    emit(state.copyWith(items: updated));
  }
}
