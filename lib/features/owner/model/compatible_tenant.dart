import 'package:equatable/equatable.dart';

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
  });

  final String matchId;
  final String tenantId;
  final String name;
  final String gender;
  final num maxBudget;
  final num bScore;
  final String? occupation;
  final String? school;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
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
  ];
}
