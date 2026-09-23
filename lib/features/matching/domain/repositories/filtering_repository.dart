import '../../../../core/firestore/models/models.dart';

/// Data access for [FilteringService] — no scoring logic here, just reads
/// and writes. Kept separate from the (pure, easily unit-tested) scoring
/// functions per CLAUDE.md rule 7 ("data access goes in repositories").
abstract class FilteringRepository {
  /// The tenant's own gender, from `users/{uid}.gender` — used for
  /// GenderMatch (Layer 1). Null if the user doc doesn't exist.
  Future<String?> fetchTenantGender(String tenantId);

  Future<TenantProfileDoc?> fetchTenantProfile(String tenantId);

  /// All currently available, admin-verified properties — the candidate
  /// pool `runFiltering` scores against.
  Future<List<PropertyDoc>> fetchAvailableProperties();

  /// Writes one `matches/{tenantId}_{propertyId}` doc per bScore = 1 result,
  /// and removes any existing match doc for a pair that is now bScore = 0
  /// (so a preference change that makes a previously-eligible property
  /// ineligible doesn't leave a stale eligible match behind).
  Future<void> writeFilterResults({
    required String tenantId,
    required List<MatchDoc> eligibleMatches,
    required List<String> ineligiblePropertyIds,
  });
}
