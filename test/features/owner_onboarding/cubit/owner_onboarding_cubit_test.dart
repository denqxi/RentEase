import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/owner_onboarding/cubit/owner_onboarding_cubit.dart';
import 'package:rentease/features/owner_onboarding/domain/repositories/owner_onboarding_repository.dart';
import 'package:rentease/features/uploads/domain/entities/uploaded_image.dart';

class _FakeRepo implements OwnerOnboardingRepository {
  List<UploadedImage>? submitted;

  @override
  Future<String> submitForVerification(
    String uid, {
    List<UploadedImage> documents = const [],
  }) async {
    submitted = documents;
    return 'pending';
  }

  @override
  Stream<String> watchVerificationStatus(String uid) => const Stream.empty();

  PropertyDoc? created;
  List<PropertyDoc> existing = const [];

  @override
  Future<String> createProperty(PropertyDoc property) async {
    created = property;
    return 'p1';
  }

  @override
  Future<List<PropertyDoc>> fetchOwnerProperties(String ownerId) async =>
      existing;
}

PropertyDoc _doc({
  String rentalType = 'entire_place',
  String? parent,
  String? propertyName,
  String? roomName,
}) => PropertyDoc(
  propertyId: 'x',
  ownerId: 'u1',
  title: 't',
  address: 'a',
  location: const GeoPoint(7, 125),
  geoHash: '',
  photos: const [],
  monthlyRent: 1000,
  depositAmount: 0,
  advanceMonths: 1,
  isAvailable: true,
  vacancyStatus: 'available',
  isVerified: false,
  allowedGender: 'Mixed / Any',
  smokingAllowed: false,
  petsAllowed: false,
  maxOccupants: 1,
  hasWifi: false,
  amenityList: const [],
  rentalType: rentalType,
  parentPropertyId: parent,
  propertyName: propertyName,
  roomName: roomName,
);

void _fill(
  OwnerOnboardingCubit cubit, {
  required String rentalType,
  String? roomName,
  String? parent,
  List<String> amenities = const ['WiFi', 'Electric fan'],
}) {
  cubit.saveListing(
    rentalType: rentalType,
    propertyName: 'GL Boardinghouse',
    propertyType: 'House',
    roomName: roomName,
    parentPropertyId: parent,
    address: 'Davao',
    latitude: 7.07,
    longitude: 125.6,
    photos: _docs(1),
    depositAmount: 500,
    advanceMonths: 1,
    allowedGender: 'Mixed / Any',
    smokingAllowed: false,
    petsAllowed: false,
    curfewHours: null,
    maxOccupants: 2,
    monthlyRent: 3500,
    isAvailable: true,
    amenities: amenities,
  );
}


List<UploadedImage> _docs(int n) => [
  for (var i = 0; i < n; i++) UploadedImage(url: 'https://x/$i', publicId: 'id$i'),
];

void main() {
  group('submitForVerification', () {
    test('accepts two documents (business permit omitted)', () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      await cubit.submitForVerification('u1', documents: _docs(2));
      expect(cubit.state.status, OwnerOnboardingStatus.saved);
      expect(repo.submitted, hasLength(2));
    });

    test('accepts three documents', () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      await cubit.submitForVerification('u1', documents: _docs(3));
      expect(cubit.state.status, OwnerOnboardingStatus.saved);
      expect(repo.submitted, hasLength(3));
    });

    test('rejects fewer than two documents without touching the repo', () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      await cubit.submitForVerification('u1', documents: _docs(1));
      expect(cubit.state.status, OwnerOnboardingStatus.failure);
      expect(repo.submitted, isNull);
    });
  });

  group('create listing', () {
    test('entire place: no room/parent fields, amenityScore == list length',
        () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      _fill(cubit, rentalType: 'entire_place');
      await cubit.submitProperty(uid: 'u1');
      expect(cubit.state.status, OwnerOnboardingStatus.saved);
      final p = repo.created!;
      expect(p.rentalType, 'entire_place');
      expect(p.title, 'GL Boardinghouse');
      expect(p.roomName, isNull);
      expect(p.parentPropertyId, isNull);
      expect(p.curfewHours, isNull);
      expect(p.amenityScore, p.amenityList.length);
      expect(p.toMap().containsKey('parentPropertyId'), isFalse);
    });

    test('room: generated title, parent reference, own rent/occupants',
        () async {
      final repo = _FakeRepo();
      final cubit = OwnerOnboardingCubit(repository: repo);
      _fill(cubit, rentalType: 'room', roomName: 'Room 101', parent: 'b1');
      await cubit.submitProperty(uid: 'u1');
      expect(cubit.state.status, OwnerOnboardingStatus.saved);
      final p = repo.created!;
      expect(p.title, 'GL Boardinghouse – Room 101');
      expect(p.parentPropertyId, 'b1');
      expect(p.roomName, 'Room 101');
      expect(p.monthlyRent, 3500);
      expect(p.maxOccupants, 2);
      expect(p.amenityScore, 2);
    });

    test('duplicate room name in the same property is rejected', () async {
      final repo = _FakeRepo()
        ..existing = [
          _doc(rentalType: 'room', parent: 'b1', roomName: 'Room 101'),
        ];
      final cubit = OwnerOnboardingCubit(repository: repo);
      _fill(cubit, rentalType: 'room', roomName: ' room 101 ', parent: 'b1');
      await cubit.submitProperty(uid: 'u1');
      expect(cubit.state.status, OwnerOnboardingStatus.failure);
      expect(repo.created, isNull);
    });

    test('same room name in a different property is allowed', () async {
      final repo = _FakeRepo()
        ..existing = [
          _doc(rentalType: 'room', parent: 'b2', roomName: 'Room 101'),
        ];
      final cubit = OwnerOnboardingCubit(repository: repo);
      _fill(cubit, rentalType: 'room', roomName: 'Room 101', parent: 'b1');
      await cubit.submitProperty(uid: 'u1');
      expect(cubit.state.status, OwnerOnboardingStatus.saved);
    });

    test('legacy documents default to entire_place', () {
      final p = PropertyDoc.fromMap('id', const {'title': 'Old'});
      expect(p.rentalType, 'entire_place');
      expect(p.isRoom, isFalse);
    });
  });
}

