// Self-constructed test oracle (see conversation record) — SPRINTPLAN.md's
// own TOPSIS oracle can't be reproduced: its BH1-BH5 scenario never assigns
// amenity scores anywhere in the source material (confirmed absent from
// Tables 10-17), and TOPSIS needs all three criteria. Rather than fabricate
// amenity numbers that happen to hit an unreconstructable target, this test
// verifies the *algorithm* (normalize -> weight -> ideal solutions ->
// distances -> closeness coefficient) against a fully-specified scenario
// computed independently by hand and cross-checked with a script, so every
// input and expected output is traceable.
//
// P1: rent=3000, distance=1.0km, amenity=10  (cheap, close, great amenities)
// P2: rent=4000, distance=2.0km, amenity=5   (mid rent, mid distance, poor amenities)
// P3: rent=5000, distance=3.0km, amenity=14  (expensive, far, best amenities)
// weights: rent=0.35, distance=0.35, amenities=0.30 (CLAUDE.md defaults)
//
// Expected ranking: P1 (Ci ~0.7726) > P3 (Ci ~0.4159) > P2 (Ci ~0.3650)
// P1 dominates on both cost criteria (cheapest, closest) and is mid-amenity,
// so it wins clearly; P2 and P3 both trade a cost disadvantage against a
// partial amenity advantage, landing closer together.

import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/matching/domain/services/topsis_service.dart';

void main() {
  group('TopsisService.computeCloseness', () {
    test('reproduces the hand-verified 3-candidate oracle within tolerance', () {
      final results = TopsisService.computeCloseness(
        candidates: const [
          TopsisCandidate(matchId: 'P1', monthlyRent: 3000, distanceKm: 1.0, amenityScore: 10),
          TopsisCandidate(matchId: 'P2', monthlyRent: 4000, distanceKm: 2.0, amenityScore: 5),
          TopsisCandidate(matchId: 'P3', monthlyRent: 5000, distanceKm: 3.0, amenityScore: 14),
        ],
        wRent: 0.35,
        wDistance: 0.35,
        wAmenities: 0.30,
      );

      final byId = {for (final r in results) r.matchId: r};

      expect(byId['P1']!.ci, closeTo(0.7726, 0.001));
      expect(byId['P2']!.ci, closeTo(0.3650, 0.001));
      expect(byId['P3']!.ci, closeTo(0.4159, 0.001));

      expect(byId['P1']!.rank, 1);
      expect(byId['P3']!.rank, 2);
      expect(byId['P2']!.rank, 3);
    });

    test('a single candidate ranks Ci = 1.0 (no 0/0 division)', () {
      final results = TopsisService.computeCloseness(
        candidates: const [
          TopsisCandidate(matchId: 'only', monthlyRent: 4000, distanceKm: 1.0, amenityScore: 8),
        ],
        wRent: 0.35,
        wDistance: 0.35,
        wAmenities: 0.30,
      );
      expect(results, hasLength(1));
      expect(results.single.ci, 1.0);
      expect(results.single.rank, 1);
    });

    test('empty candidates returns an empty result', () {
      final results = TopsisService.computeCloseness(
        candidates: const [],
        wRent: 0.35,
        wDistance: 0.35,
        wAmenities: 0.30,
      );
      expect(results, isEmpty);
    });

    test('ranks are contiguous 1..n with no ties or gaps', () {
      final results = TopsisService.computeCloseness(
        candidates: const [
          TopsisCandidate(matchId: 'a', monthlyRent: 3000, distanceKm: 1.0, amenityScore: 10),
          TopsisCandidate(matchId: 'b', monthlyRent: 4000, distanceKm: 2.0, amenityScore: 5),
          TopsisCandidate(matchId: 'c', monthlyRent: 5000, distanceKm: 3.0, amenityScore: 14),
          TopsisCandidate(matchId: 'd', monthlyRent: 3500, distanceKm: 1.5, amenityScore: 8),
        ],
        wRent: 0.35,
        wDistance: 0.35,
        wAmenities: 0.30,
      );
      final ranks = results.map((r) => r.rank).toList()..sort();
      expect(ranks, [1, 2, 3, 4]);
    });
  });
}
