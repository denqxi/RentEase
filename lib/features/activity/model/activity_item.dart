import 'package:equatable/equatable.dart';

import '../../../core/firestore/models/models.dart';

/// Category of an activity notification.
enum ActivityType {
  /// A new listing match was found.
  match,

  /// A message from a landlord or agent.
  message,

  /// A listing update (price drop, new photos, etc.).
  update,
}

/// Filter categories for the segmented notification filter bar.
enum ActivityCategory {
  all,
  properties,
  inquiries,
  system;

  String get label => switch (this) {
        all => 'All',
        properties => 'Properties',
        inquiries => 'Inquiries',
        system => 'System',
      };
}

/// A single item in the activity / alerts feed.
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
    this.metadata,
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
  final Map<String, dynamic>? metadata;

  /// Maps a `notifications` doc; [now] is injectable for tests.
  factory ActivityItem.fromNotification(NotificationDoc n, {DateTime? now}) {
    final type = switch (n.type) {
      'new_match' => ActivityType.match,
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
      title: n.title,
      body: n.body,
      relatedId: n.relatedId,
      relatedType: n.relatedType,
      rawType: n.type,
      createdAt: n.createdAt?.toDate(),
      timeAgo: timeAgoLabel(n.createdAt?.toDate(), now ?? DateTime.now()),
      isRead: n.isRead,
    );
  }

  /// Categorizes this notification into one of the chip filter tabs.
  ActivityCategory get category {
    final raw = rawType ?? '';
    if (raw == 'new_match' ||
        raw == 'invitation' ||
        raw == 'compatible_tenants' ||
        type == ActivityType.match ||
        relatedType == 'property') {
      return ActivityCategory.properties;
    }
    if (raw == 'inquiry' ||
        raw == 'inquiry_accepted' ||
        raw == 'inquiry_declined' ||
        raw == 'invitation_accepted' ||
        raw == 'invitation_declined' ||
        raw == 'message' ||
        type == ActivityType.message) {
      return ActivityCategory.inquiries;
    }
    return ActivityCategory.system;
  }

  /// Determines time bucket ("Today", "Earlier", "This Month") for grouping.
  String dateGroup(DateTime now) {
    final at = createdAt;
    if (at != null) {
      final diff = now.difference(at);
      if (diff.inHours < 24 && now.day == at.day) {
        return 'Today';
      }
      if (diff.inDays <= 7) {
        return 'Earlier';
      }
      return 'This Month';
    }
    final lower = timeAgo.toLowerCase();
    if (lower.contains('minute') || lower.contains('hour') || lower.contains('just now')) {
      return 'Today';
    }
    if (lower.contains('yesterday') ||
        lower.contains('1 day') ||
        lower.contains('2 day') ||
        lower.contains('3 day') ||
        lower.contains('4 day') ||
        lower.contains('5 day') ||
        lower.contains('6 day') ||
        lower.contains('7 day')) {
      return 'Earlier';
    }
    return 'This Month';
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
    Map<String, dynamic>? metadata,
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
      metadata: metadata ?? this.metadata,
    );
  }

  /// Tenant prototype sample feed items matching the reference design.
  static const List<ActivityItem> samples = <ActivityItem>[
    ActivityItem(
      id: '1',
      type: ActivityType.match,
      rawType: 'invitation',
      title: 'A new property is available',
      body:
          'A property that matches your preferences and is near Holy Cross of Davao College is now available.',
      timeAgo: '2 hours ago',
      isRead: false,
      relatedId: 'prop_lucky_101',
      relatedType: 'property',
      metadata: <String, dynamic>{
        'propertyId': 'prop_lucky_101',
        'propertyName': 'Lucky Boarding House',
        'roomName': 'Room 101',
        'address': 'Doña Vicenta Drive, Davao City',
        'propertyType': 'Boarding House',
        'monthlyRent': 3500,
        'rating': 0.0,
        'photoCount': 8,
        'photoUrl':
            'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=600&q=80',
      },
    ),
    ActivityItem(
      id: '2',
      type: ActivityType.message,
      rawType: 'inquiry_accepted',
      title: 'Inquiry accepted by owner',
      body:
          'Sarah Chen accepted your inquiry for Green Sanctuary Dorm. Live messaging is now open.',
      timeAgo: '1 day ago',
      isRead: true,
      relatedId: 'inq_sarah_1',
      relatedType: 'inquiry',
    ),
    ActivityItem(
      id: '3',
      type: ActivityType.update,
      rawType: 'property_update',
      title: 'Price dropped on Modern Studio Loft',
      body: 'A saved property in Bajada has reduced its monthly rent by ₱500.',
      timeAgo: '2 days ago',
      isRead: true,
      relatedId: 'prop_modern_studio',
      relatedType: 'property',
      metadata: <String, dynamic>{
        'propertyId': 'prop_modern_studio',
        'propertyName': 'Modern Studio Loft',
        'roomName': 'Unit 3B',
        'address': 'Bajada, Davao City',
        'propertyType': 'Apartment',
        'monthlyRent': 6000,
        'rating': 4.8,
        'photoCount': 5,
        'photoUrl':
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=600&q=80',
      },
    ),
    ActivityItem(
      id: '4',
      type: ActivityType.match,
      rawType: 'new_match',
      title: 'New 94% match near Holy Cross',
      body:
          'A new listing matching your budget and amenities criteria was published.',
      timeAgo: '3 days ago',
      isRead: true,
      relatedId: 'prop_riverside',
      relatedType: 'property',
    ),
    ActivityItem(
      id: '5',
      type: ActivityType.update,
      rawType: 'system_alert',
      title: 'Profile preferences updated',
      body:
          'Your search filters were recalculated with new bilateral TOPSIS rankings.',
      timeAgo: '2 weeks ago',
      isRead: true,
    ),
  ];

  /// Landlord prototype sample feed items matching the reference design.
  static const List<ActivityItem> landlordSamples = <ActivityItem>[
    ActivityItem(
      id: '1',
      type: ActivityType.update,
      rawType: 'view_count',
      title: 'Your property was viewed',
      body: 'Your listing was viewed 12 times this week by compatible tenants.',
      timeAgo: '1 day ago',
      isRead: true,
    ),
    ActivityItem(
      id: '2',
      type: ActivityType.match,
      rawType: 'compatible_tenants',
      title: 'New compatible tenants found',
      body:
          '3 new tenants match your listing for Lucky Boarding House. You can notify them now.',
      timeAgo: 'Yesterday',
      isRead: false,
      relatedId: 'prop_lucky',
      relatedType: 'property',
    ),
    ActivityItem(
      id: '3',
      type: ActivityType.message,
      rawType: 'inquiry',
      title: 'New 94% tenant match: Jane Doe',
      body:
          'David Kim submitted an inquiry for availability. Compatibility: 94%.',
      timeAgo: '40 minutes ago',
      isRead: false,
      relatedId: 'inq_david',
      relatedType: 'inquiry',
    ),
    ActivityItem(
      id: '4',
      type: ActivityType.update,
      rawType: 'verification',
      title: 'Listing verified & published',
      body:
          'Your property Lucky Boarding House has been verified by the RentEase admin team.',
      timeAgo: '3 days ago',
      isRead: true,
      relatedId: 'prop_lucky',
      relatedType: 'property',
    ),
    ActivityItem(
      id: '5',
      type: ActivityType.update,
      rawType: 'system_alert',
      title: 'Reminder: complete your listing photos',
      body: 'Adding high-resolution photos boosts tenant compatibility and views.',
      timeAgo: '2 weeks ago',
      isRead: true,
    ),
  ];

  @override
  List<Object?> get props => <Object?>[
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
        metadata,
      ];
}

