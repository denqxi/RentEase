import 'dart:math' as math;

/// One option being ranked, with one value per criterion (same order as the
/// weights passed to [rankTopsis]).
class TopsisAlternative {
  const TopsisAlternative({required this.id, required this.values});

  final String id;
  final List<num> values;
}

class TopsisRanking {
  const TopsisRanking({required this.id, required this.ci, required this.rank});

  final String id;

  /// Closeness coefficient, 0.00–1.00.
  final double ci;

  /// 1-based rank, 1 = best.
  final int rank;
}

/// The TOPSIS algorithm shared by both single-sided instances (CLAUDE.md
/// "Two TOPSIS Instances") — tenant-side ranks properties, owner-side ranks
/// tenants; only the criteria differ, so the math lives here once.
///
/// Steps: normalize (r = x / √Σx²) → weight (v = w·r) → ideal best/worst per
/// criterion (best = max for benefit, min for cost) → Euclidean distance to
/// each (D+, D−) → Ci = D− / (D+ + D−) → rank descending by Ci.
///
/// Conventions for the cases the formula leaves undefined:
/// - a single alternative ranks Ci = 1.0 (nothing to be closer/farther than);
/// - alternatives identical on every criterion have D+ = D− = 0, and also
///   rank Ci = 1.0 — none of them is worse than another.
List<TopsisRanking> rankTopsis({
  required List<TopsisAlternative> alternatives,
  required List<num> weights,
  required List<bool> isBenefit,
}) {
  assert(weights.length == isBenefit.length);
  if (alternatives.isEmpty) return const [];
  if (alternatives.length == 1) {
    return [TopsisRanking(id: alternatives.single.id, ci: 1.0, rank: 1)];
  }

  final criteria = weights.length;
  final norms = [
    for (var j = 0; j < criteria; j++)
      math.sqrt(
        alternatives.fold<num>(0, (s, a) => s + a.values[j] * a.values[j]).toDouble(),
      ),
  ];

  final weighted = [
    for (final a in alternatives)
      [
        for (var j = 0; j < criteria; j++)
          norms[j] == 0 ? 0.0 : weights[j] * a.values[j] / norms[j],
      ],
  ];

  double column(int j, bool wantMax) => weighted
      .map((row) => row[j].toDouble())
      .reduce(wantMax ? math.max : math.min);

  final best = [for (var j = 0; j < criteria; j++) column(j, isBenefit[j])];
  final worst = [for (var j = 0; j < criteria; j++) column(j, !isBenefit[j])];

  double distance(List<num> row, List<double> ideal) => math.sqrt(
    [for (var j = 0; j < criteria; j++) (row[j] - ideal[j]) * (row[j] - ideal[j])]
        .fold<num>(0, (s, d) => s + d)
        .toDouble(),
  );

  final scored = [
    for (var i = 0; i < alternatives.length; i++)
      (
        id: alternatives[i].id,
        ci: () {
          final dPlus = distance(weighted[i], best);
          final dMinus = distance(weighted[i], worst);
          final denominator = dPlus + dMinus;
          return denominator == 0 ? 1.0 : dMinus / denominator;
        }(),
      ),
  ]..sort((a, b) => b.ci.compareTo(a.ci));

  return [
    for (var i = 0; i < scored.length; i++)
      TopsisRanking(id: scored[i].id, ci: scored[i].ci, rank: i + 1),
  ];
}
