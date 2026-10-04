import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/core/theme/app_theme.dart';
import 'package:rentease/core/utils/url_opener.dart';
import 'package:rentease/features/inquiry/cubit/inquiry_thread_cubit.dart';
import 'package:rentease/features/inquiry/domain/repositories/inquiry_repository.dart';
import 'package:rentease/features/inquiry/domain/services/inquiry_service.dart';
import 'package:rentease/features/inquiry/widgets/contact_consent_notice.dart';
import 'package:rentease/features/inquiry/widgets/contact_row.dart';

import 'fake_invite_repository.dart';

/// Repository stub for contact sharing: records share writes and lets the
/// test push the counterpart's share.
class _ShareRepo implements InquiryRepository {
  _ShareRepo(this.inquiry);

  InquiryDoc inquiry;
  final inquiryCtrl = StreamController<InquiryDoc?>.broadcast();
  final shareCtrls = <String, StreamController<ContactShareDoc?>>{};
  final Map<String, ContactShareDoc> shares = {};
  final updates = <Map<String, dynamic>>[];
  UserContactDoc? ownContact = const UserContactDoc(
    phone: '09171234567',
    email: 'me@example.com',
  );
  int writes = 0;
  bool failWrite = false;

  @override
  Stream<InquiryDoc?> watchInquiry(String id) async* {
    yield inquiry;
    yield* inquiryCtrl.stream;
  }

  @override
  Stream<List<MessageDoc>> watchMessages(String id) =>
      Stream.value(const <MessageDoc>[]);

  @override
  Stream<ContactShareDoc?> watchContactShare(String id, String role) =>
      (shareCtrls[role] ??= StreamController<ContactShareDoc?>.broadcast())
          .stream;

  @override
  Future<ContactShareDoc?> fetchContactShare(String id, String role) async =>
      shares[role];

  @override
  Future<UserContactDoc?> fetchOwnContact(String uid) async => ownContact;

  @override
  Future<void> writeContactShare(
    String id,
    String role,
    ContactShareDoc share,
  ) async {
    if (failWrite) throw Exception('permission-denied');
    writes++;
    shares[role] = share;
  }

  @override
  Future<void> updateInquiry(String id, Map<String, dynamic> fields) async =>
      updates.add(fields);

  @override
  Future<PropertyDoc?> fetchProperty(String id) async => propertyFor(kProp1);

  @override
  Future<UserDoc?> fetchUser(String uid) async => UserDoc(
    userId: uid,
    firstName: 'F',
    lastName: 'L',
    gender: 'f',
    role: 'tenant',
    status: 'active',
  );

  @override
  Future<TenantProfileDoc?> fetchTenantProfile(String uid) async => null;

