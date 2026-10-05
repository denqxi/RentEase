import '../repositories/account_deletion_repository.dart';

/// Runs the in-app account deletion (no backend). Order matters and is fixed:
///
///  1. re-authenticate (current password)
///  2. notifications; role data (tenant: matches, saved listings, profile;
///     owner: close open inquiries, rooms + listings, profile + documents)
///  3. users/{uid}/private/*
///  4. users/{uid}            (rules for steps above read it, so it goes last)
///  5. the Firebase Auth account
///
/// Each step is idempotent, so calling [deleteAccount] again after a failure
/// resumes the work. Chat/inquiry records, ratings and `matches` rows that
/// belong to other users are NOT deleted.
class AccountDeletionService {
  AccountDeletionService({required this._repository});

  final AccountDeletionRepository _repository;

  Future<void> deleteAccount({
    required String uid,
    required bool isOwner,
    required String password,
  }) async {
    try {
      await _repository.reauthenticate(password);
      await _repository.deleteNotifications(uid);
      if (isOwner) {
        await _repository.closeOwnerOpenInquiries(uid);
        await _repository.deleteOwnerProperties(uid);
        await _repository.deleteOwnerProfile(uid);
      } else {
        await _repository.deleteTenantMatches(uid);
        await _repository.deleteSavedListings(uid);
        await _repository.deleteTenantProfile(uid);
      }
      await _repository.deleteUserPrivate(uid);
      await _repository.deleteUserDoc(uid);
      await _repository.deleteAuthAccount();
    } on AccountDeletionFailure {
      rethrow;
    } catch (_) {
      throw const AccountDeletionFailure(AccountDeletionFailureKind.unknown);
    }
    try {
      await _repository.signOut();
    } catch (_) {
      // The account is already gone; a failed local sign-out is harmless.
    }
  }
}
