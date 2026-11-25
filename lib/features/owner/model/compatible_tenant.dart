import 'package:equatable/equatable.dart';

// Compiled once instead of on every call.
final RegExp _kWhitespaceRe = RegExp(r'\s+');

/// One compatible (bScore = 1) tenant for a property, as shown on a Find
/// Tenants card — joined from `matches`, `users` and `tenantProfiles`.
///
/// Owner-side tenant discovery is filtering-only (CLAUDE.md — there is no
/// owner-side TOPSIS instance), so this list carries no ranking score.
class CompatibleTenant extends Equatable {
  const CompatibleTenant({
    required this.matchId,
    required this.tenantId,
    required this.name,
    required this.gender,
    required this.maxBudget,
    required this.bScore,
    this.occupation,
    this.school,
    this.tenantCi,
    this.groupSize,
    this.moveInDate,
    this.avgRating,
    this.ratingCount = 0,
  });

  final String matchId;
  final String tenantId;
  final String name;
  final String gender;
  final num maxBudget;
  final num bScore;
  final String? occupation;
  final String? school;
  final num? tenantCi;
  final int? groupSize;
  final DateTime? moveInDate;

  /// Average of owners' ratings; null until the first one.
  final double? avgRating;
  final int ratingCount;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "Female · 2 people", leaving out whatever is unknown.
  String get genderAndGroup {
    final size = groupSize;
    final parts = [
      if (gender.trim().isNotEmpty) gender.trim() else 'Gender not set',
      if (size != null && size > 0)
        size == 1 ? '1 person' : '$size people'
      else
        'Group size not set',
    ];
    return parts.join(' · ');
  }

  String get occupationLabel => (occupation?.trim().isNotEmpty ?? false)
      ? occupation!.trim()
      : 'Occupation not set';

  String get moveInLabel {
    final d = moveInDate;
    return d == null
        ? 'Move-in date not set'
        : 'Move-in ${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String get ratingLabel {
    final avg = avgRating;
    return avg == null || ratingCount <= 0
        ? 'No ratings yet'
        : '${avg.toStringAsFixed(1)} ($ratingCount '
              '${ratingCount == 1 ? 'rating' : 'ratings'})';
  }

  String get initials {
    final parts = name.trim().split(_kWhitespaceRe).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  List<Object?> get props => [
    matchId,
    tenantId,
    name,
    gender,
    maxBudget,
    bScore,
    occupation,
    school,
    tenantCi,
    groupSize,
    moveInDate,
    avgRating,
    ratingCount,
  ];
}
