import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';

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

  /// Guest browse pool — all listed properties, no TOPSIS filtering.
  static final List<Listing> guestSamples = [
    for (final (i, p) in MockData.properties.indexed)
      Listing(
        id: p['propertyId'] as String,
        title: p['title'] as String,
        location: p['address'] as String,
        pricePerMonth: (p['monthlyRent'] as num).toInt(),
        beds: 1,
        baths: 1,
        matchPercent: 0,
        amenityScore: (p['amenityScore'] as num?)?.toInt() ?? 0,
        imageSeed: i % 5 + 1,
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
      ];
}
