import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firestore/firestore_collections.dart';
import '../../../../core/firestore/models/models.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.notifications);

  @override
  Stream<List<NotificationDoc>> watchForUser(String uid) {
    // Sorted client-side so the query needs no composite index.
    return _col.where('recipientId', isEqualTo: uid).snapshots().map((snap) {
      final docs = snap.docs.map(NotificationDoc.fromSnapshot).toList();
      docs.sort((a, b) {
        final at = a.createdAt?.millisecondsSinceEpoch ?? 1 << 62;
        final bt = b.createdAt?.millisecondsSinceEpoch ?? 1 << 62;
        return bt.compareTo(at);
      });
      return docs;
    });
  }

  @override
  Future<void> markRead(List<String> notifIds) async {
    if (notifIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in notifIds) {
      batch.update(_col.doc(id), {'isRead': true});
    }
    await batch.commit();
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
