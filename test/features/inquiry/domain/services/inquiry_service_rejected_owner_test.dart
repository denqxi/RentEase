import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/inquiry/domain/services/inquiry_service.dart';

import '../../fake_invite_repository.dart';

class _Repo extends FakeInviteRepository {
  final messages = <MessageDoc>[];
  final bookings = <String>[];
  final shares = <String>[];

  @override
  Future<void> addMessage(String inquiryId, MessageDoc message) async =>
      messages.add(message);

  @override
  Future<void> commitBooking({
    required String inquiryId,
    required String propertyId,
    required bool fillsLastVacancy,
    required List<String> otherInquiryIds,
  }) async => bookings.add(inquiryId);

  @override
  Future<ContactShareDoc?> fetchContactShare(String inquiryId, String role) async =>
      null;

  @override
  Future<UserContactDoc?> fetchOwnContact(String uid) async =>
      UserContactDoc(phone: '+639171234567');

  @override
  Future<void> writeContactShare(
    String inquiryId,
    String role,
    ContactShareDoc share,
  ) async => shares.add(role);
}

void main() {
  late _Repo repo;
  late InquiryService service;

  setUp(() {
    repo = _Repo()
      ..ownerStatus = 'rejected'
      ..matches = [matchFor(kProp1)]
      ..properties = {kProp1: propertyFor(kProp1)};
    service = InquiryService(repository: repo, notifications: FakeNotifications());
  });

  final pending = threadFor(kProp1, initiatedBy: 'tenant');
  final active = threadFor(
    kProp1,
    initiatedBy: 'tenant',
    stage: 2,
    status: 'active',
    decision: 'accepted',
  );

  test('inviteOptions is empty (button absent) for a rejected owner', () async {
    expect(await service.inviteOptions(ownerId: kOwner, tenantId: kTenant), isEmpty);
  });

  test('sendInvite fails fast with the friendly message and writes nothing', () async {
    await expectLater(
      service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1)),
      throwsA(
        isA<InquiryException>().having(
          (e) => e.message,
          'message',
          InquiryService.rejectedOwnerMessage,
        ),
      ),
    );
    expect(repo.created, isEmpty);
  });

  test('accept, decline, markBooked are refused', () async {
    await expectLater(
      service.accept(inquiry: pending, ownerId: kOwner),
      throwsA(isA<InquiryException>()),
    );
    await expectLater(
      service.decline(inquiry: pending, ownerId: kOwner),
      throwsA(isA<InquiryException>()),
    );
    await expectLater(
      service.markBooked(inquiry: active, ownerId: kOwner),
      throwsA(isA<InquiryException>()),
    );
    expect(repo.updates, isEmpty);
    expect(repo.bookings, isEmpty);
  });

  test('owner cannot message; tenant gets the neutral note', () async {
    await expectLater(
      service.sendMessage(inquiry: active, senderId: kOwner, content: 'hi'),
      throwsA(
        isA<InquiryException>().having(
          (e) => e.message,
          'message',
          InquiryService.rejectedOwnerMessage,
        ),
      ),
    );
    await expectLater(
      service.sendMessage(inquiry: active, senderId: kTenant, content: 'hi'),
      throwsA(
        isA<InquiryException>().having(
          (e) => e.message,
          'message',
          InquiryService.rejectedOwnerTenantNote,
        ),
      ),
    );
    expect(repo.messages, isEmpty);
  });

  test('owner contact is not shared, tenant contact still is', () async {
    await service.shareMyContact(inquiry: active, uid: kOwner);
    expect(repo.shares, isEmpty);
    await service.shareMyContact(inquiry: active, uid: kTenant);
    expect(repo.shares, ['tenant']);
  });

  for (final status in ['none', 'pending', 'verified']) {
    test('$status owner can still invite, answer and chat', () async {
      repo.ownerStatus = status;
      expect(
        await service.inviteOptions(ownerId: kOwner, tenantId: kTenant),
        isNotEmpty,
      );
      await service.sendInvite(ownerId: kOwner, matchId: matchIdFor(kProp1));
      await service.accept(inquiry: pending, ownerId: kOwner);
      await service.sendMessage(inquiry: active, senderId: kOwner, content: 'hi');
      expect(repo.messages, hasLength(1));
    });
  }
}
