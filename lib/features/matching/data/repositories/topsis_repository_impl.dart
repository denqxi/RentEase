import '../../../../core/firestore/models/models.dart';
import '../../domain/repositories/topsis_repository.dart';
import '../../domain/services/topsis_service.dart';
import '../datasources/matching_remote_datasource.dart';

class TopsisRepositoryImpl implements TopsisRepository {
  TopsisRepositoryImpl({MatchingRemoteDataSource? remote})
    : _remote = remote ?? MatchingRemoteDataSource();

  final MatchingRemoteDataSource _remote;

  @override
  Future<TenantProfileDoc?> fetchTenantWeights(String tenantId) =>
      _remote.fetchTenantProfile(tenantId);

  @override
  Future<List<MatchDoc>> fetchEligibleMatches(String tenantId) =>
      _remote.fetchEligibleMatches(tenantId);

  @override
  Future<Map<String, PropertyDoc>> fetchProperties(Set<String> propertyIds) =>
      _remote.fetchPropertiesByIds(propertyIds);

  @override
  Future<void> writeTopsisResults(List<TopsisResult> results) =>
      _remote.writeTopsisResults(results);
}
