import '../../../../core/firestore/models/models.dart';
import '../entities/admin_entities.dart';

/// Admin-side data access. Every write also appends an `adminLogs` entry in
/// the same batch, attributed to the signed-in admin. Throws
/// [AdminException] with a friendly message on failure.
abstract class AdminRepository {
  // ---- auth ----
  /// Signs in and verifies `users/{uid}.role == 'admin'`; otherwise signs
  /// back out and throws. Admin accounts exist in the console only.
  Future<void> signIn(String email, String password);
  Future<void> signOut();

  // ---- verifications ----
  /// Owners with status pending / verified / rejected, newest submission first.
  Stream<List<VerificationItem>> watchVerifications();
  Future<VerificationDocuments> fetchDocuments(String ownerId);

  /// pending -> verified (+ verifiedAt), badge flag on the owner's listings.
  Future<void> approveOwner(String ownerId);

  /// pending -> rejected (+ rejectedAt, optional reason).
  Future<void> rejectOwner(String ownerId, {String? reason});

  // ---- users ----
  Stream<List<UserDoc>> watchUsers();
  Future<void> setUserSuspended(String userId, {required bool suspended});

  // ---- properties ----
  Stream<List<AdminPropertyItem>> watchProperties();
  Future<void> setPropertyListed(String propertyId, {required bool listed});

  // ---- analytics ----
  Future<AdminStats> fetchStats();
  Stream<List<AdminLogDoc>> watchRecentLogs({int limit = 5});
}
