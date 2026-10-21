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

  /// Set of inquiry IDs that currently have unread notifications.
  Set<String> get unreadInquiryIds => items
      .where((i) =>
          !i.isRead &&
          (i.relatedType == 'inquiry' ||
              i.rawType == 'inquiry' ||
              i.rawType == 'inquiry_accepted' ||
              i.rawType == 'inquiry_declined' ||
              i.rawType == 'invitation' ||
              i.rawType == 'invitation_accepted' ||
              i.rawType == 'invitation_declined' ||
              i.rawType == 'message'))
      .map((i) => i.relatedId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();

  /// Total count of inquiries with unread notifications — drives the Inquiries tab dot.
  int get unreadInquiriesCount => unreadInquiryIds.length;

  ActivityState copyWith({List<ActivityItem>? items}) {
    return ActivityState(items: items ?? this.items);
  }

  @override
  List<Object?> get props => <Object?>[items, isLoading, errorMessage];
}
