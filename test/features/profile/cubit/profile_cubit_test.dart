import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/inquiry/domain/repositories/inquiry_repository.dart';
import 'package:rentease/features/profile/cubit/profile_cubit.dart';

class _FakeRepo implements InquiryRepository {
  _FakeRepo({this.user});
  final UserDoc? user;
  final inquiries = StreamController<List<InquiryDoc>>.broadcast();

  @override
  Future<UserDoc?> fetchUser(String uid) async => user;

  @override
  Stream<List<InquiryDoc>> watchTenantInquiries(String tenantId) =>
      inquiries.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

InquiryDoc _inq(String id) => InquiryDoc(
  inquiryId: id,
  matchId: id,
  tenantId: 't',
  ownerId: 'o',
  propertyId: 'p',
  tenantCiSnapshot: 0.5,
  stage: 1,
  initiatedBy: 'tenant',
  status: 'pending',
  ownerDecision: 'pending',
  autoInfoSent: true,
);

void main() {
  test('loads the real name, photo and inquiry count', () async {
    final repo = _FakeRepo(
      user: const UserDoc(
        userId: 't',
        firstName: 'Ana',
        lastName: 'Reyes',
        email: 'a@b.c',
        gender: 'Female',
        phone: '0',
        role: 'tenant',
        status: 'active',
        profilePhoto: 'https://example.com/a.png',
      ),
    );
    final cubit = ProfileCubit(uid: 't', repository: repo);
    repo.inquiries.add([_inq('1'), _inq('2')]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.fullName, 'Ana Reyes');
    expect(cubit.state.photoUrl, 'https://example.com/a.png');
    expect(cubit.state.inquiryCount, 2);
    await cubit.close();
  });

  test('missing user doc keeps the neutral defaults', () async {
    final repo = _FakeRepo();
    final cubit = ProfileCubit(uid: 't', repository: repo);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.fullName, '');
    expect(cubit.state.inquiryCount, 0);
    await cubit.close();
  });

  test('without uid/repository (guest) nothing is loaded', () {
    final cubit = ProfileCubit();
    expect(cubit.state.fullName, '');
  });
}
