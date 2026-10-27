import 'package:equatable/equatable.dart';

import '../../../core/firestore/models/models.dart';
import '../../home/model/listing.dart';

/// A single listing match shown on the success screen.
class MatchResult extends Equatable {
  const MatchResult({
    required this.scorePercent,
    required this.title,
    required this.location,
    this.price,
    this.imageAsset,
    this.imageUrl,
    this.propertyId,
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

  /// Remote network image URL for property photo.
  final String? imageUrl;

  /// Associated property document ID.
  final String? propertyId;

  /// Converts a real matched [Listing] from TOPSIS into a [MatchResult].
  factory MatchResult.fromListing(Listing listing) {
    final formattedPrice =
        '₱${listing.pricePerMonth.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}/mo';
    final photo = listing.photoUrl ??
        (listing.photos.isNotEmpty ? listing.photos.first : null);
    return MatchResult(
      scorePercent: listing.matchPercent,
      title: listing.title,
      location: listing.location,
      price: formattedPrice,
      imageUrl: photo,
      propertyId: listing.id,
    );
  }

  /// Converts a real [PropertyDoc] from Firestore into a [MatchResult].
  factory MatchResult.fromProperty(PropertyDoc property, {int scorePercent = 92}) {
    final formattedPrice =
        '₱${property.monthlyRent.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}/mo';
    final photo = property.photos.isNotEmpty ? property.photos.first : null;
    return MatchResult(
      scorePercent: scorePercent,
      title: property.title,
      location: property.address,
      price: formattedPrice,
      imageUrl: photo,
      propertyId: property.propertyId,
    );
  }

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
        imageUrl,
        propertyId,
      ];
}
