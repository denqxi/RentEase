import 'package:equatable/equatable.dart';

/// A listing match shown on the success screen.
class MatchResult extends Equatable {
  const MatchResult({
    required this.scorePercent,
    required this.title,
    required this.location,
    this.price = '₱8,500/mo',
    this.imageAsset = 'assets/images/hero-modern.png',
  });

  /// Compatibility score, 0–100.
  final int scorePercent;

  /// Short listing title / property name.
  final String title;

  /// Listing summary / unit details / address.
  final String location;

  /// Price / monthly rent or budget.
  final String price;

  /// Preview thumbnail asset path.
  final String imageAsset;

  static const MatchResult tenantSample = MatchResult(
    scorePercent: 96,
    title: 'Sunshine Boarding House',
    location: '245 Taft Ave, Malate, Manila',
    price: '₱8,500/mo',
    imageAsset: 'assets/images/hero-modern.png',
  );

  static const MatchResult landlordSample = MatchResult(
    scorePercent: 96,
    title: 'Sunshine Boarding House',
    location: '245 Taft Ave, Malate, Manila',
    price: '₱8,500/mo budget',
    imageAsset: 'assets/images/hero-room.png',
  );

  /// Top 3 matches for tenants.
  static const List<MatchResult> tenantTopMatches = <MatchResult>[
    tenantSample,
    MatchResult(
      scorePercent: 92,
      title: 'BlueSky Dormitory',
      location: '1024 España Blvd, Sampaloc, Manila',
      price: '₱7,200/mo',
      imageAsset: 'assets/images/hero-interior.png',
    ),
    MatchResult(
      scorePercent: 88,
      title: 'Green Leaf Boarding House',
      location: '789 Katipunan Ave, Loyola Heights, QC',
      price: '₱9,000/mo',
      imageAsset: 'assets/images/hero-building.png',
    ),
  ];

  /// Top 3 matches for landlords.
  static const List<MatchResult> landlordTopMatches = <MatchResult>[
    landlordSample,
    MatchResult(
      scorePercent: 92,
      title: 'BlueSky Dormitory',
      location: '1024 España Blvd, Sampaloc, Manila',
      price: '₱7,200/mo budget',
      imageAsset: 'assets/images/hero-interior.png',
    ),
    MatchResult(
      scorePercent: 88,
      title: 'Green Leaf Boarding House',
      location: '789 Katipunan Ave, Loyola Heights, QC',
      price: '₱9,000/mo budget',
      imageAsset: 'assets/images/hero-modern.png',
    ),
  ];

  static const MatchResult sample = tenantSample;

  @override
  List<Object?> get props => <Object?>[
        scorePercent,
        title,
        location,
        price,
        imageAsset,
      ];
}
