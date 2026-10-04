import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/admin/cubit/admin_login_cubit.dart';
import 'package:rentease/features/admin/cubit/analytics_cubit.dart';
import 'package:rentease/features/admin/cubit/properties_cubit.dart';
import 'package:rentease/features/admin/cubit/users_cubit.dart';
import 'package:rentease/features/admin/cubit/verifications_cubit.dart';
import 'package:rentease/features/admin/domain/entities/admin_entities.dart';
import 'package:rentease/features/admin/domain/repositories/admin_repository.dart';

class _FakeRepo implements AdminRepository {
  final verifications = StreamController<List<VerificationItem>>.broadcast();
  final users = StreamController<List<UserDoc>>.broadcast();
  final properties = StreamController<List<AdminPropertyItem>>.broadcast();
  final calls = <String>[];
  AdminException? failWith;
  AdminStats stats = const AdminStats(tenants: 3, owners: 2);

  Future<void> _record(String call) async {
    calls.add(call);
    if (failWith != null) throw failWith!;
  }

  @override
  Future<void> signIn(String email, String password) =>
      _record('signIn:$email');

  @override
  Future<void> signOut() => _record('signOut');

  @override
  Stream<List<VerificationItem>> watchVerifications() => verifications.stream;

  @override
  Future<VerificationDocuments> fetchDocuments(String ownerId) async {
    calls.add('docs:$ownerId');
    return const VerificationDocuments(
      urls: ['u1', 'u2'],
      publicIds: ['a', 'b'],
    );
  }

  @override
  Future<void> approveOwner(String ownerId) => _record('approve:$ownerId');

  @override
  Future<void> rejectOwner(String ownerId, {String? reason}) =>
      _record('reject:$ownerId:$reason');

  @override
  Stream<List<UserDoc>> watchUsers() => users.stream;

  @override
  Future<void> setUserSuspended(String userId, {required bool suspended}) =>
      _record('suspend:$userId:$suspended');

  @override
  Stream<List<AdminPropertyItem>> watchProperties() => properties.stream;

  @override
  Future<void> setPropertyListed(String propertyId, {required bool listed}) =>
      _record('listed:$propertyId:$listed');

  @override
  Future<AdminStats> fetchStats() async => stats;

  @override
  Stream<List<AdminLogDoc>> watchRecentLogs({int limit = 5}) =>
      Stream.value(const []);
}

VerificationItem _v(String id, String status) => VerificationItem(
  profile: OwnerProfileDoc(
    userId: id,
    verificationStatus: status,
    submittedAt: Timestamp.fromMillisecondsSinceEpoch(1000),
  ),
  ownerName: 'Owner $id',
);

UserDoc _u(String id, String role, String status, String first) => UserDoc(
  userId: id,
  firstName: first,
  lastName: 'Test',
  email: '$first@example.com',
  gender: '',
  phone: '',
  role: role,
  status: status,
);

