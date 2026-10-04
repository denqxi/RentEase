import '../repositories/topsis_repository.dart';
import 'topsis_core.dart';

/// One eligible (bScore = 1) property, reduced to just the three criteria
/// TOPSIS ranks on. Pure input type — no Firestore types leak into the
/// scoring math, matching [FilteringService]'s split between pure logic and
/// orchestration.
class TopsisCandidate {
  const TopsisCandidate({
    required this.matchId,
    required this.monthlyRent,
    required this.distanceKm,
    required this.amenityScore,
  });

  final String matchId;

  /// Cost criterion — lower is better.
  final num monthlyRent;

  /// Cost criterion — lower is better.
  final num distanceKm;

  /// Benefit criterion (0–14) — higher is better.
  final num amenityScore;
}

class TopsisResult {
  const TopsisResult({
    required this.matchId,
    required this.ci,
    required this.rank,
  });

  final String matchId;

  /// Closeness coefficient, 0.00–1.00.
  final double ci;

  /// 1-based rank, 1 = best.
  final int rank;
}

/// TOPSIS multi-criteria ranking (CLAUDE.md "TOPSIS (Tenant-Side Ranking)" —
/// the only instance; there is no owner-side TOPSIS). Client-side, per the "Client-Side Matching
/// Engine" decision (no Cloud Functions).
///
/// [computeCloseness] is pure and unit-tested directly; [computeTOPSIS] is
/// the Firestore-backed orchestration that feeds it real match/property data.
class TopsisService {
  TopsisService({required this._repository});

  final TopsisRepository _repository;

  /// Ranks [candidates] descending by Ci (rank 1 = best) via the shared
  /// [rankTopsis] core. Rent and distance are cost criteria (lower is
  /// better); amenity score is a benefit criterion (higher is better).
  /// Weights must sum to 1.0 (CLAUDE.md — enforced by the caller, not
  /// re-validated here so this stays a pure numeric function).
  static List<TopsisResult> computeCloseness({
    required List<TopsisCandidate> candidates,
    required num wRent,
    required num wDistance,
    required num wAmenities,
  }) {
    return rankTopsis(
      alternatives: [
        for (final c in candidates)
          TopsisAlternative(
            id: c.matchId,
            values: [c.monthlyRent, c.distanceKm, c.amenityScore],
          ),
      ],
      weights: [wRent, wDistance, wAmenities],
      isBenefit: const [false, false, true],
    ).map((r) => TopsisResult(matchId: r.id, ci: r.ci, rank: r.rank)).toList();
  }

  // ── Orchestration ────────────────────────────────────────────────────────

  /// Pulls the tenant's eligible (bScore = 1) matches, the rent/amenityScore
  /// of each referenced property (distance is already cached on the match
  /// doc from [FilteringService]), runs [computeCloseness] with the
  /// tenant's own weights, and writes `tenantCi`/`tenantRank` back onto each
  /// match. Call immediately after `runFiltering()` (chained), and whenever
  /// the tenant updates wRent/wDistance/wAmenities.
  Future<void> computeTOPSIS(String tenantId) async {
    final tenant = await _repository.fetchTenantWeights(tenantId);
    if (tenant == null) {
      throw StateError(
        'No tenantProfiles/$tenantId doc — filtering must run before TOPSIS.',
      );
    }

    final matches = await _repository.fetchEligibleMatches(tenantId);
    if (matches.isEmpty) return;

    final properties = await _repository.fetchProperties(
      matches.map((m) => m.propertyId).toSet(),
    );

    final candidates = <TopsisCandidate>[];
    for (final match in matches) {
      final property = properties[match.propertyId];
      if (property == null) continue; // listing removed since filtering ran
      candidates.add(
        TopsisCandidate(
          matchId: match.matchId,
          monthlyRent: property.monthlyRent,
          distanceKm: match.distanceKm ?? 0,
          amenityScore: property.amenityScore ?? property.amenityList.length,
        ),
      );
    }

    final results = computeCloseness(
      candidates: candidates,
      wRent: tenant.wRent,
      wDistance: tenant.wDistance,
      wAmenities: tenant.wAmenities,
    );

    await _repository.writeTopsisResults(results);
  }
}
