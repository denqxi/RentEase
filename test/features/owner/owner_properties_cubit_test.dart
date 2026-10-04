import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/owner/cubit/owner_properties_cubit.dart';
import 'package:rentease/features/owner/domain/repositories/owner_property_repository.dart';

PropertyDoc _prop({bool unlisted = false}) => PropertyDoc(
  propertyId: 'p1',
  ownerId: 'o1',
  title: 't',
  address: 'a',
  location: const GeoPoint(0, 0),
  geoHash: '',
  photos: const ['u1'],
  monthlyRent: 3000,
  depositAmount: 3000,
  advanceMonths: 1,
  isAvailable: !unlisted,
  vacancyStatus: 'available',
  isVerified: true,
  allowedGender: 'Mixed / Any',
  smokingAllowed: false,
  petsAllowed: false,
  maxOccupants: 1,
  hasWifi: false,
  amenityList: const [],
  adminUnlisted: unlisted,
);

class _Repo implements OwnerPropertyRepository {
  final props = StreamController<List<PropertyDoc>>.broadcast();
  final updates = <Map<String, dynamic>>[];

  @override
  Stream<List<PropertyDoc>> watchOwnerProperties(String o) => props.stream;
  @override
  Stream<String> watchVerificationStatus(String o) => const Stream.empty();
  @override
  Stream<int> watchOpenInquiryCount(String o) => const Stream.empty();
  @override
  Future<UserDoc?> fetchUser(String uid) async => null;
  @override
  Future<void> publishListings(Iterable<String> ids) async {}
  @override
  Future<void> updateProperty(String id, Map<String, dynamic> f) async =>
      updates.add(f);
}

void main() {
  test('setVacancy on an admin-unlisted property is blocked with a message',
      () async {
    final repo = _Repo();
    final cubit = OwnerPropertiesCubit(ownerId: 'o1', repository: repo);
    repo.props.add([_prop(unlisted: true)]);
    await Future<void>.delayed(Duration.zero);
    await cubit.setVacancy('p1', 'available');
    expect(repo.updates, isEmpty);
    expect(cubit.state.errorMessage, adminUnlistedMessage);
    await cubit.close();
  });

  test('setVacancy on a normal property writes', () async {
    final repo = _Repo();
    final cubit = OwnerPropertiesCubit(ownerId: 'o1', repository: repo);
    repo.props.add([_prop()]);
    await Future<void>.delayed(Duration.zero);
    await cubit.setVacancy('p1', 'booked');
    expect(repo.updates.single['isAvailable'], false);
    await cubit.close();
  });

  test('ownerPropertyErrorMessage maps codes', () {
    expect(
      ownerPropertyErrorMessage('permission-denied', {'isAvailable': true}),
      adminUnlistedMessage,
    );
    expect(
      ownerPropertyErrorMessage('permission-denied', {'title': 'x'}),
      contains("can't edit"),
    );
    expect(
      ownerPropertyErrorMessage('unavailable', {}),
      contains('No connection'),
    );
    expect(ownerPropertyErrorMessage('weird', {}), contains('Could not save'));
  });

  test('PropertyDoc adminUnlisted round-trips', () {
    final m = _prop(unlisted: true).toMap()
      ..remove('createdAt')
      ..remove('updatedAt');
    expect(m['adminUnlisted'], true);
    expect(PropertyDoc.fromMap('p1', m).adminUnlisted, true);
    expect(_prop().toMap().containsKey('adminUnlisted'), false);
  });
}
