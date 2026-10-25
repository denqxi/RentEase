import '../../../../core/firestore/models/models.dart';

/// Firestore access for `notifications/{id}`: a user reads and marks their
/// own; creation is best-effort from the app-side inquiry flow.
abstract class NotificationRepository {
  /// Max docs the Activity feed listens to (no paging UI yet).
  static const int feedLimit = 50;

  /// The user's most recent notifications, newest first, capped at [limit].
  /// Use [watchUnreadForUser] for badge counts, never this capped list.
  Stream<List<NotificationDoc>> watchForUser(
    String uid, {
    int limit = feedLimit,
  });

  /// Every unread notification of the user (uncapped, newest first). This is
  /// the source of truth for unread badges.
  Stream<List<NotificationDoc>> watchUnreadForUser(String uid);

  Future<void> markRead(List<String> notifIds);

  /// Marks every unread notification of [uid] read (queries the unread
  /// subset, not the capped feed).
  Future<void> markAllRead(String uid);

  Future<void> create(NotificationDoc notification);

  /// Writes [notification] at the doc ID `notification.notifId`, replacing any
  /// earlier doc there (used for the one rolling chat alert per conversation).
  Future<void> upsert(NotificationDoc notification);
}
