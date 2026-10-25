import '../../../../core/firestore/models/models.dart';
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
    final people = await _fetchPeople({for (final m in matches) m.tenantId});
    return _toTenants(matches, people);
  }

  @override
  Future<OwnerCompatibleTenants> fetchCompatibleTenantsForOwner({
    required String ownerId,
    required Set<String> detailPropertyIds,
  }) async {
    final matches = await _remote.fetchOwnerEligibleMatches(ownerId);
    final idsByProperty = <String, Set<String>>{};
    final detailMatches = <String, List<MatchDoc>>{};
    for (final m in matches) {
      idsByProperty.putIfAbsent(m.propertyId, () => <String>{}).add(m.tenantId);
      if (detailPropertyIds.contains(m.propertyId)) {
        detailMatches.putIfAbsent(m.propertyId, () => []).add(m);
      }
    }
    // A tenant matched to several listings is read once, not once per listing.
    final people = await _fetchPeople({
      for (final list in detailMatches.values)
        for (final m in list) m.tenantId,
    });
    return (
      byProperty: {
        for (final id in detailPropertyIds)
          id: _toTenants(detailMatches[id] ?? const [], people),
      },
      tenantIdsByProperty: idsByProperty,
    );
  }

  /// user + tenant profile per tenant id, both docs read in parallel.
  Future<Map<String, (UserDoc?, TenantProfileDoc?)>> _fetchPeople(
    Set<String> tenantIds,
  ) async {
    final ids = tenantIds.toList();
    final rows = await Future.wait(
      ids.map(
        (id) => (_remote.fetchUser(id), _remote.fetchTenantProfile(id)).wait,
      ),
    );
    return {for (var i = 0; i < ids.length; i++) ids[i]: rows[i]};
  }

  List<CompatibleTenant> _toTenants(
    List<MatchDoc> matches,
    Map<String, (UserDoc?, TenantProfileDoc?)> people,
  ) {
    final out = <CompatibleTenant>[];
    for (final m in matches) {
      final (user, profile) = people[m.tenantId] ?? (null, null);
      if (profile == null) continue; // tenant deleted their profile
      final name = [
        user?.firstName ?? '',
        user?.lastName ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ');
      out.add(
        CompatibleTenant(
          matchId: m.matchId,
          tenantId: m.tenantId,
          name: name.isEmpty ? 'Tenant' : name,
          gender: user?.gender ?? '',
          maxBudget: profile.maxBudget,
          bScore: m.bScore,
          occupation: profile.occupation,
          school: profile.school,
          tenantCi: m.tenantCi,
        ),
      );
    }
    return out;
  }
}
