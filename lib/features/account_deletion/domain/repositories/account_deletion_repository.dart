/// Why a deletion step failed, already mapped from the data layer.
enum AccountDeletionFailureKind {
  /// The password typed for re-authentication is wrong.
  wrongPassword,

  /// Firebase wants a fresher sign-in than the one just made.
  requiresRecentLogin,

  /// No connection / timeout.
  network,

  /// Too many attempts, or rules denied a step (e.g. suspended account).
  denied,

  /// Anything else.
  unknown,
}

class AccountDeletionFailure implements Exception {
  const AccountDeletionFailure(this.kind);

  final AccountDeletionFailureKind kind;

  @override
  String toString() => 'AccountDeletionFailure($kind)';
}

/// Data access for "Delete my account". Every step is idempotent (deleting a
/// doc that is already gone succeeds) so the whole flow can be retried after
/// a partial failure. Implementations throw [AccountDeletionFailure].
abstract class AccountDeletionRepository {
  /// Re-authenticates the signed-in user with their current password.
  Future<void> reauthenticate(String password);

  /// Owner: best-effort close of the owner's pending/active inquiries (never
  /// throws; rules may refuse, e.g. for a rejected owner).
  Future<void> closeOwnerOpenInquiries(String uid);

  /// Owner: every property the owner listed, rooms first, then the listing.
  Future<void> deleteOwnerProperties(String uid);

  /// `notifications` where recipientId == [uid].
  Future<void> deleteNotifications(String uid);

  /// Tenant: `matches` where tenantId == [uid].
  Future<void> deleteTenantMatches(String uid);

  /// Tenant: `users/{uid}/savedListings/*`.
  Future<void> deleteSavedListings(String uid);

  /// Tenant: `tenantProfiles/{uid}/private/*` then `tenantProfiles/{uid}`.
  Future<void> deleteTenantProfile(String uid);

  /// Owner: `ownerProfiles/{uid}/private/*` then `ownerProfiles/{uid}`.
  Future<void> deleteOwnerProfile(String uid);

  /// `users/{uid}/private/*` (email, phone, emergency contact).
  Future<void> deleteUserPrivate(String uid);

  /// `users/{uid}`. Must run after every step above: later rules read it.
  Future<void> deleteUserDoc(String uid);

  /// Deletes the Firebase Auth account (`currentUser.delete()`).
  Future<void> deleteAuthAccount();

  Future<void> signOut();
}
