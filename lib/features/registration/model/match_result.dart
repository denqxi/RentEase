import 'package:equatable/equatable.dart';

/// A single listing match shown on the success screen.
class MatchResult extends Equatable {
  const MatchResult({
    required this.scorePercent,
    required this.title,
    required this.location,
    this.price,
    this.imageAsset,
  });

  /// Compatibility score, 0–100.
  final int scorePercent;

  /// Short listing title (e.g. "Sunshine Boarding House").
  final String title;

  /// Listing summary line (e.g. "245 Taft Ave, Malate, Manila").
  final String location;

  /// Monthly rental price (e.g. "₱8,500/mo").
  final String? price;

  /// Image asset path for property thumbnail.
  final String? imageAsset;

  /// Sample presented to tenants once registration completes.
  static const MatchResult tenantSample = MatchResult(
    scorePercent: 96,
    title: 'Sunshine Boarding House',
    location: '245 Taft Ave, Malate, Manila',
    price: '₱8,500/mo',
    imageAsset: 'assets/images/hero-interior.png',
  );

  /// Sample presented to landlords once registration completes.
  static const MatchResult landlordSample = MatchResult(
    scorePercent: 96,
    title: 'Verified Students',
    location: '245 Taft Ave, Malate, Manila',
    price: '₱8,500/mo budget',
    imageAsset: 'assets/images/hero-interior.png',
  );

  /// Top three listings presented to tenants on the success screen.
  static const List<MatchResult> tenantTopMatches = <MatchResult>[
    tenantSample,
    MatchResult(
      scorePercent: 92,
      title: 'BlueSky Dormitory',
      location: '1024 España Blvd, Sampaloc, Manila',
      price: '₱7,200/mo',
      imageAsset: 'assets/images/hero-room.png',
    ),
    MatchResult(
      scorePercent: 88,
      title: 'Green Leaf Boarding House',
      location: '789 Katipunan Ave, Loyola Heights, QC',
      price: '₱9,000/mo',
      imageAsset: 'assets/images/hero-modern.png',
    ),
  ];

  /// Top three tenant matches presented to landlords on the success screen.
  static const List<MatchResult> landlordTopMatches = <MatchResult>[
    landlordSample,
    MatchResult(
      scorePercent: 92,
      title: 'Young Professionals',
      location: '1024 España Blvd, Sampaloc, Manila',
      price: '₱7,200/mo budget',
      imageAsset: 'assets/images/hero-room.png',
    ),
    MatchResult(
      scorePercent: 88,
      title: 'Graduate Researchers',
      location: '789 Katipunan Ave, Loyola Heights, QC',
      price: '₱9,000/mo budget',
      imageAsset: 'assets/images/hero-modern.png',
    ),
  ];

  /// @deprecated Use [tenantSample] or [landlordSample].
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
