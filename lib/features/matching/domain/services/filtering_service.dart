import '../../../../core/firestore/models/models.dart';
import '../../../../core/utils/distance_utils.dart';
import '../entities/mismatch_reason.dart';
import '../repositories/filtering_repository.dart';

/// Dual-sided constraint-based filtering (CLAUDE.md "Dual-Sided Bilateral
/// Filtering") — client-side, per the "Client-Side Matching Engine" decision
/// (no Cloud Functions). [computePropertySideScore], [computeTenantSideScore]
/// and [computeBilateralScore] are pure and unit-tested directly against the
/// SPRINTPLAN.md test oracle; [runFiltering] is the Firestore-backed
/// orchestration that calls them for every candidate property.
class FilteringService {
  FilteringService({required this._repository});

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
    final genderMatch = _genderOk(tenantGender, property) ? 1 : 0;
    final smokingMatch = _smokingOk(tenant, property) ? 1 : 0;
    final petMatch = _petsOk(tenant, property) ? 1 : 0;
    final occupancyMatch = _occupancyOk(tenant, property) ? 1 : 0;
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
    final budgetMatch = _budgetOk(tenant, property) ? 1 : 0;
    final genderPolicyMatch = _genderPolicyOk(tenant, property) ? 1 : 0;
    final wifiMatch = _wifiOk(tenant, property) ? 1 : 0;
    final locationMatch = _locationOk(tenant, distanceKm) ? 1 : 0;
    return budgetMatch * genderPolicyMatch * wifiMatch * locationMatch;
  }

  /// B_score = P_score × T_score. 1 → eligible for TOPSIS; 0 → discarded.
  static num computeBilateralScore(num pScore, num tScore) => pScore * tScore;

  // ── Shared predicates ───────────────────────────────────────────────────
  // The single definition of each rule: used by the scores above and by
  // [explainMismatch], so the two cannot drift apart.

  static bool _genderOk(String tenantGender, PropertyDoc property) =>
      _genderPolicyAllows(property.allowedGender, tenantGender);
  static bool _smokingOk(TenantProfileDoc t, PropertyDoc p) =>
      !t.isSmoker || p.smokingAllowed;
  static bool _petsOk(TenantProfileDoc t, PropertyDoc p) =>
      !t.hasPet || p.petsAllowed;
  static bool _occupancyOk(TenantProfileDoc t, PropertyDoc p) =>
      t.groupSize <= p.maxOccupants;
  static bool _budgetOk(TenantProfileDoc t, PropertyDoc p) =>
      p.monthlyRent <= t.maxBudget;
  static bool _genderPolicyOk(TenantProfileDoc t, PropertyDoc p) =>
      _genderPoliciesCompatible(p.allowedGender, t.requiredGender);
  // needsWifi governs — do NOT hardcode WiFi as always required.
  static bool _wifiOk(TenantProfileDoc t, PropertyDoc p) =>
      !t.needsWifi || p.hasWifi;
  static bool _locationOk(TenantProfileDoc t, num distanceKm) =>
      distanceKm <= t.maxDistanceKm;

  /// Why [property] fails [tenant]'s constraints; empty exactly when
  /// B_score = 1. Pure, display-only (Search's view-only non-matches); it
  /// never gates communication — `firestore.rules` does that independently.
  static List<MismatchReason> explainMismatch({
    required String tenantGender,
    required TenantProfileDoc tenant,
    required PropertyDoc property,
    required num distanceKm,
  }) {
    return [
      if (!_budgetOk(tenant, property))
        MismatchReason(
          MismatchKind.overBudget,
          property.monthlyRent - tenant.maxBudget,
        ),
      if (!_genderPolicyOk(tenant, property))
        const MismatchReason(MismatchKind.genderPolicy),
      if (!_genderOk(tenantGender, property))
        const MismatchReason(MismatchKind.tenantGenderNotAllowed),
      if (!_smokingOk(tenant, property))
        const MismatchReason(MismatchKind.smoking),
      if (!_petsOk(tenant, property)) const MismatchReason(MismatchKind.pets),
      if (!_occupancyOk(tenant, property))
        MismatchReason(
          MismatchKind.overCapacity,
          tenant.groupSize - property.maxOccupants,
        ),
      if (!_wifiOk(tenant, property)) const MismatchReason(MismatchKind.noWifi),
      if (!_locationOk(tenant, distanceKm))
        MismatchReason(MismatchKind.tooFar, distanceKm - tenant.maxDistanceKm),
    ];
  }

  // ── Gender matching helpers ─────────────────────────────────────────────
  // The app's real gender-policy values are 'Female only' | 'Male only' |
  // 'Mixed / Any' (see property_rules_screen.dart, hard_constraints_screen.dart) —
  // matched case-insensitively rather than hardcoding that exact casing.

  static bool _isWildcardGender(String value) {
    final v = value.trim().toLowerCase();
    return v.isEmpty ||
        v == 'all' ||
        v == 'any' ||
        v == 'mixed / any' ||
        v == 'mixed';
  }

  /// Layer 1: does the property's policy allow a person of [candidateGender]?
  static bool _genderPolicyAllows(
    String allowedGender,
    String candidateGender,
  ) {
    if (_isWildcardGender(allowedGender)) return true;
    if (candidateGender.trim().isEmpty) return false;
    return allowedGender.trim().toLowerCase().startsWith(
      candidateGender.trim().toLowerCase(),
    );
  }

  /// Layer 2: is the property's gender policy compatible with what the
  /// tenant requires? Either side being a wildcard ("no preference") is
  /// always compatible; otherwise the two policies must match.
  static bool _genderPoliciesCompatible(
    String allowedGender,
    String requiredGender,
  ) {
    if (_isWildcardGender(allowedGender) || _isWildcardGender(requiredGender)) {
      return true;
    }
    return allowedGender.trim().toLowerCase() ==
        requiredGender.trim().toLowerCase();
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
      final distanceKm = DistanceUtils.kmBetween(
        tenant.poiLatLng,
        property.location,
      );
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

    // A property that left the candidate pool entirely — fully booked,
    // unlisted, or no longer verified — is never scored above, so its old
    // bScore = 1 row would otherwise survive and keep showing on Home and
    // accepting inquiries. Remove those too.
    final poolIds = properties.map((p) => p.propertyId).toSet();
    final existing = await _repository.fetchMatchedPropertyIds(tenantId);
    ineligiblePropertyIds.addAll(existing.difference(poolIds));

    await _repository.writeFilterResults(
      tenantId: tenantId,
      eligibleMatches: eligible,
      ineligiblePropertyIds: ineligiblePropertyIds,
    );
  }
}
