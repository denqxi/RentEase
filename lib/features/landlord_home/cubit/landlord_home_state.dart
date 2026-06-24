part of 'landlord_home_cubit.dart';

/// State for [LandlordHomeCubit].
class LandlordHomeState extends Equatable {
  const LandlordHomeState({
    this.tenants = Tenant.samples,
    this.property = LandlordProperty.sample,
    this.searchQuery = '',
  });

  final List<Tenant> tenants;
  final LandlordProperty property;
  final String searchQuery;

  /// Tenants sorted by match score descending.
  List<Tenant> get allByMatch =>
      List<Tenant>.from(tenants)..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));

  /// Top matches shown on the home screen compatible-tenants section.
  List<Tenant> get compatible => allByMatch;

  /// Only saved tenants.
  List<Tenant> get saved => tenants.where((t) => t.isSaved).toList();

  LandlordHomeState copyWith({
    List<Tenant>? tenants,
    LandlordProperty? property,
    String? searchQuery,
  }) {
    return LandlordHomeState(
      tenants: tenants ?? this.tenants,
      property: property ?? this.property,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => <Object?>[tenants, property, searchQuery];
}
