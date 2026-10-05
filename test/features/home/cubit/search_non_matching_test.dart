import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/firestore/models/models.dart';
import 'package:rentease/features/home/cubit/search_cubit.dart';
import 'package:rentease/features/home/domain/repositories/home_repository.dart';
import 'package:rentease/features/matching/domain/entities/mismatch_reason.dart';

const _profile = TenantProfileDoc(
  userId: 't1',
  maxBudget: 4000,
  requiredGender: 'Mixed / Any',
  needsWifi: false,
  maxDistanceKm: 3,
  poiLatLng: GeoPoint(7.07, 125.6),
  poiLabel: 'USEP',
  isSmoker: false,
  hasPet: false,
  groupSize: 1,
  wRent: 0.35,
  wDistance: 0.35,
  wAmenities: 0.3,
);

Map<String, dynamic> _match(String id) => {
  'propertyId': id,
  'bScore': 1,
  'matchId': 't1_$id',
  'tenantCi': 0.8,
};

Map<String, dynamic> _non(String id, List<MismatchReason> reasons) => {
  'propertyId': id,
  'bScore': 0,
  'matchId': null,
  'isNonMatch': true,
  'mismatchReasons': reasons,
};

class _Repo implements HomeRepository {
  _Repo({
    required this.matches,
    this.nonMatches = const [],
    this.failNon = false,
  });
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> nonMatches;
  final bool failNon;
  int nonCalls = 0;
  Set<String>? lastExcluded;

  @override
  Future<List<Map<String, dynamic>>> fetchSearchResults(String t) async =>
      matches;

  @override
  Future<TenantProfileDoc?> fetchTenantProfile(String t) async => _profile;

  @override
  Future<List<Map<String, dynamic>>> fetchNonMatchingResults({
    required String tenantId,
    required TenantProfileDoc profile,
    required Set<String> excludePropertyIds,
    int limit = 50,
    int? displayLimit,
  }) async {
    nonCalls++;
    lastExcluded = excludePropertyIds;
    if (failNon) throw Exception('boom');
    return nonMatches;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}

const _wifi = MismatchReason(MismatchKind.noWifi);
const _budget = MismatchReason(MismatchKind.overBudget, 800);

void main() {
  Future<SearchCubit> make(_Repo repo) async {
    final c = SearchCubit(tenantId: 't1', repository: repo);
    await c.stream.firstWhere((s) => !s.isLoading);
    return c;
  }

  test('toggle off by default: results unchanged, no non-match fetch', () async {
    final repo = _Repo(
      matches: [_match('a')],
      nonMatches: [
        _non('x', [_wifi]),
      ],
    );
    final c = await make(repo);
    expect(c.state.includeNonMatching, isFalse);
    expect(c.state.results.map((r) => r['propertyId']), ['a']);
    expect(c.state.nonMatches, isEmpty);
    expect(repo.nonCalls, 0);
    await c.close();
  });

  test('on: matches first; non-matches by fewest reasons then newest; '
      'no inquiry affordance', () async {
    final repo = _Repo(
      matches: [_match('a')],
      // Fetched newest-first: n1 (2 reasons), n2 (1), n3 (1).
      nonMatches: [
        _non('n1', [_wifi, _budget]),
        _non('n2', [_wifi]),
        _non('n3', [_budget]),
      ],
    );
    final c = await make(repo);
    await c.setIncludeNonMatching(true);

    expect(c.state.results.map((r) => r['propertyId']), ['a']);
    expect(c.state.nonMatches.map((r) => r['propertyId']), ['n2', 'n3', 'n1']);
    expect(repo.lastExcluded, {'a'});
    for (final n in c.state.nonMatches) {
      expect(n['bScore'], 0);
      expect(n['matchId'], isNull);
      expect(n['isNonMatch'], isTrue);
      expect(n['mismatchReasons'], isNotEmpty);
    }
    await c.close();
  });

  test('reload keeps the toggle and refetches; off clears', () async {
    final repo = _Repo(
      matches: [],
      nonMatches: [
        _non('x', [_wifi]),
      ],
    );
    final c = await make(repo);
    await c.setIncludeNonMatching(true);
    expect(c.state.nonMatches, hasLength(1));

    await c.load();
    expect(c.state.includeNonMatching, isTrue);
    expect(c.state.nonMatches, hasLength(1));
    expect(repo.nonCalls, 2);

    await c.setIncludeNonMatching(false);
    expect(c.state.nonMatches, isEmpty);
    await c.close();
  });

  test('non-match fetch failure keeps matches and flags the failure', () async {
    final c = await make(_Repo(matches: [_match('a')], failNon: true));
    await c.setIncludeNonMatching(true);
    expect(c.state.results, hasLength(1));
    expect(c.state.nonMatches, isEmpty);
    expect(c.state.nonMatchesFailed, isTrue);
    await c.close();
  });
}
