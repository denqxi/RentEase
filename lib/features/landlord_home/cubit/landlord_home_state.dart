part of 'landlord_home_cubit.dart';

/// State for [LandlordHomeCubit].
class LandlordHomeState extends Equatable {
  const LandlordHomeState({
    this.isLoading = false,
    this.errorMessage,
    this.firstName = '',
    this.fullName = '',
    this.photoUrl,
    this.verificationStatus,
    this.properties = const [],
    this.tenants = const [],
    this.tenantsLoading = false,
    this.tenantsError,
    this.searchQuery = '',
  });

  final bool isLoading;
  final String? errorMessage;

  /// Empty until the `users` doc has loaded (or when signed out).
  final String firstName;
  final String fullName;
  final String? photoUrl;

  /// 'none' | 'pending' | 'verified' | 'rejected'; null until first read.
  final String? verificationStatus;
  final List<PropertyDoc> properties;

  /// Compatible (bScore = 1) tenants across the owner's available listings,
  /// alphabetical — never ranked.
  final List<CompatibleTenant> tenants;
  final bool tenantsLoading;
  final String? tenantsError;
  final String searchQuery;

  bool get isVerified => verificationStatus == 'verified';

  /// Owner known to be unverified: show the verification banner (informational only;
  /// verification gates no feature).
  bool get showPendingBanner =>
      verificationStatus != null && verificationStatus != 'verified';

  int get availableCount => properties.where((p) => p.isAvailable).length;

  LandlordHomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? firstName,
    String? fullName,
    String? photoUrl,
    String? verificationStatus,
    List<PropertyDoc>? properties,
    List<CompatibleTenant>? tenants,
    bool? tenantsLoading,
    String? tenantsError,
    bool clearTenantsError = false,
    String? searchQuery,
  }) {
    return LandlordHomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      firstName: firstName ?? this.firstName,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      properties: properties ?? this.properties,
      tenants: tenants ?? this.tenants,
      tenantsLoading: tenantsLoading ?? this.tenantsLoading,
      tenantsError: clearTenantsError
          ? null
          : (tenantsError ?? this.tenantsError),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    firstName,
    fullName,
    photoUrl,
    verificationStatus,
    properties,
    tenants,
    tenantsLoading,
    tenantsError,
    searchQuery,
  ];
}
