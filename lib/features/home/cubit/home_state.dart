part of 'home_cubit.dart';

/// State for [HomeCubit] — holds all listings and the search query.
class HomeState extends Equatable {
  const HomeState({
    List<Listing>? listings,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.isGuest = false,
  }) : listings = listings ?? const <Listing>[];

  final List<Listing> listings;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  /// True for the unauthenticated browse mode — no tenantProfiles/matches to
  /// read, so listings are the public newest-first feed and unranked.
  final bool isGuest;

  /// Top matches for the "Recommended for you" horizontal scroll.
  List<Listing> get recommended {
    // Guests keep the feed's newest-first order: there is no Ci to rank by.
    if (isGuest) return listings;
    final sorted = [...listings]
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return sorted;
  }

  /// All listings for the "Compatible properties" vertical list — sorted by
  /// TOPSIS Ci score, never by distance alone (CLAUDE.md rule 9). Guests
  /// have no Ci score at all, so they see the newest-first feed as loaded.
  List<Listing> get nearby => listings;

  /// All listings sorted by match score (Matches tab).
  List<Listing> get allByMatch {
    if (isGuest) return listings;
    return [...listings]
      ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
  }

  /// Only saved listings (Saved tab).
  List<Listing> get saved => listings.where((l) => l.isSaved).toList();

  HomeState copyWith({
    List<Listing>? listings,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isGuest,
  }) {
    return HomeState(
      listings: listings ?? this.listings,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    listings,
    searchQuery,
    isLoading,
    errorMessage,
    isGuest,
  ];
}
