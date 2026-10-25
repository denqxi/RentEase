import 'package:equatable/equatable.dart';

import '../../../core/firestore/models/models.dart';

/// Category of an activity notification.
enum ActivityType {
  match,
  message,
  update,
  rating,
}

/// A single item in the simplified activity / notifications feed.
class ActivityItem extends Equatable {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.timeAgo,
    this.isRead = false,
    this.body,
    this.relatedId,
    this.relatedType,
    this.rawType,
    this.createdAt,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String timeAgo;
  final bool isRead;
  final String? body;
  final String? relatedId;
  final String? relatedType;
  final String? rawType;
  final DateTime? createdAt;

  /// Maps a `notifications` Firestore doc; [now] is injectable for tests.
  factory ActivityItem.fromNotification(NotificationDoc n, {DateTime? now}) {
    final type = switch (n.type) {
      'new_match' => ActivityType.match,
      'rating' => ActivityType.rating,
      'inquiry' ||
      'inquiry_accepted' ||
      'inquiry_declined' ||
      'invitation' ||
      'invitation_accepted' ||
      'invitation_declined' ||
      'message' => ActivityType.message,
      _ => ActivityType.update,
    };
    return ActivityItem(
      id: n.notifId,
      type: type,
      title: _sanitizeNotificationText(n.title),
      body: _sanitizeNotificationText(n.body),
      relatedId: n.relatedId,
      relatedType: n.relatedType,
      rawType: n.type,
      createdAt: n.createdAt?.toDate(),
      timeAgo: timeAgoLabel(n.createdAt?.toDate(), now ?? DateTime.now()),
      isRead: n.isRead,
    );
  }

  /// Sanitizes notification copy to use "notify / notified / notification"
  /// instead of "invite / invited / invitation".
  static String _sanitizeNotificationText(String text) {
    if (text.isEmpty) return text;
    var sanitized = text;
    sanitized = sanitized.replaceAll(
      'You were invited to a property',
      'A landlord notified you about a property',
    );
    sanitized = sanitized.replaceAll(
      'Your invitation was accepted',
      'Your property notification was accepted',
    );
    sanitized = sanitized.replaceAll(
      'Your invitation was declined',
      'Your property notification was declined',
    );
    sanitized = sanitized.replaceAll(
      'The tenant declined your invitation.',
      'The tenant declined your notification.',
    );
    sanitized = sanitized.replaceAll(
      'declined your invitation',
      'declined your notification',
    );
    sanitized = sanitized.replaceAll(
      'invited you to view',
      'notified you about',
    );
    sanitized = sanitized.replaceAll(
      'invited you to',
      'notified you about',
    );
    sanitized = sanitized.replaceAll(
      'invited you',
      'notified you',
    );
    sanitized = sanitized.replaceAll(
      'new property invitation',
      'new property notification',
    );
    sanitized = sanitized.replaceAll(
      'an invitation',
      'a notification',
    );
    sanitized = sanitized.replaceAll(
      'An invitation',
      'A notification',
    );
    sanitized = sanitized.replaceAll(
      'this invitation',
      'this notification',
    );
    sanitized = sanitized.replaceAll(
      'invitations',
      'notifications',
    );
    sanitized = sanitized.replaceAll(
      'Invitations',
      'Notifications',
    );
    sanitized = sanitized.replaceAll(
      'invitation',
      'notification',
    );
    sanitized = sanitized.replaceAll(
      'Invitation',
      'Notification',
    );
    sanitized = sanitized.replaceAll(
      'invited',
      'notified',
    );
    sanitized = sanitized.replaceAll(
      'Invited',
      'Notified',
    );
    return sanitized;
  }

  /// "Just now", "5 minutes ago", "Yesterday", "3 days ago"...
  static String timeAgoLabel(DateTime? at, DateTime now) {
    if (at == null) return 'Just now';
    final d = now.difference(at);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) {
      return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'} ago';
    }
    if (d.inHours < 24) {
      return '${d.inHours} hour${d.inHours == 1 ? '' : 's'} ago';
    }
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays} days ago';
  }

  ActivityItem copyWith({
    bool? isRead,
    String? title,
    String? body,
  }) {
    return ActivityItem(
      id: id,
      type: type,
      title: title ?? this.title,
      timeAgo: timeAgo,
      isRead: isRead ?? this.isRead,
      body: body ?? this.body,
      relatedId: relatedId,
      relatedType: relatedType,
      rawType: rawType,
      createdAt: createdAt,
    );
  }

  /// Preview samples for harnesses.
  static const List<ActivityItem> samples = <ActivityItem>[
    ActivityItem(
      id: '1',
      type: ActivityType.message,
      rawType: 'invitation',
      title: 'Owner notified you about Cozy Studio',
      body: 'You have a new property notification.',
      timeAgo: '2 hours ago',
      isRead: false,
    ),
    ActivityItem(
      id: '2',
      type: ActivityType.rating,
      rawType: 'rating',
      title: 'You received a new rating from your landlord',
      body: 'Check out the new review on your profile.',
      timeAgo: '1 day ago',
      isRead: true,
    ),
  ];

  static const List<ActivityItem> landlordSamples = <ActivityItem>[
    ActivityItem(
      id: '1',
      type: ActivityType.message,
      rawType: 'inquiry',
      title: 'John Doe sent you an inquiry for Room 101',
      body: 'New inquiry received.',
      timeAgo: '10 minutes ago',
      isRead: false,
    ),
    ActivityItem(
      id: '2',
      type: ActivityType.rating,
      rawType: 'rating',
      title: 'A tenant rated your property',
      body: 'New review posted.',
      timeAgo: '3 hours ago',
      isRead: true,
    ),
  ];

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        timeAgo,
        isRead,
        body,
        relatedId,
        relatedType,
        rawType,
        createdAt,
      ];
}
