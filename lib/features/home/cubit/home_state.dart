part of 'home_cubit.dart';

/// State for [HomeCubit] — holds all listings and the search query.
class HomeState extends Equatable {
  const HomeState({
    List<Listing>? listings,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.isGuest = false,
    this.otherListings = const [],
    this.isLoadingOthers = false,
    this.othersFailed = false,
    this.searchNonMatchesRequests = 0,
    this.savedIds = const {},
    this.savedListings = const [],
    this.isLoadingSaved = false,
    this.savedLoadFailed = false,
    this.saveFailures = 0,
  }) : listings = listings ?? const <Listing>[];

  /// "Other listings": view-only property maps (`isNonMatch`, `bScore` 0,
  /// `mismatchReasons`) that fail the tenant's saved preferences. Separate
  /// from [listings]; never ranked, never inquirable.
  final List<Map<String, dynamic>> otherListings;
  final bool isLoadingOthers;
  final bool othersFailed;

  /// Bumped by "See more" so Search switches its non-match toggle on.
  final int searchNonMatchesRequests;

  /// Ids the tenant has hearted (users/{uid}/savedListings). The single source
  /// of truth for every heart; guests never get any.
  final Set<String> savedIds;

  /// Saved screen data: the available properties among [savedIds] (loaded on
  /// demand by `loadSaved`; unsaved ones are filtered out by the screen).
  final List<Listing> savedListings;
  final bool isLoadingSaved;
  final bool savedLoadFailed;

  /// Bumped when a save/unsave write failed and was rolled back, so the UI
  /// shows a SnackBar once.
  final int saveFailures;

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

  /// Compatible listings that are hearted (the Saved screen reads
  /// [savedListings] instead, which also covers non-match listings).
  List<Listing> get saved => listings.where((l) => l.isSaved).toList();

  HomeState copyWith({
    List<Listing>? listings,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isGuest,
    List<Map<String, dynamic>>? otherListings,
    bool? isLoadingOthers,
    bool? othersFailed,
    int? searchNonMatchesRequests,
    Set<String>? savedIds,
    List<Listing>? savedListings,
    bool? isLoadingSaved,
    bool? savedLoadFailed,
    int? saveFailures,
  }) {
    return HomeState(
      otherListings: otherListings ?? this.otherListings,
      isLoadingOthers: isLoadingOthers ?? this.isLoadingOthers,
      othersFailed: othersFailed ?? this.othersFailed,
      searchNonMatchesRequests:
          searchNonMatchesRequests ?? this.searchNonMatchesRequests,
      savedIds: savedIds ?? this.savedIds,
      savedListings: savedListings ?? this.savedListings,
      isLoadingSaved: isLoadingSaved ?? this.isLoadingSaved,
      savedLoadFailed: savedLoadFailed ?? this.savedLoadFailed,
      saveFailures: saveFailures ?? this.saveFailures,
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
    otherListings,
    isLoadingOthers,
    othersFailed,
    searchNonMatchesRequests,
    savedIds,
    savedListings,
    isLoadingSaved,
    savedLoadFailed,
    saveFailures,
  ];
}
