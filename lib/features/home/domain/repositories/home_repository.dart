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
}
