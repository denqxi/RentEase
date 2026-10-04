/// Result of [normalizeWeights]: the three TOPSIS weights after adjustment,
/// always summing to exactly 1.0.
class NormalizedWeights {
  const NormalizedWeights(this.changed, this.otherA, this.otherB);

  final double changed;
  final double otherA;
  final double otherB;
}

/// Applies [newValue] to a single weight slider and redistributes the
/// remainder across the other two weights proportionally to their current
/// share, so all three always sum to exactly 1.0 (100%). Each weight is
/// floored at [minWeight] so no criterion can be dragged to zero.
NormalizedWeights normalizeWeights({
  required double newValue,
  required double otherA,
  required double otherB,
  double minWeight = 0.05,
  double Function(double)? round,
}) {
  final double clamped = newValue.clamp(minWeight, 1 - 2 * minWeight);
  final double remainder = 1 - clamped;
  final double othersSum = otherA + otherB;

  double newA, newB;
  if (othersSum <= 0) {
    newA = remainder / 2;
    newB = remainder / 2;
  } else {
    newA = remainder * (otherA / othersSum);
    newB = remainder * (otherB / othersSum);
  }
  // Enforce the floor on both, then push any resulting slack back onto
  // whichever of the two has room, keeping the total exact.
  if (newA < minWeight) {
    newB -= (minWeight - newA);
    newA = minWeight;
  }
  if (newB < minWeight) {
    newA -= (minWeight - newB);
    newB = minWeight;
  }

  if (round != null) {
    // Rounding each weight independently can drift the total (e.g. 105%), so
    // derive the last weight from the other two to keep the sum exact.
    final rc = round(clamped);
    var ra = round(newA);
    var rb = round(1 - rc - ra);
    if (rb < minWeight) {
      ra = round(1 - rc - minWeight);
      rb = round(1 - rc - ra);
    }
    return NormalizedWeights(rc, ra, rb);
  }
  return NormalizedWeights(clamped, newA, newB);
}