  @override
  Future<OwnerProfileDoc?> fetchOwnerProfile(String uid) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Opener implements UrlOpener {
  Uri? opened;

  @override
  Future<bool> open(Uri uri) async {
    opened = uri;
    return true;
  }
}

InquiryDoc _accepted({String status = 'active', String by = 'tenant'}) =>
    threadFor(
      kProp1,
      initiatedBy: by,
      stage: 2,
      status: status,
      decision: 'accepted',
    );

void main() {
  group('InquiryService contact sharing', () {
    test('owner accept writes the owner share (phone only)', () async {
      final repo = _ShareRepo(threadFor(kProp1, initiatedBy: 'tenant'));
      final service = InquiryService(repository: repo);

      await service.accept(inquiry: repo.inquiry, ownerId: kOwner);

      expect(repo.updates.single['ownerDecision'], 'accepted');
      expect(repo.shares.keys, ['owner']);
      expect(repo.shares['owner']!.phone, '09171234567');
    });

    test('tenant accepting an invitation writes the tenant share', () async {
      final repo = _ShareRepo(threadFor(kProp1, initiatedBy: 'owner'));
      await InquiryService(
        repository: repo,
      ).acceptInvite(inquiry: repo.inquiry, tenantId: kTenant);
      expect(repo.shares.keys, ['tenant']);
    });

    test('shareMyContact is idempotent and never runs at inquiry time', () async {
      final repo = _ShareRepo(threadFor(kProp1, initiatedBy: 'tenant'));
      final service = InquiryService(repository: repo);

      await service.shareMyContact(inquiry: repo.inquiry, uid: kOwner);
      expect(repo.writes, 0);

      final accepted = _accepted();
      await service.shareMyContact(inquiry: accepted, uid: kTenant);
      await service.shareMyContact(inquiry: accepted, uid: kTenant);
      expect(repo.writes, 1);
    });

    test('declined / closed threads never share; booked threads can', () async {
      final repo = _ShareRepo(_accepted());
      final service = InquiryService(repository: repo);
      for (final i in [
        threadFor(kProp1, stage: 1, status: 'declined', decision: 'declined'),
        _accepted(status: 'closed'),
      ]) {
        await service.shareMyContact(inquiry: i, uid: kTenant);
      }
      expect(repo.writes, 0);
      await service.shareMyContact(
        inquiry: _accepted(status: 'booked'),
        uid: kTenant,
      );
      expect(repo.writes, 1);
    });

    test('missing phone or a failing write never throws', () async {
      final repo = _ShareRepo(_accepted())..ownContact = null;
      final service = InquiryService(repository: repo);
      await service.shareMyContact(inquiry: repo.inquiry, uid: kTenant);
      expect(repo.writes, 0);

      repo
        ..ownContact = const UserContactDoc(phone: '0917')
        ..failWrite = true;
      await service.shareMyContact(inquiry: repo.inquiry, uid: kTenant);
      expect(repo.writes, 0);
    });

    test('accept still succeeds when the share write fails', () async {
      final repo = _ShareRepo(threadFor(kProp1, initiatedBy: 'tenant'))
        ..failWrite = true;
      await InquiryService(
        repository: repo,
      ).accept(inquiry: repo.inquiry, ownerId: kOwner);
      expect(repo.updates, hasLength(1));
    });

    test('a stranger writes nothing', () async {
      final repo = _ShareRepo(_accepted());
      await InquiryService(
        repository: repo,
      ).shareMyContact(inquiry: repo.inquiry, uid: 'stranger');
      expect(repo.writes, 0);
    });

    test('share doc serialises only phone and sharedAt', () {
      expect(const ContactShareDoc(phone: '1').toMap().keys.toSet(), {
        'phone',
        'sharedAt',
      });
    });

    test('consent message matches the agreed copy', () {
      expect(
        InquiryService.contactConsentMessage('the owner'),
        'Your phone number will be shared with the owner once the inquiry '
        'is accepted.',
      );
    });
  });

  group('InquiryThreadCubit contact', () {
    InquiryThreadCubit build(_ShareRepo repo, String uid) => InquiryThreadCubit(
      inquiryId: repo.inquiry.inquiryId,
      uid: uid,
      repository: repo,
      service: InquiryService(repository: repo),
    );

    test('accepted thread shares my phone and follows the counterpart', () async {
      final repo = _ShareRepo(_accepted());
      final cubit = build(repo, kTenant);
      await pumpEventQueue();

      expect(repo.shares.keys, ['tenant']);
      expect(cubit.state.counterpartPhone, isNull);

      repo.shareCtrls['owner']!.add(const ContactShareDoc(phone: '0999'));
      await pumpEventQueue();
      expect(cubit.state.counterpartPhone, '0999');

      repo.shareCtrls['owner']!.add(null);
      await pumpEventQueue();
      expect(cubit.state.counterpartPhone, isNull);
      await cubit.close();
    });

    test('a pending thread shares and watches nothing', () async {
      final repo = _ShareRepo(threadFor(kProp1, initiatedBy: 'tenant'));
      final cubit = build(repo, kOwner);
      await pumpEventQueue();
      expect(repo.writes, 0);
      expect(repo.shareCtrls, isEmpty);
      expect(cubit.state.counterpartPhone, isNull);
      await cubit.close();
    });

    test('the thread unlocking live starts sharing exactly once', () async {
      final repo = _ShareRepo(threadFor(kProp1, initiatedBy: 'tenant'));
      final cubit = build(repo, kTenant);
      await pumpEventQueue();
      expect(repo.writes, 0);

      repo.inquiryCtrl.add(_accepted());
      repo.inquiryCtrl.add(_accepted());
      await pumpEventQueue();
      expect(repo.writes, 1);
      await cubit.close();
    });
  });

  group('contact widgets', () {
    Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

    testWidgets('ContactRow is absent without a phone', (tester) async {
      await tester.pumpWidget(host(const ContactRow(phone: null)));
      expect(find.text('Contact'), findsNothing);
      await tester.pumpWidget(host(const ContactRow(phone: '  ')));
      expect(find.text('Contact'), findsNothing);
    });

    testWidgets('ContactRow shows the phone; Call opens a tel: link', (
      tester,
    ) async {
      final opener = _Opener();
      await tester.pumpWidget(
        host(ContactRow(phone: '0917 123 4567', urlOpener: opener)),
      );
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('0917 123 4567'), findsOneWidget);

      await tester.tap(find.byTooltip('Call'));
      await tester.pump();
      expect(opener.opened?.scheme, 'tel');
      expect(opener.opened?.path, '09171234567');
    });

    testWidgets('Copy puts the number on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(host(const ContactRow(phone: '0917')));
      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();
      expect(copied, '0917');
      expect(find.text('Phone number copied.'), findsOneWidget);
    });

    testWidgets('consent notice names who the phone goes to', (tester) async {
      await tester.pumpWidget(
        host(const ContactConsentNotice(sharedWith: 'the tenant')),
      );
      expect(
        find.text(
          'Your phone number will be shared with the tenant once the inquiry '
          'is accepted.',
        ),
        findsOneWidget,
      );
    });
  });
}
