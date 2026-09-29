part of 'search_cubit.dart';

class SearchState extends Equatable {
  const SearchState({
    this.isLoading = true,
    this.errorMessage,
    this.results = const [],
    this.profile,
  });

  final bool isLoading;
  final String? errorMessage;

  /// Full property maps, best TOPSIS Ci first.
  final List<Map<String, dynamic>> results;

  /// The tenant's saved hard constraints — null before onboarding.
  final TenantProfileDoc? profile;

  SearchState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      results: results,
      profile: profile,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, results, profile];
}
