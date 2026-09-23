import '../../../../core/firestore/models/models.dart';
import '../../../../core/utils/distance_utils.dart';
import '../repositories/filtering_repository.dart';

/// Dual-sided constraint-based filtering (CLAUDE.md "Dual-Sided Bilateral
/// Filtering") — client-side, per the "Client-Side Matching Engine" decision
/// (no Cloud Functions). [computePropertySideScore], [computeTenantSideScore]
/// and [computeBilateralScore] are pure and unit-tested directly against the
/// SPRINTPLAN.md test oracle; [runFiltering] is the Firestore-backed
/// orchestration that calls them for every candidate property.
class FilteringService {
  FilteringService({required FilteringRepository repository})
    : _repository = repository;

  final FilteringRepository _repository;

  // ── Layer 1 — property-side constraints (owner rules vs tenant) ────────

  /// P_score = GenderMatch × SmokingMatch × PetMatch × OccupancyMatch.
  /// [tenantGender] is the tenant's own gender (`users/{uid}.gender`) — not
  /// to be confused with [TenantProfileDoc.requiredGender], which is the
  /// tenant's *requirement of the property* and belongs to [computeTenantSideScore].
  static num computePropertySideScore({
    required String tenantGender,
    required TenantProfileDoc tenant,
    required PropertyDoc property,
  }) {
    final genderMatch = _genderPolicyAllows(property.allowedGender, tenantGender) ? 1 : 0;
    final smokingMatch = (!tenant.isSmoker || property.smokingAllowed) ? 1 : 0;
    final petMatch = (!tenant.hasPet || property.petsAllowed) ? 1 : 0;
    final occupancyMatch = (tenant.groupSize <= property.maxOccupants) ? 1 : 0;
    return genderMatch * smokingMatch * petMatch * occupancyMatch;
  }

  // ── Layer 2 — tenant-side constraints (tenant requirements vs property) ─

  /// T_score = BudgetMatch × GenderPolicyMatch × WifiMatch × LocationMatch.
  /// [distanceKm] is precomputed by the caller (via [DistanceUtils]) so this
  /// function stays pure and easy to unit test without a GeoPoint fixture.
  static num computeTenantSideScore({
    required TenantProfileDoc tenant,
    required PropertyDoc property,
    required num distanceKm,
  }) {
    final budgetMatch = (property.monthlyRent <= tenant.maxBudget) ? 1 : 0;
    final genderPolicyMatch =
        _genderPoliciesCompatible(property.allowedGender, tenant.requiredGender)
            ? 1
            : 0;
    // needsWifi governs — do NOT hardcode WiFi as always required.
    final wifiMatch = (!tenant.needsWifi || property.hasWifi) ? 1 : 0;
    final locationMatch = (distanceKm <= tenant.maxDistanceKm) ? 1 : 0;
    return budgetMatch * genderPolicyMatch * wifiMatch * locationMatch;
  }

  /// B_score = P_score × T_score. 1 → eligible for TOPSIS; 0 → discarded.
  static num computeBilateralScore(num pScore, num tScore) => pScore * tScore;

  // ── Gender matching helpers ─────────────────────────────────────────────
  // The app's real gender-policy values are 'Female only' | 'Male only' |
  // 'Mixed / Any' (see property_rules_screen.dart, hard_constraints_screen.dart) —
  // matched case-insensitively rather than hardcoding that exact casing.

  static bool _isWildcardGender(String value) {
    final v = value.trim().toLowerCase();
    return v.isEmpty || v == 'all' || v == 'any' || v == 'mixed / any' || v == 'mixed';
  }

  /// Layer 1: does the property's policy allow a person of [candidateGender]?
  static bool _genderPolicyAllows(String allowedGender, String candidateGender) {
    if (_isWildcardGender(allowedGender)) return true;
    if (candidateGender.trim().isEmpty) return false;
    return allowedGender.trim().toLowerCase().startsWith(
      candidateGender.trim().toLowerCase(),
    );
  }

  /// Layer 2: is the property's gender policy compatible with what the
  /// tenant requires? Either side being a wildcard ("no preference") is
  /// always compatible; otherwise the two policies must match.
  static bool _genderPoliciesCompatible(String allowedGender, String requiredGender) {
    if (_isWildcardGender(allowedGender) || _isWildcardGender(requiredGender)) {
      return true;
    }
    return allowedGender.trim().toLowerCase() == requiredGender.trim().toLowerCase();
  }

  // ── Orchestration ────────────────────────────────────────────────────────

  /// Fetches the tenant's profile + every available, verified property,
  /// scores each pair, and writes the eligible (bScore = 1) results to
  /// `matches` — removing any existing match doc for a pair that is now
  /// ineligible. Call this whenever a tenant saves/updates their profile,
  /// or when they open the recommendations screen (CLAUDE.md rule 7: run
  /// at profile-save time, not on every search).
  Future<void> runFiltering(String tenantId) async {
    final tenant = await _repository.fetchTenantProfile(tenantId);
    if (tenant == null) {
      throw StateError(
        'No tenantProfiles/$tenantId doc — onboarding must be completed '
        'before filtering can run.',
      );
    }
    final tenantGender = await _repository.fetchTenantGender(tenantId) ?? '';
    final properties = await _repository.fetchAvailableProperties();

    final eligible = <MatchDoc>[];
    final ineligiblePropertyIds = <String>[];

    for (final property in properties) {
      final distanceKm = DistanceUtils.kmBetween(tenant.poiLatLng, property.location);
      final pScore = computePropertySideScore(
        tenantGender: tenantGender,
        tenant: tenant,
        property: property,
      );
      final tScore = computeTenantSideScore(
        tenant: tenant,
        property: property,
        distanceKm: distanceKm,
      );
      final bScore = computeBilateralScore(pScore, tScore);

      if (bScore == 1) {
        eligible.add(
          MatchDoc(
            matchId: '${tenantId}_${property.propertyId}',
            tenantId: tenantId,
            ownerId: property.ownerId,
            propertyId: property.propertyId,
            pScore: pScore,
            tScore: tScore,
            bScore: bScore,
            distanceKm: distanceKm,
          ),
        );
      } else {
        ineligiblePropertyIds.add(property.propertyId);
      }
    }

    await _repository.writeFilterResults(
      tenantId: tenantId,
      eligibleMatches: eligible,
      ineligiblePropertyIds: ineligiblePropertyIds,
    );
  }
}
