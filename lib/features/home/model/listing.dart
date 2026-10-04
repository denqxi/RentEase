import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/firestore/models/models.dart';

/// A rental property listing displayed across home, matches, and saved screens.
class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.title,
    required this.location,
    required this.pricePerMonth,
    required this.beds,
    required this.baths,
    required this.matchPercent,
    this.amenityScore = 0,
    this.sqft,
    this.isSaved = false,
    this.imageSeed = 1,
    this.photoUrl,
  });

  final String id;
  final String title;
  final String location;
  final int pricePerMonth;
  final int beds;
  final int baths;
  final int matchPercent;
  final int amenityScore;
  final int? sqft;
  final bool isSaved;

  /// 1–5; selects a distinct placeholder gradient in image widgets.
  final int imageSeed;

  /// First uploaded photo of the property (Cloudinary URL); null falls back
  /// to the [imageSeed] placeholder.
  final String? photoUrl;

  /// Indicator dot color driven by [matchPercent].
  Color get matchDotColor =>
      matchPercent >= 80 ? AppColors.matchHigh : AppColors.matchMedium;

  /// Returns a copy with [isSaved] overridden.
  Listing copyWith({bool? isSaved}) {
    return Listing(
      id: id,
      title: title,
      location: location,
      pricePerMonth: pricePerMonth,
      beds: beds,
      baths: baths,
      matchPercent: matchPercent,
      amenityScore: amenityScore,
      sqft: sqft,
      isSaved: isSaved ?? this.isSaved,
      imageSeed: imageSeed,
      photoUrl: photoUrl,
    );
  }

  /// Built from a real `matches`/`properties` pair — [ci] is the tenant-side
  /// TOPSIS closeness coefficient (0.00–1.00), shown as a rounded percent
  /// per CLAUDE.md's "match display should be consistent" note (percent on
  /// carousels, raw Ci on the search/comparison screens).
  factory Listing.fromMatch({
    required MatchDoc match,
    required PropertyDoc property,
    required int imageSeed,
  }) {
    return Listing(
      id: property.propertyId,
      title: property.title,
      location: property.address,
      pricePerMonth: property.monthlyRent.toInt(),
      // Boarding-house listings aren't modeled with bedroom/bathroom counts
      // (CLAUDE.md's schema has no such fields) — same placeholder the
      // prototype data already used.
      beds: 1,
      baths: 1,
      matchPercent: (((match.tenantCi ?? 0) * 100).round()),
      imageSeed: imageSeed,
      photoUrl: property.photos.isNotEmpty ? property.photos.first : null,
    );
  }

  /// A guest-feed card from a public `properties` doc: no match, so no Ci or
  /// percentage ([matchPercent] stays 0 and is never shown to guests).
  factory Listing.fromProperty({
    required PropertyDoc property,
    required int imageSeed,
  }) {
    return Listing(
      id: property.propertyId,
      title: property.title,
      location: property.address,
      pricePerMonth: property.monthlyRent.toInt(),
      beds: 1,
      baths: 1,
      matchPercent: 0,
      amenityScore: (property.amenityScore ?? property.amenityList.length)
          .toInt(),
      imageSeed: imageSeed,
      photoUrl: property.photos.isNotEmpty ? property.photos.first : null,
    );
  }

  /// Prototype sample data — derived from [MockData.properties] so home,
  /// search, and detail always agree. Only compatible (bScore == 1)
  /// properties appear; matchPercent is the tenant-side Ci score.
  static final List<Listing> samples = [
    for (final (i, p)
        in MockData.properties.where((p) => p['bScore'] == 1).indexed)
      Listing(
        id: p['propertyId'] as String,
        title: p['title'] as String,
        location: p['address'] as String,
        pricePerMonth: (p['monthlyRent'] as num).toInt(),
        beds: 1,
        baths: 1,
        matchPercent: ((p['tenantCi'] as num) * 100).round(),
        amenityScore: (p['amenityScore'] as num?)?.toInt() ?? 0,
        imageSeed: i % 5 + 1,
        isSaved: p['propertyId'] == 'bh002',
      ),
  ];

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    location,
    pricePerMonth,
    beds,
    baths,
    matchPercent,
    amenityScore,
    sqft,
    isSaved,
    imageSeed,
    photoUrl,
  ];
}
