import '../../../../core/firestore/models/models.dart';
import '../../domain/repositories/filtering_repository.dart';
import '../datasources/matching_remote_datasource.dart';

class FilteringRepositoryImpl implements FilteringRepository {
  FilteringRepositoryImpl({MatchingRemoteDataSource? remote})
    : _remote = remote ?? MatchingRemoteDataSource();

  final MatchingRemoteDataSource _remote;

  @override
  Future<String?> fetchTenantGender(String tenantId) =>
      _remote.fetchUserGender(tenantId);

  @override
  Future<TenantProfileDoc?> fetchTenantProfile(String tenantId) =>
      _remote.fetchTenantProfile(tenantId);

  @override
  Future<List<PropertyDoc>> fetchAvailableProperties() =>
      _remote.fetchAvailableVerifiedProperties();

  @override
  Future<Set<String>> fetchMatchedPropertyIds(String tenantId) async {
    final matches = await _remote.fetchEligibleMatches(tenantId);
    return matches.map((m) => m.propertyId).toSet();
  }

  @override
  Future<void> writeFilterResults({
    required String tenantId,
    required List<MatchDoc> eligibleMatches,
    required List<String> ineligiblePropertyIds,
  }) {
    return _remote.writeFilterResults(
      tenantId: tenantId,
      eligibleMatches: eligibleMatches,
      ineligiblePropertyIds: ineligiblePropertyIds,
    );
  }
}
