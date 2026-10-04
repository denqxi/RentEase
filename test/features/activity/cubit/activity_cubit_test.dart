import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/activity/cubit/activity_cubit.dart';
import 'package:rentease/features/activity/domain/repositories/notification_repository.dart';
import 'package:rentease/features/activity/model/activity_item.dart';

NotificationDoc _n(String id, {String type = 'inquiry', bool isRead = false}) =>
    NotificationDoc(
      notifId: id,
      recipientId: 'u1',
      type: type,
      title: 'Title $id',
      body: 'Body',
      isRead: isRead,
    );

class _FakeRepo implements NotificationRepository {
  final controller = StreamController<List<NotificationDoc>>.broadcast();
  final marked = <List<String>>[];

  @override
  Stream<List<NotificationDoc>> watchForUser(String uid) => controller.stream;

  @override
  Future<void> markRead(List<String> notifIds) async => marked.add(notifIds);

  @override
  Future<void> create(NotificationDoc notification) async {}

  @override
  Future<void> upsert(NotificationDoc notification) async {}
}

void main() {
  test('starts loading, then shows live notifications and unread count',
      () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    expect(cubit.state.isLoading, isTrue);

    repo.controller.add([_n('a'), _n('b', isRead: true)]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.items.length, 2);
    expect(cubit.state.unreadCount, 1);
    await cubit.close();
  });

  test('empty feed is not loading and has no unread', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.controller.add([]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, isNull);
    await cubit.close();
  });

  test('stream error surfaces a message and retry re-subscribes', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.controller.addError(Exception('boom'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.errorMessage, isNotNull);

    cubit.retry();
    expect(cubit.state.isLoading, isTrue);
    repo.controller.add([_n('a')]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.items.length, 1);
    await cubit.close();
  });

  test('markAllRead clears the badge and writes only unread ids', () async {
    final repo = _FakeRepo();
    final cubit = ActivityCubit(repository: repo, uid: 'u1');
    repo.controller.add([_n('a'), _n('b', isRead: true), _n('c')]);
    await Future<void>.delayed(Duration.zero);

    await cubit.markAllRead();

    expect(cubit.state.unreadCount, 0);
    expect(repo.marked.single, ['a', 'c']);

    await cubit.markAllRead();
    expect(repo.marked.length, 1, reason: 'nothing unread, no second write');
    await cubit.close();
  });

  test('without a repository it just holds the initial items', () {
    final cubit = ActivityCubit();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.isLoading, isFalse);
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
