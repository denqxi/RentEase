part of 'search_cubit.dart';

class SearchState extends Equatable {
  const SearchState({
    this.isLoading = true,
    this.errorMessage,
    this.results = const [],
    this.profile,
    this.includeNonMatching = false,
    this.nonMatches = const [],
    this.isLoadingNonMatches = false,
    this.nonMatchesFailed = false,
  });

  final bool isLoading;
  final String? errorMessage;

  /// Full property maps, best TOPSIS Ci first.
  final List<Map<String, dynamic>> results;

  /// The tenant's saved hard constraints - null before onboarding.
  final TenantProfileDoc? profile;

  /// Session-only "Include listings outside my preferences" toggle (default
  /// off; local state, never written to Firestore - CLAUDE.md rule 3).
  final bool includeNonMatching;

  /// View-only listings that fail the saved constraints, each with
  /// `mismatchReasons`; fewest reasons first, then newest. Empty while the
  /// toggle is off. Always shown after [results].
  final List<Map<String, dynamic>> nonMatches;
  final bool isLoadingNonMatches;
  final bool nonMatchesFailed;

  SearchState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? includeNonMatching,
    List<Map<String, dynamic>>? nonMatches,
    bool? isLoadingNonMatches,
    bool? nonMatchesFailed,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      results: results,
      profile: profile,
      includeNonMatching: includeNonMatching ?? this.includeNonMatching,
      nonMatches: nonMatches ?? this.nonMatches,
      isLoadingNonMatches: isLoadingNonMatches ?? this.isLoadingNonMatches,
      nonMatchesFailed: nonMatchesFailed ?? this.nonMatchesFailed,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    results,
    profile,
    includeNonMatching,
    nonMatches,
    isLoadingNonMatches,
    nonMatchesFailed,
  ];
}
