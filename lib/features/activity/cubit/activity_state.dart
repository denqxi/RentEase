part of 'activity_cubit.dart';

/// State for [ActivityCubit].
///
/// [items] is the capped recent feed (newest first, at most
/// [NotificationRepository.feedLimit]); [unreadItems] is the full unread
/// subset from a separate listener. Badges and unread counts must come from
/// [unreadItems], never from [items].
class ActivityState extends Equatable {
  const ActivityState({
    this.items = const <ActivityItem>[],
    this.unreadItems = const <ActivityItem>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ActivityItem> items;
  final List<ActivityItem> unreadItems;
  final bool isLoading;
  final String? errorMessage;

  /// Number of unread notifications — drives the Alerts tab badge.
  int get unreadCount => unreadItems.length;

  /// Set of inquiry IDs that currently have unread notifications.
  Set<String> get unreadInquiryIds => unreadItems
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

  ActivityState copyWith({
    List<ActivityItem>? items,
    List<ActivityItem>? unreadItems,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActivityState(
      items: items ?? this.items,
      unreadItems: unreadItems ?? this.unreadItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[items, unreadItems, isLoading, errorMessage];
}
