import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/activity/cubit/activity_cubit.dart';
import 'package:rentease/features/activity/domain/repositories/notification_repository.dart';
import 'package:rentease/features/activity/model/activity_item.dart';

NotificationDoc _n(
  String id, {
  String type = 'inquiry',
  bool isRead = false,
  String? relatedId,
  int minutesAgo = 0,
}) => NotificationDoc(
  notifId: id,
  recipientId: 'u1',
  type: type,
  title: 'Title $id',
  body: 'Body',
  relatedId: relatedId,
  relatedType: relatedId == null ? null : 'inquiry',
  isRead: isRead,
  createdAt: Timestamp.fromDate(
    DateTime(2026, 10, 1).subtract(Duration(minutes: minutesAgo)),
  ),
);

/// Two independent streams, like the real impl: the capped feed and the
/// unread subset.
class _FakeRepo implements NotificationRepository {
  final feed = StreamController<List<NotificationDoc>>.broadcast();
  final unread = StreamController<List<NotificationDoc>>.broadcast();
  final marked = <List<String>>[];
  final markAllCalls = <String>[];
  int? requestedLimit;

  @override
  Stream<List<NotificationDoc>> watchForUser(
    String uid, {
    int limit = NotificationRepository.feedLimit,
  }) {
    requestedLimit = limit;
    return feed.stream;
  }

  @override
  Stream<List<NotificationDoc>> watchUnreadForUser(String uid) =>
      unread.stream;

  @override
  Future<void> markRead(List<String> notifIds) async => marked.add(notifIds);

  @override
  Future<void> markAllRead(String uid) async => markAllCalls.add(uid);

  @override
  Future<void> create(NotificationDoc notification) async {}

  @override
  Future<void> upsert(NotificationDoc notification) async {}
}

/// In-memory store with the real query semantics: newest-first capped feed,
/// uncapped unread subset, markAllRead over the unread subset only.
class _StoreRepo implements NotificationRepository {
  _StoreRepo(List<NotificationDoc> docs)
    : _docs = {for (final d in docs) d.notifId: d};

  final Map<String, NotificationDoc> _docs;
  final _feed = StreamController<List<NotificationDoc>>.broadcast();
  final _unread = StreamController<List<NotificationDoc>>.broadcast();
  final writtenIds = <String>[];
  int _limit = NotificationRepository.feedLimit;

  List<NotificationDoc> get _sorted =>
      _docs.values.toList()
        ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

  void publish() {
    _feed.add(_sorted.take(_limit).toList());
    _unread.add(_sorted.where((d) => !d.isRead).toList());
  }

  @override
  Stream<List<NotificationDoc>> watchForUser(
    String uid, {
    int limit = NotificationRepository.feedLimit,
  }) {
    _limit = limit;
    return _feed.stream;
  }

  @override
  Stream<List<NotificationDoc>> watchUnreadForUser(String uid) =>
      _unread.stream;

  @override
  Future<void> markRead(List<String> notifIds) async {
    for (final id in notifIds) {
      writtenIds.add(id);
      final d = _docs[id]!;
      _docs[id] = NotificationDoc(
        notifId: d.notifId,
        recipientId: d.recipientId,
        type: d.type,
        title: d.title,
        body: d.body,
        relatedId: d.relatedId,
        relatedType: d.relatedType,
        isRead: true,
        createdAt: d.createdAt,
      );
    }
    publish();
  }

  @override
  Future<void> markAllRead(String uid) => markRead([
    for (final d in _docs.values)
      if (d.recipientId == uid && !d.isRead) d.notifId,
  ]);

  @override
  Future<void> create(NotificationDoc notification) async {}

