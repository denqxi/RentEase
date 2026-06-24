import 'package:equatable/equatable.dart';

/// A single listing match shown on the success screen.
class MatchResult extends Equatable {
  const MatchResult({
    required this.scorePercent,
    required this.title,
    required this.location,
  });

  /// Compatibility score, 0–100.
  final int scorePercent;

  /// Short listing title (e.g. "Top match found").
  final String title;

  /// Listing summary line (e.g. "Sunny 2-bed apartment, Downtown").
  final String location;

  /// Sample presented to tenants once registration completes.
  static const MatchResult tenantSample = MatchResult(
    scorePercent: 92,
    title: 'Top match found',
    location: 'Sunny 2-bed apartment, Downtown',
  );

  /// Sample presented to landlords once registration completes.
  static const MatchResult landlordSample = MatchResult(
    scorePercent: 88,
    title: '6 compatible tenants',
    location: 'Sorted by best match for your property',
  );

  /// @deprecated Use [tenantSample] or [landlordSample].
  static const MatchResult sample = tenantSample;

  @override
  List<Object?> get props => <Object?>[scorePercent, title, location];
}
