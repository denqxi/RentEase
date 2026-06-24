import 'package:equatable/equatable.dart';

/// A single match reason row in the tenant detail match card.
class TenantMatchReason extends Equatable {
  const TenantMatchReason({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  List<Object?> get props => <Object?>[label, met];
}

/// Full detail data for a tenant applicant shown in the landlord detail screen.
class TenantDetail extends Equatable {
  const TenantDetail({
    required this.id,
    required this.name,
    required this.occupation,
    required this.incomeRange,
    required this.matchPercent,
    required this.matchLabel,
    required this.matchSummary,
    required this.matchReasons,
    required this.monthlyIncome,
    required this.occupants,
    required this.smoking,
    required this.pets,
    required this.moveIn,
    required this.imageSeed,
    this.isSaved = false,
    this.isVerified = true,
  });

  final String id;
  final String name;
  final String occupation;
  final String incomeRange;
  final int matchPercent;
  final String matchLabel;
  final String matchSummary;
  final List<TenantMatchReason> matchReasons;
  final String monthlyIncome;
  final String occupants;
  final String smoking;
  final String pets;
  final String moveIn;
  final int imageSeed;
  final bool isSaved;
  final bool isVerified;

  TenantDetail copyWith({bool? isSaved}) => TenantDetail(
        id: id,
        name: name,
        occupation: occupation,
        incomeRange: incomeRange,
        matchPercent: matchPercent,
        matchLabel: matchLabel,
        matchSummary: matchSummary,
        matchReasons: matchReasons,
        monthlyIncome: monthlyIncome,
        occupants: occupants,
        smoking: smoking,
        pets: pets,
        moveIn: moveIn,
        imageSeed: imageSeed,
        isSaved: isSaved ?? this.isSaved,
        isVerified: isVerified,
      );

  static const TenantDetail sample = TenantDetail(
    id: '1',
    name: 'Jane Doe',
    occupation: 'Product Designer',
    incomeRange: '\$1.5k–2k',
    matchPercent: 94,
    matchLabel: 'Strong fit for your property',
    matchSummary: 'Matched on your tenant requirements.',
    matchReasons: <TenantMatchReason>[
      TenantMatchReason(label: 'Income meets your requirement', met: true),
      TenantMatchReason(label: 'Non-smoker, as preferred', met: true),
      TenantMatchReason(label: 'Within max occupants', met: true),
      TenantMatchReason(label: 'Working professional', met: true),
    ],
    monthlyIncome: '\$3,500/mo',
    occupants: '2 people',
    smoking: 'Non-smoker',
    pets: 'None',
    moveIn: 'Within 1 month',
    imageSeed: 1,
  );

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        occupation,
        incomeRange,
        matchPercent,
        matchLabel,
        matchSummary,
        matchReasons,
        monthlyIncome,
        occupants,
        smoking,
        pets,
        moveIn,
        imageSeed,
        isSaved,
        isVerified,
      ];
}
