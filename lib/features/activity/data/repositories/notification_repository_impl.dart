import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Firestore allows 500 writes per batch; stay below it.
  static const int _batchSize = 450;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.notifications);

  @override
  Stream<List<NotificationDoc>> watchForUser(
    String uid, {
    int limit = NotificationRepository.feedLimit,
  }) {
    // Index: notifications (recipientId ASC, createdAt DESC).
    return _col
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_sortedNewestFirst);
  }

  @override
  Stream<List<NotificationDoc>> watchUnreadForUser(String uid) {
    // Equality-only query: served by single-field index merging, no
    // composite needed. Sorted client-side.
    return _col
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map(_sortedNewestFirst);
  }

  static List<NotificationDoc> _sortedNewestFirst(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final docs = snap.docs.map(NotificationDoc.fromSnapshot).toList();
    // Pending server timestamps (null) count as newest.
    docs.sort((a, b) {
      final at = a.createdAt?.millisecondsSinceEpoch ?? 1 << 62;
      final bt = b.createdAt?.millisecondsSinceEpoch ?? 1 << 62;
      return bt.compareTo(at);
    });
    return docs;
  }

  @override
  Future<void> markRead(List<String> notifIds) async {
    if (notifIds.isEmpty) return;
    for (var i = 0; i < notifIds.length; i += _batchSize) {
      final end = i + _batchSize > notifIds.length
          ? notifIds.length
          : i + _batchSize;
      final batch = _firestore.batch();
      for (final id in notifIds.sublist(i, end)) {
        batch.update(_col.doc(id), {'isRead': true});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> markAllRead(String uid) async {
    final snap = await _col
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    await markRead([for (final d in snap.docs) d.id]);
  }

  @override
  Future<void> create(NotificationDoc notification) async {
    await _col.add(notification.toMap());
  }

  @override
  Future<void> upsert(NotificationDoc notification) async {
    await _col.doc(notification.notifId).set(notification.toMap());
  }
}
