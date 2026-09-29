import '../../model/compatible_tenant.dart';
import '../../model/owner_listing.dart';

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
}
