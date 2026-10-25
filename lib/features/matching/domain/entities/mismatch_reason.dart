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
    MismatchKind.tooFar => _tooFar(amount, 'too far'),
  };

  /// Fuller sentence for the detail screen.
  String get detailLabel => switch (kind) {
    MismatchKind.overBudget =>
      'Rent is ₱${_money(amount ?? 0)} higher than your max budget',
    MismatchKind.genderPolicy =>
      'Gender rules differ from your preference',
    MismatchKind.tenantGenderNotAllowed =>
      'This property is not open to your gender',
    MismatchKind.smoking => 'Smoking is not allowed here',
    MismatchKind.pets => 'Pets are not allowed here',
    MismatchKind.overCapacity =>
      'Group size exceeds allowed limit (by ${amount ?? 0})',
    MismatchKind.noWifi => 'No WiFi internet available',
    MismatchKind.tooFar =>
      _tooFar(amount, 'farther than your commute limit'),
  };

  /// Unknown location (no pin) has an infinite excess: don't print a number.
  String _tooFar(num? amount, String suffix) =>
      (amount != null && !amount.isFinite)
          ? 'Distance unavailable'
          : '${_km(amount ?? 0)} km $suffix';

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
