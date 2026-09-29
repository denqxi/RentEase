import '../../../../core/firestore/models/models.dart';
import '../../model/listing.dart';

/// Reads the tenant's already-computed matching results for display —
/// never runs the algorithm itself (that's `FilteringService`/`TopsisService`;
/// see CLAUDE.md "TOPSIS Runs in Dedicated Services, Never Inline").
abstract class HomeRepository {
  /// Eligible (bScore = 1) properties for this tenant, sorted by
  /// `tenantRank` — the TOPSIS output, never by distance alone (CLAUDE.md
  /// rule 9).
  Future<List<Listing>> fetchCompatibleListings(String tenantId);

  /// Assembles the detail-screen map for one property — includes the owner
  /// summary (name/initials/member-since/property count) that the listing
  /// feed itself doesn't need.
  Future<Map<String, dynamic>?> fetchPropertyDetail({
    required String tenantId,
    required String propertyId,
  });

  /// Every eligible, still-available property as a full detail map (same
  /// shape as [fetchPropertyDetail], so Search, its map view and the detail
  /// screen all read one format), best TOPSIS Ci first — never by distance
  /// alone (CLAUDE.md rule 9). Reads cached matches only; never re-runs
  /// matching (CLAUDE.md rule 7).
  Future<List<Map<String, dynamic>>> fetchSearchResults(String tenantId);

  /// The tenant's saved hard constraints — shown as Search's filter chips.
  Future<TenantProfileDoc?> fetchTenantProfile(String tenantId);
}
