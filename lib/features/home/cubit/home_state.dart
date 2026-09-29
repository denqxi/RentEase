part of 'home_cubit.dart';

/// State for [HomeCubit] — holds all listings and the search query.
class HomeState extends Equatable {
  HomeState({
    List<Listing>? listings,
    this.searchQuery = '',
    this.isGuest = false,
  }) : listings = listings ??
            (isGuest ? Listing.guestSamples : Listing.samples);

  final List<Listing> listings;
  final String searchQuery;
  final bool isGuest;

  /// Top matches for the "Recommended for you" horizontal scroll.
  List<Listing> get recommended {
    if (isGuest) {
      final sorted = [...listings]
        ..sort((a, b) => b.amenityScore.compareTo(a.amenityScore));
      return sorted;
    }
    final sorted = [...listings]
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return sorted;
  }

  /// All listings for the "Nearby homes" vertical list.
  List<Listing> get nearby {
    if (isGuest) {
      return [...listings]
        ..sort((a, b) => b.amenityScore.compareTo(a.amenityScore));
    }
    return listings;
  }

  /// All listings sorted by match score (Matches tab).
  List<Listing> get allByMatch {
    if (isGuest) {
      return [...listings]
        ..sort((a, b) => b.amenityScore.compareTo(a.amenityScore));
    }
    return [...listings]
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
  }

  /// Only saved listings (Saved tab).
  List<Listing> get saved => listings.where((l) => l.isSaved).toList();

  HomeState copyWith({
    List<Listing>? listings,
    String? searchQuery,
    bool? isGuest,
  }) {
    return HomeState(
      listings: listings ?? this.listings,
      searchQuery: searchQuery ?? this.searchQuery,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => <Object?>[listings, searchQuery, isGuest];
}
