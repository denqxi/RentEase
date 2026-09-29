part of 'find_tenants_cubit.dart';

class FindTenantsState extends Equatable {
  const FindTenantsState({
    this.isLoading = true,
    this.errorMessage,
    this.listings = const [],
    this.selectedPropertyId,
    this.tenants = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final List<OwnerListing> listings;
  final String? selectedPropertyId;
  final List<CompatibleTenant> tenants;

  OwnerListing? get selectedListing {
    for (final l in listings) {
      if (l.propertyId == selectedPropertyId) return l;
    }
    return null;
  }

  FindTenantsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<OwnerListing>? listings,
    String? selectedPropertyId,
    List<CompatibleTenant>? tenants,
  }) {
    return FindTenantsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      listings: listings ?? this.listings,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      tenants: tenants ?? this.tenants,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    listings,
    selectedPropertyId,
    tenants,
  ];
}
