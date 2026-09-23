import '../../../../core/firestore/models/tenant_profile_doc.dart';

/// Persists the tenant's matching profile (`tenantProfiles/{uid}`).
///
/// Saving is the trigger for server-side matching (CLAUDE.md rule 7): Cloud
/// Functions listen for writes to this document and recompute B_scores and
/// TOPSIS rankings. Nothing here computes scores — it only stores inputs.
abstract class TenantProfileRepository {
  /// Creates or overwrites the tenant's profile inputs. Server-computed
  /// fields (avgRating, credibilityScore, …) are never written from here —
  /// the security rules reject them anyway.
  Future<void> saveProfile(TenantProfileDoc profile);

  Future<TenantProfileDoc?> fetchProfile(String uid);
}
