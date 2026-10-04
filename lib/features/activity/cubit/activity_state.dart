part of 'activity_cubit.dart';

/// State for [ActivityCubit].
class ActivityState extends Equatable {
  const ActivityState({
    this.items = const <ActivityItem>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ActivityItem> items;
  final bool isLoading;
  final String? errorMessage;

  /// Number of unread items — drives the Alerts tab badge.
  int get unreadCount => items.where((i) => !i.isRead).length;

  ActivityState copyWith({List<ActivityItem>? items}) {
    return ActivityState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => <Object?>[items, isLoading, errorMessage];
}
