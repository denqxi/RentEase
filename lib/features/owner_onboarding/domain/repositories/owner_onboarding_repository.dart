import '../../../../core/firestore/models/models.dart';
import '../../../uploads/domain/entities/uploaded_image.dart';
import '../entities/owner_credentials.dart';
import '../entities/submitted_documents.dart';

/// Persists the owner onboarding flow: verification request
/// (`ownerProfiles/{uid}`) and the first listing (`properties`). Owner-side
/// TOPSIS weights are fixed (CLAUDE.md — not owner-adjustable), so there's
/// nothing here to save for those; [submitForVerification] records the fixed
/// defaults on the profile once, for reference.
abstract class OwnerOnboardingRepository {
  /// Marks the owner as awaiting admin review. Returns the resulting
  /// verification status — an already `verified` or `pending` owner is left
  /// untouched, so re-running the flow never downgrades an approval.
  ///
  /// [documents] are the already-uploaded verification images; they are
  /// stored as `documentUrls` / `documentPublicIds`. [businessPermit] and
  /// [ownershipDocument], when given, are also stored where tenants can read
  /// them once the owner is verified and shows credentials.
  Future<String> submitForVerification(
    String uid, {
    List<UploadedImage> documents = const [],
    UploadedImage? businessPermit,
    UploadedImage? ownershipDocument,
    String? diditSessionId,
    String idSource = 'upload',
  });

  /// Documents the owner shares with tenants; empty when the owner isn't
  /// verified or has "Show credentials" off.
  Future<OwnerCredentials> fetchCredentials(String ownerId);

  /// Documents and Didit session previously submitted by [uid].
  Future<SubmittedDocuments> fetchSubmittedDocuments(String uid);

  /// Owner's opt-in to show their business permit and ownership document to
  /// tenants. Turning it on also syncs the shared copies.
  Future<void> setShowCredentials(String uid, bool value);

  /// Copies the permit and ownership document from the owner's private,
  /// admin-reviewed documents to the tenant-readable docs.
  Future<void> syncSharedCredentials(String uid);

  /// Live `verificationStatus` ('none' | 'pending' | 'verified' |
  /// 'rejected'), so the pending screen advances the moment an admin approves.
  Stream<String> watchVerificationStatus(String uid);

  /// Live full `ownerProfiles/{uid}` doc including `rejectionReason`.
  Stream<OwnerProfileDoc?> watchOwnerProfile(String uid);

  /// Creates the listing and returns its new document ID.
  Future<String> createProperty(PropertyDoc property);

  /// All listings owned by [ownerId]; used to build the saved-property
  /// picker and to reject duplicate room names within a property.
  Future<List<PropertyDoc>> fetchOwnerProperties(String ownerId);
}

