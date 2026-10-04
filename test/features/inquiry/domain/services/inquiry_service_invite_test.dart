import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/inquiry/domain/services/inquiry_service.dart';

import '../../fake_invite_repository.dart';

void main() {
  late FakeInviteRepository repo;
  late FakeNotifications notes;
  late InquiryService service;

  setUp(() {
    repo = FakeInviteRepository()
      ..matches = [matchFor(kProp1)]
      ..properties = {kProp1: propertyFor(kProp1)};
    notes = FakeNotifications();
    service = InquiryService(repository: repo, notifications: notes);
  });

  group('inviteOptions', () {
    test('offers each available compatible property', () async {
      repo
        ..matches = [matchFor(kProp1), matchFor(kProp2)]
        ..properties = {kProp1: propertyFor(kProp1), kProp2: propertyFor(kProp2)};
      final options = await service.inviteOptions(
        ownerId: kOwner,
        tenantId: kTenant,
      );
      expect(options.map((o) => o.propertyId), [kProp1, kProp2]);
      expect(options.first.matchId, matchIdFor(kProp1));
    });

    test('narrows to the given property', () async {
      repo
        ..matches = [matchFor(kProp1), matchFor(kProp2)]
        ..properties = {kProp1: propertyFor(kProp1), kProp2: propertyFor(kProp2)};
      final options = await service.inviteOptions(
        ownerId: kOwner,
        tenantId: kTenant,
        propertyId: kProp2,
      );
      expect(options.map((o) => o.propertyId), [kProp2]);
    });

    test('is not gated by owner verification status', () async {
      for (final status in ['none', 'pending', 'verified']) {
        repo.ownerStatus = status;
        expect(
          await service.inviteOptions(ownerId: kOwner, tenantId: kTenant),
          isNotEmpty,
          reason: status,
        );
      }
    });

    test('drops bScore != 1, foreign, unavailable and missing properties', () async {
      repo
        ..matches = [
          matchFor(kProp1, bScore: 0),
          matchFor(kProp2),
          matchFor('prop3'),
          matchFor('prop4'),
        ]
        ..properties = {
          kProp1: propertyFor(kProp1),
          kProp2: propertyFor(kProp2, isAvailable: false),
          'prop3': propertyFor('prop3', ownerId: 'someoneElse'),
        };
      expect(
        await service.inviteOptions(ownerId: kOwner, tenantId: kTenant),
        isEmpty,
      );
    });

    test('drops a property that already has any thread with the tenant', () async {
      repo.threads = [threadFor(kProp1, initiatedBy: 'tenant', status: 'declined')];
      expect(
        await service.inviteOptions(ownerId: kOwner, tenantId: kTenant),
        isEmpty,
      );
    });
  });

  group('sendInvite', () {
    test('creates a stage-1 pending owner-initiated thread keyed by match id', () async {
      final id = await service.sendInvite(
        ownerId: kOwner,
        matchId: matchIdFor(kProp1),
      );
      expect(id, matchIdFor(kProp1));
      final doc = repo.created.single;
      expect(doc.initiatedBy, 'owner');
      expect(doc.tenantId, kTenant);
      expect(doc.ownerId, kOwner);
      expect(doc.propertyId, kProp1);
      expect(doc.stage, 1);
      expect(doc.status, 'pending');
      expect(doc.ownerDecision, 'pending');
    });

    test('notifies the tenant with the invitation type', () async {
      await service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1));
      expect(notes.created.single.type, 'invitation');
      expect(notes.created.single.recipientId, kTenant);
    });

    test('allows an unverified (pending) owner', () async {
      repo.ownerStatus = 'pending';
      await service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1));
      expect(repo.created, hasLength(1));
    });

    test('refuses bScore 0, a missing match and another owner\'s match', () async {
      repo.matches = [matchFor(kProp1, bScore: 0)];
      await expectLater(
        service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1)),
        throwsA(isA<InquiryException>()),
      );
      await expectLater(
        service.sendInvite(ownerId: kOwner, matchId: 'missing'),
        throwsA(isA<InquiryException>()),
      );
      repo.matches = [matchFor(kProp1, ownerId: 'other')];
      await expectLater(
        service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1)),
        throwsA(isA<InquiryException>()),
      );
      expect(repo.created, isEmpty);
    });

    test('refuses an unavailable property', () {
      repo.properties = {kProp1: propertyFor(kProp1, isAvailable: false)};
      expect(
        service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1)),
        throwsA(isA<InquiryException>()),
      );
    });

    test('refuses when the tenant already has a thread for the property', () {
      repo.threads = [threadFor(kProp1, initiatedBy: 'tenant')];
      expect(
        service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1)),
        throwsA(isA<InquiryException>()),
      );
    });

    test('a failing notification never breaks the invite', () async {
      final svc = InquiryService(
        repository: repo,
        notifications: FakeNotifications(fail: true),
      );
      await svc.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1));
      expect(repo.created, hasLength(1));
    });
  });

  group('tenant answers an invitation', () {
    test('accept opens Phase 2 and notifies the owner', () async {
      await service.acceptInvite(inquiry: threadFor(kProp1), tenantId: kTenant);
      expect(repo.updates.single, {
        'stage': 2,
        'ownerDecision': 'accepted',
        'status': 'active',
      });
      expect(notes.created.single.type, 'invitation_accepted');
      expect(notes.created.single.recipientId, kOwner);
    });

    test('decline closes the thread with an optional reason', () async {
      await service.declineInvite(
        inquiry: threadFor(kProp1),
        tenantId: kTenant,
        reason: ' not now ',
      );
      expect(repo.updates.single, {
        'ownerDecision': 'declined',
        'status': 'declined',
        'declineReason': 'not now',
      });
      expect(notes.created.single.type, 'invitation_declined');
    });

    test('only the invited tenant, only once, only for invitations', () async {
      await expectLater(
        service.acceptInvite(inquiry: threadFor(kProp1), tenantId: 'x'),
        throwsA(isA<InquiryException>()),
      );
      await expectLater(
        service.acceptInvite(
          inquiry: threadFor(kProp1, stage: 2, decision: 'accepted', status: 'active'),
          tenantId: kTenant,
        ),
        throwsA(isA<InquiryException>()),
      );
      await expectLater(
        service.acceptInvite(
          inquiry: threadFor(kProp1, initiatedBy: 'tenant'),
          tenantId: kTenant,
        ),
        throwsA(isA<InquiryException>()),
      );
      expect(repo.updates, isEmpty);
    });

    test('the owner cannot accept or decline their own invitation', () async {
      await expectLater(
        service.accept(inquiry: threadFor(kProp1), ownerId: kOwner),
        throwsA(isA<InquiryException>()),
      );
      await expectLater(
        service.decline(inquiry: threadFor(kProp1), ownerId: kOwner),
        throwsA(isA<InquiryException>()),
      );
      expect(repo.updates, isEmpty);
    });
  });
}
