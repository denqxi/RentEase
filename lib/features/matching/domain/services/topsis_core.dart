import 'dart:math' as math;

const List<double> _defaultWeights = [0.35, 0.35, 0.30];

/// Defensive guard: weights that do not sum to ~1 are divided by their sum;
/// a non-positive/NaN/negative-containing set falls back to the 0.35/0.35/0.30
/// defaults (when three criteria) or equal weights otherwise.
List<num> _sanitizeWeights(List<num> weights) {
  if (weights.isEmpty) return weights;
  final sum = weights.fold<double>(0, (s, w) => s + w.toDouble());
  final invalid = sum.isNaN || sum.isInfinite || sum <= 0 ||
      weights.any((w) => w.isNaN || w < 0);
  if (invalid) {
    return weights.length == _defaultWeights.length
        ? _defaultWeights
        : List<num>.filled(weights.length, 1 / weights.length);
  }
  if ((sum - 1).abs() < 1e-6) return weights;
  return [for (final w in weights) w / sum];
}

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

/// The TOPSIS algorithm (CLAUDE.md "TOPSIS (Tenant-Side Ranking)"): the one
/// tenant-side instance ranks properties for a tenant. It is kept generic over
/// the criteria so the math lives here once.
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
  weights = _sanitizeWeights(weights);
  if (alternatives.isEmpty) return const [];
  if (alternatives.length == 1) {
    return [TopsisRanking(id: alternatives.single.id, ci: 1.0, rank: 1)];
  }

  final criteria = weights.length;
  final norms = [
    for (var j = 0; j < criteria; j++)
      math.sqrt(
        alternatives
            .fold<num>(0, (s, a) => s + a.values[j] * a.values[j])
            .toDouble(),
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
    [
      for (var j = 0; j < criteria; j++)
        (row[j] - ideal[j]) * (row[j] - ideal[j]),
    ].fold<num>(0, (s, d) => s + d).toDouble(),
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
  ];
  // Deterministic order: Ci desc, then first criterion (rent) asc, then id.
  final firstValue = {for (final a in alternatives) a.id: a.values[0]};
  scored.sort((a, b) {
    final byCi = b.ci.compareTo(a.ci);
    if (byCi != 0) return byCi;
    final byRent = firstValue[a.id]!.compareTo(firstValue[b.id]!);
    if (byRent != 0) return byRent;
    return a.id.compareTo(b.id);
  });

  return [
    for (var i = 0; i < scored.length; i++)
      TopsisRanking(id: scored[i].id, ci: scored[i].ci, rank: i + 1),
  ];
}
