import '../../../../core/firestore/models/models.dart';

/// Persists the owner onboarding flow: verification request
/// (`ownerProfiles/{uid}`) and the first listing (`properties`). Owner-side
/// TOPSIS weights are fixed (CLAUDE.md — not owner-adjustable), so there's
/// nothing here to save for those; [submitForVerification] records the fixed
/// defaults on the profile once, for reference.
abstract class OwnerOnboardingRepository {
  /// Marks the owner as awaiting admin review. Returns the resulting
  /// verification status — an already `verified` or `pending` owner is left
  /// untouched, so re-running the flow never downgrades an approval.
  Future<String> submitForVerification(String uid);

  /// Live `verificationStatus` ('none' | 'pending' | 'verified' |
  /// 'rejected'), so the pending screen advances the moment an admin approves.
  Stream<String> watchVerificationStatus(String uid);

  /// Creates the listing and returns its new document ID.
  Future<String> createProperty(PropertyDoc property);
}
