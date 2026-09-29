import 'package:equatable/equatable.dart';

/// One of the owner's own properties, reduced to what Find Tenants needs:
/// the selector label and the house rules shown as locked chips.
class OwnerListing extends Equatable {
  const OwnerListing({
    required this.propertyId,
    required this.title,
    required this.allowedGender,
    required this.smokingAllowed,
    required this.petsAllowed,
    required this.maxOccupants,
  });

  final String propertyId;
  final String title;
  final String allowedGender;
  final bool smokingAllowed;
  final bool petsAllowed;
  final num maxOccupants;

  /// Layer 1 rules as short chip labels, e.g. `Female only`, `No smoking`.
  List<String> get ruleLabels => [
    switch (allowedGender.trim().toLowerCase()) {
      'female only' => 'Female only',
      'male only' => 'Male only',
      _ => 'Any gender',
    },
    smokingAllowed ? 'Smoking OK' : 'No smoking',
    petsAllowed ? 'Pets OK' : 'No pets',
    'Max $maxOccupants per room',
  ];

  @override
  List<Object?> get props => [
    propertyId,
    title,
    allowedGender,
    smokingAllowed,
    petsAllowed,
    maxOccupants,
  ];
}
