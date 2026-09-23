import 'dart:math' as math;

import '../repositories/topsis_repository.dart';

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
  const TopsisResult({required this.matchId, required this.ci, required this.rank});

  final String matchId;

  /// Closeness coefficient, 0.00–1.00.
  final double ci;

  /// 1-based rank, 1 = best.
  final int rank;
}

/// TOPSIS multi-criteria ranking (CLAUDE.md "Two TOPSIS Instances",
/// Instance 1 — tenant-side). Client-side, per the "Client-Side Matching
/// Engine" decision (no Cloud Functions).
///
/// [computeCloseness] is pure and unit-tested directly; [computeTOPSIS] is
/// the Firestore-backed orchestration that feeds it real match/property data.
class TopsisService {
  TopsisService({required TopsisRepository repository}) : _repository = repository;

  final TopsisRepository _repository;

  /// Runs the TOPSIS steps (normalize → weight → ideal solutions → distances
  /// → closeness coefficient) over [candidates] and returns them ranked
  /// descending by Ci (rank 1 = best). Rent and distance are cost criteria
  /// (lower is better); amenity score is a benefit criterion (higher is
  /// better). Weights must sum to 1.0 (CLAUDE.md — enforced by the caller,
  /// not re-validated here so this stays a pure numeric function).
  ///
  /// A single candidate has nothing to be closer to or farther from than
  /// itself, so it trivially ranks Ci = 1.0 rather than producing 0/0.
  static List<TopsisResult> computeCloseness({
    required List<TopsisCandidate> candidates,
    required num wRent,
    required num wDistance,
    required num wAmenities,
  }) {
    if (candidates.isEmpty) return const [];
    if (candidates.length == 1) {
      return [TopsisResult(matchId: candidates.single.matchId, ci: 1.0, rank: 1)];
    }

    // Step 1 — normalize: r_ij = x_ij / sqrt(sum(x_ij^2)).
    final rentNorm = _vectorNorm(candidates.map((c) => c.monthlyRent));
    final distNorm = _vectorNorm(candidates.map((c) => c.distanceKm));
    final amenityNorm = _vectorNorm(candidates.map((c) => c.amenityScore));

    // Step 2 — weight: v_ij = w_j * r_ij.
    final weighted = candidates
        .map(
          (c) => (
            matchId: c.matchId,
            vRent: rentNorm == 0 ? 0.0 : wRent * (c.monthlyRent / rentNorm),
            vDist: distNorm == 0 ? 0.0 : wDistance * (c.distanceKm / distNorm),
            vAmenity:
                amenityNorm == 0 ? 0.0 : wAmenities * (c.amenityScore / amenityNorm),
          ),
        )
        .toList();

    // Step 3 — ideal solutions: A+ best per criterion, A- worst.
    // Rent/distance are cost criteria (best = min); amenity is benefit
    // (best = max).
    final rentValues = weighted.map((w) => w.vRent);
    final distValues = weighted.map((w) => w.vDist);
    final amenityValues = weighted.map((w) => w.vAmenity);

    final rentBest = rentValues.reduce(math.min);
    final rentWorst = rentValues.reduce(math.max);
    final distBest = distValues.reduce(math.min);
    final distWorst = distValues.reduce(math.max);
    final amenityBest = amenityValues.reduce(math.max);
    final amenityWorst = amenityValues.reduce(math.min);

    // Steps 4–5 — Euclidean distance from A+/A-, then closeness coefficient.
    final results = weighted.map((w) {
      final dPlus = _euclidean([
        w.vRent - rentBest,
        w.vDist - distBest,
        w.vAmenity - amenityBest,
      ]);
      final dMinus = _euclidean([
        w.vRent - rentWorst,
        w.vDist - distWorst,
        w.vAmenity - amenityWorst,
      ]);
      final denominator = dPlus + dMinus;
      final ci = denominator == 0 ? 0.0 : dMinus / denominator;
      return TopsisResult(matchId: w.matchId, ci: ci, rank: 0);
    }).toList();

    // Step 6 — rank descending by Ci.
    results.sort((a, b) => b.ci.compareTo(a.ci));
    return [
      for (var i = 0; i < results.length; i++)
        TopsisResult(matchId: results[i].matchId, ci: results[i].ci, rank: i + 1),
    ];
  }

  static double _vectorNorm(Iterable<num> values) =>
      math.sqrt(values.fold<num>(0, (sum, v) => sum + v * v).toDouble());

  static double _euclidean(List<num> diffs) =>
      math.sqrt(diffs.fold<num>(0, (sum, d) => sum + d * d).toDouble());

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
