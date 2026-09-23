import '../../../../core/firestore/models/models.dart';
import '../services/topsis_service.dart';

/// Data access for [TopsisService] — mirrors [FilteringRepository]'s split
/// between pure scoring and Firestore I/O.
abstract class TopsisRepository {
  /// Just the weight fields — a thin read compared to the full tenant
  /// profile, since that's all TOPSIS itself needs.
  Future<TenantProfileDoc?> fetchTenantWeights(String tenantId);

  /// This tenant's eligible (bScore = 1) match docs.
  Future<List<MatchDoc>> fetchEligibleMatches(String tenantId);

  /// The properties referenced by those matches, keyed by propertyId.
  Future<Map<String, PropertyDoc>> fetchProperties(Set<String> propertyIds);

  /// Writes `tenantCi`/`tenantRank` back onto each corresponding match doc
  /// — a partial update, not a full match rewrite (the pairing/pScore/
  /// tScore/bScore fields FilteringService already wrote are untouched).
  Future<void> writeTopsisResults(List<TopsisResult> results);
}