  @override
  Future<void> upsert(NotificationDoc notification) async {}
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  test('starts loading, then shows live feed; badge from unread stream',
      () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    expect(cubit.state.isLoading, isTrue);

    repo.feed.add([_n('a'), _n('b', isRead: true)]);
    repo.unread.add([_n('a')]);
    await _pump();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.items.length, 2);
    expect(cubit.state.unreadCount, 1);
    await cubit.close();
  });

  test('requests the capped feed limit (50)', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    expect(NotificationRepository.feedLimit, 50);
    expect(repo.requestedLimit, NotificationRepository.feedLimit);
    await cubit.close();
  });

  test('badge counts come from the unread stream, not the capped feed',
      () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');

    // The feed holds only read docs; older unread ones fell past the cap.
    repo.feed.add([_n('r1', isRead: true), _n('r2', isRead: true)]);
    repo.unread.add([
      for (var i = 0; i < 120; i++) _n('u$i', relatedId: 'inq${i % 3}'),
    ]);
    await _pump();

    expect(cubit.state.items.length, 2);
    expect(cubit.state.unreadCount, 120);
    expect(cubit.state.unreadInquiriesCount, 3);
    await cubit.close();
  });

  test('empty feed is not loading and has no unread', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.feed.add([]);
    repo.unread.add([]);
    await _pump();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.unreadCount, 0);
    await cubit.close();
  });

  test('stream error surfaces a message and retry re-subscribes', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.feed.addError(Exception('boom'));
    await _pump();
    expect(cubit.state.errorMessage, isNotNull);

    cubit.retry();
    expect(cubit.state.isLoading, isTrue);
    repo.feed.add([_n('a')]);
    repo.unread.add([_n('a')]);
    await _pump();
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.items.length, 1);
    expect(cubit.state.unreadCount, 1);
    await cubit.close();
  });

  test('markAllRead clears the badge and delegates to the unread query',
      () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.feed.add([_n('a'), _n('b', isRead: true), _n('c')]);
    repo.unread.add([_n('a'), _n('c')]);
    await _pump();

    await cubit.markAllRead();

    expect(cubit.state.unreadCount, 0);
    expect(cubit.state.items.every((i) => i.isRead), isTrue);
    expect(repo.markAllCalls, ['u1']);
    expect(repo.marked, isEmpty, reason: 'no id list built from the feed');

    await cubit.markAllRead();
    expect(repo.markAllCalls.length, 1, reason: 'nothing unread, no write');
    await cubit.close();
  });

  test('80 docs: feed capped at 50, markAllRead writes only unread docs '
      'including ones beyond the cap', () async {
    // Newest first; every 4th is unread, plus two old unread docs (n70, n79)
    // that sit beyond the 50-doc cap.
    final docs = [
      for (var i = 0; i < 80; i++)
        _n('n$i', isRead: !(i % 4 == 0 || i == 70 || i == 79), minutesAgo: i),
    ];
    final expectedUnread = {
      for (final d in docs)
        if (!d.isRead) d.notifId,
    };
    final repo = _StoreRepo(docs);
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.publish();
    await _pump();

    expect(cubit.state.items.length, 50);
    expect(cubit.state.items.first.id, 'n0');
    expect(cubit.state.unreadCount, expectedUnread.length);
    expect(
      cubit.state.unreadItems.map((i) => i.id),
      containsAll(<String>['n70', 'n79']),
    );

    await cubit.markAllRead();
    await _pump();

    expect(repo.writtenIds.toSet(), expectedUnread);
    expect(repo.writtenIds.length, expectedUnread.length);
    expect(cubit.state.unreadCount, 0);
    expect(cubit.state.items.length, 50);
    await cubit.close();
  });

  test('markInquiryRead clears unread alerts beyond the feed cap', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.feed.add([_n('new', isRead: true, relatedId: 'inqA')]);
    repo.unread.add([
      _n('old1', relatedId: 'inqA'),
      _n('old2', relatedId: 'inqB'),
    ]);
    await _pump();

    await cubit.markInquiryRead('inqA');

    expect(repo.marked.single, ['old1']);
    expect(cubit.state.unreadInquiryIds, {'inqB'});
    await cubit.close();
  });

  test('markItemRead removes the item from the unread set', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.feed.add([_n('a'), _n('b')]);
    repo.unread.add([_n('a'), _n('b')]);
    await _pump();

    await cubit.markItemRead('a');
    expect(repo.marked.single, ['a']);
    expect(cubit.state.unreadCount, 1);
    expect(cubit.state.items.firstWhere((i) => i.id == 'a').isRead, isTrue);
    await cubit.close();
  });

  test('without a repository it just holds the initial items', () {
    final cubit = ActivityCubit();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.isLoading, isFalse);
  });

  test('without a repository unread is derived from the initial items', () {
    final cubit = ActivityCubit(initialItems: ActivityItem.samples);
    expect(
      cubit.state.unreadCount,
      ActivityItem.samples.where((i) => !i.isRead).length,
    );
  });

  group('ActivityItem.fromNotification', () {
    final now = DateTime(2026, 10, 2, 12);

    test('maps types and relative time', () {
      final item = ActivityItem.fromNotification(
        NotificationDoc(
          notifId: 'x',
          recipientId: 'u1',
          type: 'inquiry_accepted',
          title: 'T',
          body: 'B',
          isRead: false,
          createdAt: Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        ),
        now: now,
      );
      expect(item.type, ActivityType.message);
      expect(item.timeAgo, '3 hours ago');
      expect(ActivityItem.fromNotification(_n('y', type: 'new_match')).type,
          ActivityType.match);
      expect(ActivityItem.fromNotification(_n('z', type: 'verification')).type,
          ActivityType.update);
    });

    test('time labels', () {
      expect(ActivityItem.timeAgoLabel(null, now), 'Just now');
      expect(ActivityItem.timeAgoLabel(now, now), 'Just now');
      expect(
        ActivityItem.timeAgoLabel(now.subtract(const Duration(minutes: 1)), now),
        '1 minute ago',
      );
      expect(
        ActivityItem.timeAgoLabel(now.subtract(const Duration(days: 1)), now),
        'Yesterday',
      );
      expect(
        ActivityItem.timeAgoLabel(now.subtract(const Duration(days: 4)), now),
        '4 days ago',
      );
    });
  });
}
