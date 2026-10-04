import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/home/cubit/home_cubit.dart';
import 'package:rentease/features/home/cubit/search_cubit.dart';
import 'package:rentease/features/home/domain/repositories/home_repository.dart';
import 'package:rentease/features/home/model/listing.dart';

PropertyDoc _property(String id, {num rent = 3500}) => PropertyDoc(
  propertyId: id,
  ownerId: 'owner1',
  title: 'House $id',
  address: 'Matina, Davao City',
  location: const GeoPoint(7.07, 125.6),
  geoHash: '',
  photos: const [],
  monthlyRent: rent,
  depositAmount: 3500,
  advanceMonths: 1,
  isAvailable: true,
  vacancyStatus: 'available',
  isVerified: true,
  allowedGender: 'Mixed / Any',
  smokingAllowed: false,
  petsAllowed: false,
  maxOccupants: 2,
  hasWifi: true,
  amenityList: const ['WiFi', 'CCTV'],
);

/// Only the guest methods exist; anything personalised throws, proving the
/// guest path never touches matches or tenant profiles.
class _GuestRepo implements HomeRepository {
  _GuestRepo({this.properties = const [], this.fail = false});

  final List<PropertyDoc> properties;
  final bool fail;
  int feedCalls = 0;

  @override
  Future<List<Listing>> fetchGuestListings({int limit = 20}) async {
    feedCalls++;
    if (fail) throw Exception('Network error. Check your connection.');
    return [
      for (final (i, p) in properties.indexed)
        Listing.fromProperty(property: p, imageSeed: i + 1),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGuestSearchResults({
    int limit = 20,
  }) async => [
    for (final p in properties)
      {'propertyId': p.propertyId, 'bScore': 0, 'isVerified': false},
  ];

  @override
  Future<Map<String, dynamic>?> fetchGuestPropertyDetail(String id) async =>
      {'propertyId': id, 'bScore': 0, 'isVerified': false};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('HomeCubit.guest', () {
    test('loads the public feed unranked, with no personalised score', () async {
      final repo = _GuestRepo(properties: [_property('a'), _property('b', rent: 5000)]);
      final cubit = HomeCubit.guest(repository: repo);
      expect(cubit.state.isLoading, isTrue);

      await cubit.stream.firstWhere((s) => !s.isLoading);

      expect(cubit.state.isGuest, isTrue);
      // Newest-first order is preserved; no Ci means no re-ranking.
      expect(cubit.state.nearby.map((l) => l.id), ['a', 'b']);
      expect(cubit.state.recommended.map((l) => l.id), ['a', 'b']);
      expect(cubit.state.nearby.every((l) => l.matchPercent == 0), isTrue);
      await cubit.close();
    });

    test('empty feed gives an empty (not error) state', () async {
      final cubit = HomeCubit.guest(repository: _GuestRepo());
      final s = await cubit.stream.firstWhere((s) => !s.isLoading);
      expect(s.listings, isEmpty);
      expect(s.errorMessage, isNull);
      await cubit.close();
    });

    test('a failed load surfaces a readable error, and refresh retries', () async {
      final cubit = HomeCubit.guest(repository: _GuestRepo(fail: true));
      final s = await cubit.stream.firstWhere((s) => !s.isLoading);
      expect(s.errorMessage, 'Network error. Check your connection.');

      await cubit.refresh();
      expect((cubit.state.errorMessage), isNotNull);
      await cubit.close();
    });

    test('guest detail comes from the public view, never a match', () async {
      final cubit = HomeCubit.guest(repository: _GuestRepo());
      await cubit.stream.firstWhere((s) => !s.isLoading);
      final detail = await cubit.loadPropertyDetail('a');
      expect(detail!['bScore'], 0);
      expect(detail['isVerified'], false);
      await cubit.close();
    });

    test('saving stays session-only and works for guests', () async {
      final cubit = HomeCubit.guest(repository: _GuestRepo(properties: [_property('a')]));
      await cubit.stream.firstWhere((s) => !s.isLoading);
      cubit.toggleSaved('a');
      expect(cubit.state.saved.single.id, 'a');
      await cubit.close();
    });
  });

  group('SearchCubit.guest', () {
    test('lists the public results with no profile', () async {
      final cubit = SearchCubit.guest(
        repository: _GuestRepo(properties: [_property('a')]),
      );
      final s = await cubit.stream.firstWhere((s) => !s.isLoading);
      expect(s.results.single['propertyId'], 'a');
      expect(s.results.single['bScore'], 0);
      expect(s.profile, isNull);
      await cubit.close();
    });
  });

  group('Listing.fromProperty', () {
    test('carries amenity score from the checklist and no match percent', () {
      final l = Listing.fromProperty(property: _property('a'), imageSeed: 2);
      expect(l.amenityScore, 2);
      expect(l.matchPercent, 0);
      expect(l.pricePerMonth, 3500);
    });
  });
}
