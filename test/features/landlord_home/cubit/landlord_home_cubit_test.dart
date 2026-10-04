import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/landlord_home/cubit/landlord_home_cubit.dart';
import 'package:rentease/features/owner/domain/repositories/find_tenants_repository.dart';
import 'package:rentease/features/owner/domain/repositories/owner_property_repository.dart';
import 'package:rentease/features/owner/model/compatible_tenant.dart';
import 'package:rentease/features/owner/model/owner_listing.dart';

PropertyDoc _property(String id, {bool available = true}) =>
    PropertyDoc.fromMap(id, {
      'ownerId': 'o1',
      'title': 'House $id',
      'isAvailable': available,
      'vacancyStatus': available ? 'available' : 'booked',
    });

CompatibleTenant _tenant(String id, String name) => CompatibleTenant(
  matchId: 'm$id',
  tenantId: id,
  name: name,
  gender: 'Female',
  maxBudget: 4000,
  bScore: 1,
);

class _FakeOwnerRepo implements OwnerPropertyRepository {
  final properties = StreamController<List<PropertyDoc>>.broadcast();
  final status = StreamController<String>.broadcast();
  UserDoc? user;

  @override
  Stream<List<PropertyDoc>> watchOwnerProperties(String ownerId) =>
      properties.stream;

  @override
  Stream<String> watchVerificationStatus(String ownerId) => status.stream;

  @override
  Future<UserDoc?> fetchUser(String uid) async => user;

  @override
  Stream<int> watchOpenInquiryCount(String ownerId) => const Stream.empty();

  @override
  Future<void> publishListings(Iterable<String> propertyIds) async {}

  @override
  Future<void> updateProperty(String id, Map<String, dynamic> f) async {}
}

class _FakeTenantsRepo implements FindTenantsRepository {
  final Map<String, List<CompatibleTenant>> byProperty = {};
  final calls = <String>[];
  bool fail = false;

  @override
  Future<List<OwnerListing>> fetchOwnerListings(String ownerId) async => [];

  @override
  Future<List<CompatibleTenant>> fetchCompatibleTenants({
    required String ownerId,
    required String propertyId,
  }) async {
    calls.add(propertyId);
    if (fail) throw Exception('boom');
    return byProperty[propertyId] ?? [];
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeOwnerRepo owner;
  late _FakeTenantsRepo tenants;

  LandlordHomeCubit build() => LandlordHomeCubit(
    ownerId: 'o1',
    propertyRepository: owner,
    tenantsRepository: tenants,
  );

  setUp(() {
    owner = _FakeOwnerRepo();
    tenants = _FakeTenantsRepo();
  });

  test('signed-out cubit is empty and not loading', () {
    final cubit = LandlordHomeCubit();
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.properties, isEmpty);
    cubit.close();
  });

  test('loads account name, properties and verification status', () async {
    owner.user = UserDoc.fromMap('o1', {
      'firstName': 'Ana',
      'lastName': 'Reyes',
    });
    final cubit = build();
    expect(cubit.state.isLoading, isTrue);
    await _settle();
    owner.properties.add([_property('a'), _property('b', available: false)]);
    owner.status.add('pending');
    await _settle();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.firstName, 'Ana');
    expect(cubit.state.fullName, 'Ana Reyes');
    expect(cubit.state.properties, hasLength(2));
    expect(cubit.state.availableCount, 1);
    expect(cubit.state.showPendingBanner, isTrue);
    await cubit.close();
  });

  for (final status in ['none', 'pending', 'rejected']) {
    test('$status owner still loads compatible tenants', () async {
      tenants.byProperty['a'] = [_tenant('t1', 'Zed')];
      final cubit = build();
      owner.properties.add([_property('a')]);
      owner.status.add(status);
      await _settle();
      await _settle();
      expect(tenants.calls, ['a']);
      expect(cubit.state.tenants.map((t) => t.name), ['Zed']);
      await cubit.close();
    });
  }

  test('verified owner: tenants deduped and alphabetical, not ranked', () async {
    tenants.byProperty['a'] = [_tenant('t2', 'zara'), _tenant('t1', 'Ben')];
    tenants.byProperty['b'] = [_tenant('t1', 'Ben'), _tenant('t3', 'Ana')];
    final cubit = build();
    owner.properties.add([_property('a'), _property('b')]);
    owner.status.add('verified');
    await _settle();
    await _settle();
    expect(cubit.state.showPendingBanner, isFalse);
    expect(cubit.state.tenants.map((t) => t.name), ['Ana', 'Ben', 'zara']);
    await cubit.close();
  });

  test('unavailable properties are not queried; none available -> empty',
      () async {
    final cubit = build();
    owner.properties.add([_property('a', available: false)]);
    owner.status.add('verified');
    await _settle();
    expect(tenants.calls, isEmpty);
    expect(cubit.state.tenants, isEmpty);
    expect(cubit.state.tenantsLoading, isFalse);
    await cubit.close();
  });

  test('tenant load failure sets tenantsError and retry recovers', () async {
    tenants.fail = true;
    final cubit = build();
    owner.properties.add([_property('a')]);
    owner.status.add('verified');
    await _settle();
    await _settle();
    expect(cubit.state.tenantsError, isNotNull);

    tenants.fail = false;
    tenants.byProperty['a'] = [_tenant('t1', 'Ben')];
    await cubit.reloadTenants();
    expect(cubit.state.tenantsError, isNull);
    expect(cubit.state.tenants, hasLength(1));
    await cubit.close();
  });

  test('stream error surfaces errorMessage; retry clears it', () async {
    final cubit = build();
    owner.properties.addError(Exception('denied'));
    await _settle();
    expect(cubit.state.errorMessage, isNotNull);
    expect(cubit.state.isLoading, isFalse);
    cubit.retry();
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.isLoading, isTrue);
    await cubit.close();
  });
}
