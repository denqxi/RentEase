import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/inquiry/cubit/invite_cubit.dart';
import 'package:rentease/features/inquiry/domain/services/inquiry_service.dart';

import '../fake_invite_repository.dart';

InviteCubit _cubit(FakeInviteRepository repo, {String? propertyId}) =>
    InviteCubit(
      ownerId: kOwner,
      tenantId: kTenant,
      propertyId: propertyId,
      service: InquiryService(
        repository: repo,
        notifications: FakeNotifications(),
      ),
    );

void main() {
  late FakeInviteRepository repo;

  setUp(() {
    repo = FakeInviteRepository()
      ..matches = [matchFor(kProp1), matchFor(kProp2)]
      ..properties = {kProp1: propertyFor(kProp1), kProp2: propertyFor(kProp2)};
  });

  test('loads the options and allows inviting', () async {
    final cubit = _cubit(repo);
    await cubit.stream.firstWhere((s) => !s.isLoading);
    expect(cubit.state.canInvite, isTrue);
    expect(cubit.state.options, hasLength(2));
    await cubit.close();
  });

  test('an unverified owner can still invite (canInvite true)', () async {
    repo.ownerStatus = 'pending';
    final cubit = _cubit(repo);
    await cubit.stream.firstWhere((s) => !s.isLoading);
    expect(cubit.state.canInvite, isTrue);
    await cubit.close();
  });

  test('a rejected owner cannot invite (canInvite false, button absent)', () async {
    repo.ownerStatus = 'rejected';
    final cubit = _cubit(repo);
    await cubit.stream.firstWhere((s) => !s.isLoading);
    expect(cubit.state.canInvite, isFalse);
    expect(cubit.state.options, isEmpty);
    await cubit.close();
  });

  test('absent when the tenant already has a thread for every property', () async {
    repo.threads = [threadFor(kProp1), threadFor(kProp2, initiatedBy: 'tenant')];
    final cubit = _cubit(repo);
    await cubit.stream.firstWhere((s) => !s.isLoading);
    expect(cubit.state.canInvite, isFalse);
    await cubit.close();
  });

  test('sending removes that option and reports the property title', () async {
    final cubit = _cubit(repo);
    await cubit.stream.firstWhere((s) => !s.isLoading);

    final ok = await cubit.send(cubit.state.options.first);

    expect(ok, isTrue);
    expect(repo.created.single.propertyId, kProp1);
    expect(cubit.state.options.map((o) => o.propertyId), [kProp2]);
    expect(cubit.state.sentTitle, 'House $kProp1');
    expect(cubit.state.isSending, isFalse);
    await cubit.close();
  });

  test('a double tap sends only one invitation', () async {
    final cubit = _cubit(repo);
    await cubit.stream.firstWhere((s) => !s.isLoading);
    final option = cubit.state.options.first;

    final results = await Future.wait([cubit.send(option), cubit.send(option)]);

    expect(results, [true, false]);
    expect(repo.created, hasLength(1));
    await cubit.close();
  });

  test('a rejected send surfaces a readable error and keeps the option', () async {
    final cubit = _cubit(repo);
    await cubit.stream.firstWhere((s) => !s.isLoading);
    repo.matches = [matchFor(kProp1, bScore: 0), matchFor(kProp2, bScore: 0)];

    final ok = await cubit.send(cubit.state.options.first);

    expect(ok, isFalse);
    expect(cubit.state.errorMessage, contains('compatible'));
    expect(cubit.state.options, hasLength(2));
    await cubit.close();
  });

  blocTest<InviteCubit, InviteState>(
    'restricts to the given property',
    build: () => _cubit(repo, propertyId: kProp2),
    wait: const Duration(milliseconds: 50),
    verify: (cubit) =>
        expect(cubit.state.options.map((o) => o.propertyId), [kProp2]),
  );
}
