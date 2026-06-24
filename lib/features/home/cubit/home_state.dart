part of 'home_cubit.dart';

/// State for [HomeCubit] — holds all listings and the search query.
class HomeState extends Equatable {
  const HomeState({
    this.listings = Listing.samples,
    this.searchQuery = '',
  });

  final List<Listing> listings;
  final String searchQuery;

  /// Top matches for the "Recommended for you" horizontal scroll.
  List<Listing> get recommended {
    final sorted = [...listings]
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return sorted;
  }

  /// All listings for the "Nearby homes" vertical list.
  List<Listing> get nearby => listings;

  /// All listings sorted by match score (Matches tab).
  List<Listing> get allByMatch {
    return [...listings]
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
  }

  /// Only saved listings (Saved tab).
  List<Listing> get saved => listings.where((l) => l.isSaved).toList();

  HomeState copyWith({List<Listing>? listings, String? searchQuery}) {
    return HomeState(
      listings: listings ?? this.listings,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => <Object?>[listings, searchQuery];
}
