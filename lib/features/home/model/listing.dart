import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

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
      sqft: sqft,
      isSaved: isSaved ?? this.isSaved,
      imageSeed: imageSeed,
    );
  }

  /// Prototype sample data.
  static const List<Listing> samples = <Listing>[
    Listing(
      id: '1',
      title: 'Sunny 2-Bed Apartment',
      location: 'Downtown, Portland',
      pricePerMonth: 1800,
      beds: 2,
      baths: 1,
      sqft: 820,
      matchPercent: 92,
      imageSeed: 1,
    ),
    Listing(
      id: '2',
      title: 'Modern Studio Loft',
      location: 'Westside, Portland',
      pricePerMonth: 1250,
      beds: 1,
      baths: 1,
      matchPercent: 88,
      imageSeed: 2,
      isSaved: true,
    ),
    Listing(
      id: '3',
      title: 'Cozy Garden House',
      location: 'North Hills, Portland',
      pricePerMonth: 2200,
      beds: 3,
      baths: 2,
      matchPercent: 84,
      imageSeed: 3,
    ),
    Listing(
      id: '4',
      title: 'Riverside 1-Bed Flat',
      location: 'Riverside, Portland',
      pricePerMonth: 1500,
      beds: 1,
      baths: 1,
      matchPercent: 81,
      imageSeed: 4,
    ),
    Listing(
      id: '5',
      title: 'Bright Boarding Room',
      location: 'Near University, Portland',
      pricePerMonth: 850,
      beds: 1,
      baths: 1,
      matchPercent: 79,
      imageSeed: 5,
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
        sqft,
        isSaved,
        imageSeed,
      ];
}
