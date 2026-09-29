import '../../domain/repositories/find_tenants_repository.dart';
import '../../model/compatible_tenant.dart';
import '../../model/owner_listing.dart';
import '../datasources/find_tenants_remote_datasource.dart';

class FindTenantsRepositoryImpl implements FindTenantsRepository {
  FindTenantsRepositoryImpl({FindTenantsRemoteDataSource? remote})
    : _remote = remote ?? FindTenantsRemoteDataSource();

  final FindTenantsRemoteDataSource _remote;

  @override
  Future<List<OwnerListing>> fetchOwnerListings(String ownerId) async {
    final properties = await _remote.fetchOwnerProperties(ownerId);
    return [
      for (final p in properties)
        OwnerListing(
          propertyId: p.propertyId,
          title: p.title,
          allowedGender: p.allowedGender,
          smokingAllowed: p.smokingAllowed,
          petsAllowed: p.petsAllowed,
          maxOccupants: p.maxOccupants,
        ),
    ];
  }

  @override
  Future<List<CompatibleTenant>> fetchCompatibleTenants({
    required String ownerId,
    required String propertyId,
  }) async {
    final matches = await _remote.fetchEligibleMatches(
      ownerId: ownerId,
      propertyId: propertyId,
    );

    final tenants = await Future.wait(
      matches.map((m) async {
        final (user, profile) = await (
          _remote.fetchUser(m.tenantId),
          _remote.fetchTenantProfile(m.tenantId),
        ).wait;
        if (profile == null) return null; // tenant deleted their profile
        final name = [
          user?.firstName ?? '',
          user?.lastName ?? '',
        ].where((s) => s.trim().isNotEmpty).join(' ');
        return CompatibleTenant(
          matchId: m.matchId,
          tenantId: m.tenantId,
          name: name.isEmpty ? 'Tenant' : name,
          gender: user?.gender ?? '',
          maxBudget: profile.maxBudget,
          bScore: m.bScore,
          occupation: profile.occupation,
          school: profile.school,
        );
      }),
    );

    return tenants.whereType<CompatibleTenant>().toList();
  }
}
