import 'package:equatable/equatable.dart';

/// Match reason shown inside the detail screen's match card.
class MatchReason extends Equatable {
  const MatchReason({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  List<Object?> get props => <Object?>[label, met];
}

/// Full detail data for a listing, extending the summary [Listing].
class ListingDetail extends Equatable {
  const ListingDetail({
    required this.id,
    required this.title,
    required this.location,
    required this.pricePerMonth,
    required this.beds,
    required this.baths,
    required this.sqft,
    required this.propertyType,
    required this.matchPercent,
    required this.matchLabel,
    required this.matchSummary,
    required this.matchReasons,
    required this.description,
    required this.amenities,
    required this.landlordName,
    required this.landlordRole,
    required this.landlordResponseTime,
    required this.imageSeed,
    this.isSaved = false,
  });

  final String id;
  final String title;
  final String location;
  final int pricePerMonth;
  final int beds;
  final int baths;
  final int sqft;
  final String propertyType;
  final int matchPercent;
  final String matchLabel;
  final String matchSummary;
  final List<MatchReason> matchReasons;
  final String description;
  final List<String> amenities;
  final String landlordName;
  final String landlordRole;
  final String landlordResponseTime;
  final int imageSeed;
  final bool isSaved;

  ListingDetail copyWith({bool? isSaved}) => ListingDetail(
        id: id,
        title: title,
        location: location,
        pricePerMonth: pricePerMonth,
        beds: beds,
        baths: baths,
        sqft: sqft,
        propertyType: propertyType,
        matchPercent: matchPercent,
        matchLabel: matchLabel,
        matchSummary: matchSummary,
        matchReasons: matchReasons,
        description: description,
        amenities: amenities,
        landlordName: landlordName,
        landlordRole: landlordRole,
        landlordResponseTime: landlordResponseTime,
        imageSeed: imageSeed,
        isSaved: isSaved ?? this.isSaved,
      );

  static const ListingDetail sample = ListingDetail(
    id: '1',
    title: 'Sunny 2-Bed Apartment',
    location: 'Downtown, Portland',
    pricePerMonth: 1800,
    beds: 2,
    baths: 1,
    sqft: 820,
    propertyType: 'Apartment',
    matchPercent: 92,
    matchLabel: 'Excellent match',
    matchSummary: 'Based on your budget, location and lifestyle preferences.',
    matchReasons: <MatchReason>[
      MatchReason(label: 'Within your \$1,500–2,000 budget', met: true),
      MatchReason(label: 'Matches your preferred location', met: true),
      MatchReason(label: 'Pets allowed', met: true),
      MatchReason(label: 'Includes Wi-Fi & parking', met: true),
      MatchReason(label: 'No on-site gym', met: false),
    ],
    description:
        'A light-filled corner apartment with floor-to-ceiling windows, a renovated kitchen, and a quiet balcony overlooking the park. Walking distance to transit, cafés, and the riverfront.',
    amenities: <String>[
      'Wi-Fi',
      'Parking',
      'Furnished',
      'Pet friendly',
      'Balcony',
      'Laundry',
    ],
    landlordName: 'Sarah Chen',
    landlordRole: 'Property owner',
    landlordResponseTime: 'Usually replies in 1h',
    imageSeed: 1,
  );

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        location,
        pricePerMonth,
        beds,
        baths,
        sqft,
        propertyType,
        matchPercent,
        matchLabel,
        matchSummary,
        matchReasons,
        description,
        amenities,
        landlordName,
        landlordRole,
        landlordResponseTime,
        imageSeed,
        isSaved,
      ];
}
