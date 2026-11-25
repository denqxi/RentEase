enum MatchReasonKind { distance, budget, amenities }

/// One plain fact about why a listing suits a tenant, shown on cards and on
/// the detail screen in place of the raw TOPSIS score.
class MatchReason {
  const MatchReason(this.kind, this.shortLabel, this.detailLabel);

  final MatchReasonKind kind;

  /// Short text for a card, e.g. "₱800 under budget".
  final String shortLabel;

  /// Fuller sentence for the detail screen.
  final String detailLabel;

  /// Size of the fixed amenity checklist.
  static const int amenityTotal = 14;

  /// Reasons in a fixed order: distance, budget margin, amenities. A fact
  /// that is unknown is left out, and so is the budget line when rent is over
  /// [maxBudget] (that is a mismatch, not a reason). [distanceKm] is the
  /// already computed distance; nothing is measured here.
  static List<MatchReason> forListing({
    num? distanceKm,
    num? rent,
    num? maxBudget,
    num? amenityCount,
  }) {
    final reasons = <MatchReason>[];
    if (distanceKm != null && distanceKm.isFinite && distanceKm >= 0) {
      final km = distanceKm.toStringAsFixed(1);
      reasons.add(
        MatchReason(
          MatchReasonKind.distance,
          '$km km away',
          '$km km from your pinned place (straight line)',
        ),
      );
    }
    if (rent != null && rent > 0 && maxBudget != null && rent <= maxBudget) {
      final margin = (maxBudget - rent).floor();
      final money = margin.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      reasons.add(
        margin > 0
            ? MatchReason(
                MatchReasonKind.budget,
                '₱$money under budget',
                'Rent is ₱$money under your max budget',
              )
            : const MatchReason(
                MatchReasonKind.budget,
                'Within budget',
                'Rent is within your max budget',
              ),
      );
    }
    if (amenityCount != null) {
      final count = amenityCount.toInt();
      reasons.add(
        MatchReason(
          MatchReasonKind.amenities,
          '$count/$amenityTotal amenities',
          'Has $count of $amenityTotal listed amenities',
        ),
      );
    }
    return reasons;
  }
}

/// The state of a listing map, worded the same on every surface.
enum MatchStatus {
  matches('Matches'),
  doesNotMatch("Doesn't match"),
  thisSearch('This search');

  const MatchStatus(this.label);

  final String label;

  /// Null when there is nothing to claim (guests, or status not yet known).
  static MatchStatus? of(Map<String, dynamic> p) {
    if (p['isFilterMatch'] == true) return thisSearch;
    if (p['isNonMatch'] == true) return doesNotMatch;
    if (p['bScore'] == 1 && p['matchKnown'] != false) return matches;
    return null;
  }
}
