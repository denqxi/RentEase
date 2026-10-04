enum MismatchKind {
  overBudget,
  genderPolicy,
  tenantGenderNotAllowed,
  smoking,
  pets,
  overCapacity,
  noWifi,
  tooFar,
}

/// One reason a property fails a tenant's saved constraints, produced by
/// `FilteringService.explainMismatch` from the same predicates that set
/// P_score / T_score. [amount] is the overage where one applies (PHP for
/// [MismatchKind.overBudget], km for [MismatchKind.tooFar], people for
/// [MismatchKind.overCapacity]).
class MismatchReason {
  const MismatchReason(this.kind, [this.amount]);

  final MismatchKind kind;
  final num? amount;

  /// Short text for a card, e.g. "No WiFi", "₱800 over budget".
  String get shortLabel => switch (kind) {
    MismatchKind.overBudget => '₱${_money(amount ?? 0)} over budget',
    MismatchKind.genderPolicy => 'Gender policy differs',
    MismatchKind.tenantGenderNotAllowed => 'Not open to your gender',
    MismatchKind.smoking => 'No smoking allowed',
    MismatchKind.pets => 'No pets allowed',
    MismatchKind.overCapacity => 'Too many occupants',
    MismatchKind.noWifi => 'No WiFi',
    MismatchKind.tooFar => '${_km(amount ?? 0)} km too far',
  };

  /// Fuller sentence for the detail screen.
  String get detailLabel => switch (kind) {
    MismatchKind.overBudget =>
      'Rent is ₱${_money(amount ?? 0)} over your maximum budget',
    MismatchKind.genderPolicy =>
      "The gender policy differs from the one you require",
    MismatchKind.tenantGenderNotAllowed =>
      "This property's gender policy does not accept your gender",
    MismatchKind.smoking => 'You smoke, but smoking is not allowed here',
    MismatchKind.pets => 'You have a pet, but pets are not allowed here',
    MismatchKind.overCapacity =>
      'Your group is ${amount ?? 0} over the maximum occupants',
    MismatchKind.noWifi => 'You need WiFi, but this property has none',
    MismatchKind.tooFar =>
      '${_km(amount ?? 0)} km beyond your maximum distance',
  };

  /// Rounded up so a tiny overage never displays as "0.0".
  static String _km(num km) => ((km * 10).ceil() / 10).toStringAsFixed(1);

  static String _money(num v) => v.ceil().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  bool operator ==(Object other) =>
      other is MismatchReason && other.kind == kind && other.amount == amount;

  @override
  int get hashCode => Object.hash(kind, amount);

  @override
  String toString() => 'MismatchReason($kind, $amount)';
}
