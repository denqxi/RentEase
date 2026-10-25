import '../../model/compatible_tenant.dart';
import '../../model/owner_listing.dart';

/// Result of [FindTenantsRepository.fetchCompatibleTenantsForOwner].
///
/// - `byProperty`: full tenant details, only for the requested property ids.
/// - `tenantIdsByProperty`: distinct compatible tenant ids for every one of
///   the owner's properties that has an eligible match (count badges).
typedef OwnerCompatibleTenants = ({
  Map<String, List<CompatibleTenant>> byProperty,
  Map<String, Set<String>> tenantIdsByProperty,
});

/// Reads compatible tenants for Find Tenants — filtering-only (CLAUDE.md:
/// no owner-side TOPSIS instance), so results aren't ranked.
abstract class FindTenantsRepository {
  /// The owner's own properties, newest first.
  Future<List<OwnerListing>> fetchOwnerListings(String ownerId);

  /// Compatible (bScore = 1) tenants for [propertyId].
  Future<List<CompatibleTenant>> fetchCompatibleTenants({
    required String ownerId,
    required String propertyId,
  });

  /// One owner-wide match query; tenant user/profile docs are read once per
  /// tenant (not once per tenant per property) and only for tenants matched
  /// to [detailPropertyIds].
  Future<OwnerCompatibleTenants> fetchCompatibleTenantsForOwner({
    required String ownerId,
    required Set<String> detailPropertyIds,
  });
}
