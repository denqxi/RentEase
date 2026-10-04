import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/tenant_profile_doc.dart';
import 'package:rentease/features/matching/domain/repositories/filtering_repository.dart';
import 'package:rentease/features/matching/domain/repositories/topsis_repository.dart';
import 'package:rentease/features/matching/domain/services/filtering_service.dart';
import 'package:rentease/features/matching/domain/services/topsis_service.dart';
import 'package:rentease/features/profile/cubit/edit_preferences_cubit.dart';
import 'package:rentease/features/tenant_onboarding/domain/repositories/tenant_profile_repository.dart';

const _uid = 'tenantA';

final _profile = TenantProfileDoc(
  userId: _uid,
  maxBudget: 4500,
  requiredGender: 'Female only',
  needsWifi: true,
  maxDistanceKm: 3,
  poiLatLng: const GeoPoint(7.07, 125.6),
  poiLabel: 'USEP',
  isSmoker: false,
  hasPet: false,
  groupSize: 1,
  wRent: 0.35,
  wDistance: 0.35,
  wAmenities: 0.30,
);

/// Records, in order, every write and engine run.
final _calls = <String>[];

class _FakeProfileRepo implements TenantProfileRepository {
  Map<String, dynamic>? lastUpdate;
  Map<String, dynamic>? lastPrefsUpdate;

  @override
  Future<TenantProfileDoc?> fetchProfile(String uid) async => _profile;

  @override
  Future<void> updateFields(String uid, Map<String, dynamic> fields) async {
    lastUpdate = fields;
    _calls.add('update');
  }

  @override
  Future<void> updatePrefs(String uid, Map<String, dynamic> fields) async {
    lastPrefsUpdate = fields;
    _calls.add('updatePrefs');
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('$i');
}

class _NoRepo implements FilteringRepository, TopsisRepository {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('$i');
}

class _FakeFiltering extends FilteringService {
  _FakeFiltering() : super(repository: _NoRepo());

  @override
  Future<void> runFiltering(String tenantId) async => _calls.add('filter');
}

class _FakeTopsis extends TopsisService {
  _FakeTopsis() : super(repository: _NoRepo());

  @override
  Future<void> computeTOPSIS(String tenantId) async => _calls.add('topsis');
}

Future<EditPreferencesCubit> _loadedCubit(_FakeProfileRepo repo) async {
  final cubit = EditPreferencesCubit(
    uid: _uid,
    repository: repo,
    filteringService: _FakeFiltering(),
    topsisService: _FakeTopsis(),
  );
  await cubit.stream.firstWhere((s) => s.status == EditPreferencesStatus.ready);
  return cubit;
}

void main() {
  setUp(_calls.clear);

  test('loads the saved profile', () async {
    final cubit = await _loadedCubit(_FakeProfileRepo());
    expect(cubit.state.profile?.maxBudget, 4500);
  });

  test('saving constraints writes them, then re-runs filtering and TOPSIS', () async {
    final repo = _FakeProfileRepo();
    final cubit = await _loadedCubit(repo);

    await cubit.saveConstraints(
      maxBudget: 5000,
      requiredGender: 'Mixed / Any',
      needsWifi: false,
      maxDistanceKm: 4.5,
    );

    expect(_calls, ['update', 'filter', 'topsis']);
    expect(repo.lastUpdate, {
      'maxBudget': 5000,
      'requiredGender': 'Mixed / Any',
      'needsWifi': false,
      'maxDistanceKm': 4.5,
    });
    expect(cubit.state.status, EditPreferencesStatus.saved);
  });

  test('saving weights re-runs TOPSIS only (eligibility is unchanged)', () async {
    final repo = _FakeProfileRepo();
    final cubit = await _loadedCubit(repo);

    await cubit.saveWeights(wRent: 0.5, wDistance: 0.3, wAmenities: 0.2);

    // Weights go to the private prefs doc, never the owner-readable profile.
    expect(_calls, ['updatePrefs', 'topsis']);
    expect(repo.lastUpdate, isNull);
    expect(repo.lastPrefsUpdate, {'wRent': 0.5, 'wDistance': 0.3, 'wAmenities': 0.2});
    expect(cubit.state.status, EditPreferencesStatus.saved);
  });

  test('weights that do not sum to 100% are never written', () async {
    final cubit = await _loadedCubit(_FakeProfileRepo());

    await cubit.saveWeights(wRent: 0.5, wDistance: 0.5, wAmenities: 0.2);

    expect(_calls, isEmpty);
    expect(cubit.state.status, EditPreferencesStatus.ready);
    expect(cubit.state.errorMessage, contains('100%'));
  });

  test('a zero budget is never written', () async {
    final cubit = await _loadedCubit(_FakeProfileRepo());

    await cubit.saveConstraints(
      maxBudget: 0,
      requiredGender: 'Mixed / Any',
      needsWifi: false,
      maxDistanceKm: 3,
    );

    expect(_calls, isEmpty);
    expect(cubit.state.errorMessage, isNotNull);
  });
}
