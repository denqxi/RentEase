import '../../../../core/firestore/models/models.dart';

/// Firestore access for `notifications/{id}`: a user reads and marks their
/// own; creation is best-effort from the app-side inquiry flow.
abstract class NotificationRepository {
  /// The user's notifications, newest first.
  Stream<List<NotificationDoc>> watchForUser(String uid);

  Future<void> markRead(List<String> notifIds);

  Future<void> create(NotificationDoc notification);

  /// Writes [notification] at the doc ID `notification.notifId`, replacing any
  /// earlier doc there (used for the one rolling chat alert per conversation).
  Future<void> upsert(NotificationDoc notification);
}
