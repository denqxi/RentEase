import 'package:equatable/equatable.dart';

/// Category of an activity notification.
enum ActivityType {
  /// A new listing match was found.
  match,

  /// A message from a landlord or agent.
  message,

  /// A listing update (price drop, new photos, etc.).
  update,
}

/// A single item in the activity / alerts feed.
class ActivityItem extends Equatable {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.timeAgo,
    this.isRead = false,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String timeAgo;
  final bool isRead;

  ActivityItem copyWith({bool? isRead}) {
    return ActivityItem(
      id: id,
      type: type,
      title: title,
      timeAgo: timeAgo,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Tenant prototype sample feed items.
  static const List<ActivityItem> samples = <ActivityItem>[
    ActivityItem(
      id: '1',
      type: ActivityType.match,
      title: 'New 92% match: Sunny 2-Bed Apartment',
      timeAgo: '2 minutes ago',
    ),
    ActivityItem(
      id: '2',
      type: ActivityType.message,
      title: 'Sarah Chen replied about your viewing',
      timeAgo: '1 hour ago',
    ),
    ActivityItem(
      id: '3',
      type: ActivityType.update,
      title: 'Price dropped on Modern Studio Loft',
      timeAgo: '3 hours ago',
      isRead: true,
    ),
    ActivityItem(
      id: '4',
      type: ActivityType.match,
      title: 'New home matched in Riverside',
      timeAgo: 'Yesterday',
      isRead: true,
    ),
    ActivityItem(
      id: '5',
      type: ActivityType.update,
      title: 'A saved home added new photos',
      timeAgo: '2 days ago',
      isRead: true,
    ),
  ];

  /// Landlord prototype sample feed items.
  static const List<ActivityItem> landlordSamples = <ActivityItem>[
    ActivityItem(
      id: '1',
      type: ActivityType.match,
      title: 'New 94% tenant match: Jane Doe',
      timeAgo: '5 minutes ago',
    ),
    ActivityItem(
      id: '2',
      type: ActivityType.message,
      title: 'David Kim asked about availability',
      timeAgo: '40 minutes ago',
    ),
    ActivityItem(
      id: '3',
      type: ActivityType.update,
      title: 'Your listing reached 120 views',
      timeAgo: '2 hours ago',
      isRead: true,
    ),
    ActivityItem(
      id: '4',
      type: ActivityType.match,
      title: '3 new compatible tenants this week',
      timeAgo: 'Yesterday',
      isRead: true,
    ),
    ActivityItem(
      id: '5',
      type: ActivityType.update,
      title: 'Reminder: complete your listing photos',
      timeAgo: '3 days ago',
      isRead: true,
    ),
  ];

  @override
  List<Object?> get props => <Object?>[id, type, title, timeAgo, isRead];
}
