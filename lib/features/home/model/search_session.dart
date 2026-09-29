/// Search's session filter (CLAUDE.md "Session filters"): a temporary,
/// local-only budget/distance override for exploring the tenant's
/// compatible set. Never written to Firestore (rule 3) and never removes a
/// listing or re-sorts — results stay in TOPSIS Ci order (rule 9); a
/// listing outside the session limits is flagged instead, which the detail
/// screen shows as "Outside your preferences" with "Send Inquiry Anyway".
class SearchSession {
  const SearchSession({required this.maxBudget, required this.maxDistanceKm});

  final num maxBudget;
  final num maxDistanceKm;

  /// Copies of [results] with `isOutsidePreference`, `budgetExcess` and
  /// `distanceExcess` set against this session. Inputs are not mutated.
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> results) => [
    for (final p in results) _flag(p),
  ];

  Map<String, dynamic> _flag(Map<String, dynamic> p) {
    final rent = (p['monthlyRent'] as num?) ?? 0;
    final distance = (p['distance'] as num?) ?? 0;
    final budgetExcess = rent > maxBudget ? (rent - maxBudget).round() : 0;
    final distanceExcess = distance > maxDistanceKm
        ? ((distance - maxDistanceKm) * 10).round() / 10
        : 0;
    return {
      ...p,
      'isOutsidePreference': budgetExcess > 0 || distanceExcess > 0,
      'budgetExcess': budgetExcess,
      'distanceExcess': distanceExcess,
    };
  }
}

/// Case-insensitive match of [query] against a listing's title or address.
bool matchesSearchQuery(Map<String, dynamic> p, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final title = (p['title'] as String? ?? '').toLowerCase();
  final address = (p['address'] as String? ?? '').toLowerCase();
  return title.contains(q) || address.contains(q);
}