PropertyDoc _p(String id, {bool available = true}) => PropertyDoc(
  propertyId: id,
  ownerId: 'o1',
  title: 'House $id',
  address: 'Matina',
  location: const GeoPoint(7.0, 125.5),
  geoHash: '',
  photos: const [],
  monthlyRent: 3500,
  depositAmount: 0,
  advanceMonths: 1,
  isAvailable: available,
  vacancyStatus: 'available',
  isVerified: false,
  allowedGender: 'any',
  smokingAllowed: false,
  petsAllowed: false,
  maxOccupants: 2,
  hasWifi: true,
  amenityList: const [],
);

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepo repo;
  setUp(() => repo = _FakeRepo());

  group('VerificationsCubit', () {
    test('loads items and filters by status', () async {
      final cubit = VerificationsCubit(repo)..start();
      expect(cubit.state.isLoading, isTrue);
      repo.verifications.add([_v('a', 'pending'), _v('b', 'verified')]);
      await _pump();
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.visible.map((e) => e.ownerId), ['a']);
      cubit.setFilter('all');
      expect(cubit.state.visible.length, 2);
      expect(cubit.state.countOf('verified'), 1);
      await cubit.close();
    });

    test('approve and reject call the repository and raise a notice', () async {
      final cubit = VerificationsCubit(repo)..start();
      await cubit.approve('a');
      expect(repo.calls, ['approve:a']);
      expect(cubit.state.notice, contains('approved'));
      expect(cubit.state.busyIds, isEmpty);
      final seq = cubit.state.noticeSeq;
      await cubit.reject('b', reason: 'Blurry');
      expect(repo.calls.last, 'reject:b:Blurry');
      expect(cubit.state.noticeSeq, seq + 1);
      await cubit.close();
    });

    test('a failure surfaces the friendly message and clears busy', () async {
      repo.failWith = const AdminException('You do not have permission.');
      final cubit = VerificationsCubit(repo)..start();
      await cubit.approve('a');
      expect(cubit.state.notice, 'You do not have permission.');
      expect(cubit.state.busyIds, isEmpty);
      await cubit.close();
    });

    test('documents are fetched once per owner', () async {
      final cubit = VerificationsCubit(repo)..start();
      await cubit.loadDocuments('a');
      await cubit.loadDocuments('a');
      expect(repo.calls.where((c) => c == 'docs:a').length, 1);
      expect(cubit.state.documents['a']!.publicIds, ['a', 'b']);
      await cubit.close();
    });

    test('stream error shows an error state', () async {
      final cubit = VerificationsCubit(repo)..start();
      repo.verifications.addError(const AdminException('nope'));
      await _pump();
      expect(cubit.state.errorMessage, 'nope');
      expect(cubit.state.isLoading, isFalse);
      await cubit.close();
    });
  });

  group('UsersCubit', () {
    test('tabs and search filter', () async {
      final cubit = UsersCubit(repo)..start();
      repo.users.add([
        _u('1', 'tenant', 'active', 'maria'),
        _u('2', 'owner', 'suspended', 'carlos'),
      ]);
      await _pump();
      expect(cubit.state.filtered('all').length, 2);
      expect(cubit.state.filtered('tenant').single.userId, '1');
      expect(cubit.state.filtered('suspended').single.userId, '2');
      cubit.setQuery('CARL');
      expect(cubit.state.filtered('all').single.userId, '2');
      await cubit.close();
    });

    test('suspend calls the repository', () async {
      final cubit = UsersCubit(repo)..start();
      await cubit.setSuspended('2', suspended: true);
      expect(repo.calls, ['suspend:2:true']);
      expect(cubit.state.notice, 'Account suspended.');
      await cubit.close();
    });
  });

  group('AdminPropertiesCubit', () {
    test('active and unlisted tabs', () async {
      final cubit = AdminPropertiesCubit(repo)..start();
      repo.properties.add([
        AdminPropertyItem(property: _p('a'), ownerName: 'X'),
        AdminPropertyItem(
          property: _p('b', available: false),
          ownerName: 'Y',
          adminUnlisted: true,
        ),
      ]);
      await _pump();
      expect(cubit.state.filtered('active').single.property.propertyId, 'a');
      expect(cubit.state.filtered('unlisted').single.property.propertyId, 'b');
      cubit.setQuery('y');
      expect(cubit.state.filtered('all').single.property.propertyId, 'b');
      await cubit.close();
    });

    test('unlist calls the repository', () async {
      final cubit = AdminPropertiesCubit(repo)..start();
      await cubit.setListed('a', listed: false);
      expect(repo.calls, ['listed:a:false']);
      expect(cubit.state.notice, 'Listing unlisted.');
      await cubit.close();
    });
  });

  group('AnalyticsCubit', () {
    test('loads real stats', () async {
      final cubit = AnalyticsCubit(repo);
      await cubit.start();
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.stats!.totalUsers, 5);
      await cubit.close();
    });
  });

  group('AdminLoginCubit', () {
    test('success', () async {
      final cubit = AdminLoginCubit(repo);
      await cubit.signIn('a@b.c', 'pw');
      expect(cubit.state.isSignedIn, isTrue);
      await cubit.close();
    });

    test('failure shows the message', () async {
      repo.failWith = const AdminException(
        'This account is not an administrator.',
      );
      final cubit = AdminLoginCubit(repo);
      await cubit.signIn('a@b.c', 'pw');
      expect(cubit.state.isSignedIn, isFalse);
      expect(cubit.state.errorMessage, 'This account is not an administrator.');
      await cubit.close();
    });
  });
}
