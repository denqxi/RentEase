import 'package:equatable/equatable.dart';

/// One of the owner's available properties that a compatible tenant can be
/// invited to — backed by an existing bScore = 1 `matches` row.
class InviteOption extends Equatable {
  const InviteOption({
    required this.matchId,
    required this.propertyId,
    required this.propertyTitle,
  });

  /// The match row (and, once sent, the invitation's document ID).
  final String matchId;
  final String propertyId;
  final String propertyTitle;

  @override
  List<Object?> get props => [matchId, propertyId, propertyTitle];
}
