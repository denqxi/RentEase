import '../../../../core/firestore/models/models.dart';

/// The owner's own listings — "My properties" and Edit property. Writes are
/// guarded by firestore.rules (own listing, amenityScore == amenityList length;
/// only a verified owner may publish).
const String adminUnlistedMessage =
    'Unlisted by admin - contact support to relist';

/// Owner-presentable text for a failed listing write. [code] is the
/// Firestore error code; [fields] is what was being written (a denied
/// `isAvailable: true` means the admin has unlisted the property).
String ownerPropertyErrorMessage(String code, Map<String, dynamic> fields) {
  switch (code) {
    case 'permission-denied':
      return fields['isAvailable'] == true
          ? adminUnlistedMessage
          : "You can't edit this listing. You can only edit your own "
                'properties.';
    case 'unavailable':
    case 'deadline-exceeded':
    case 'network-request-failed':
      return 'No connection. Check your internet and try again.';
    default:
      return 'Could not save the listing. Please try again.';
  }
}

abstract class OwnerPropertyRepository {
  /// The owner's properties, newest first, live.
  Stream<List<PropertyDoc>> watchOwnerProperties(String ownerId);

  /// Live `ownerProfiles/{uid}.verificationStatus` ('none' when absent).
  Stream<String> watchVerificationStatus(String ownerId);

  /// The owner's own `users/{uid}` account doc (name, photo); null if absent.
  Future<UserDoc?> fetchUser(String uid);

  /// Syncs the "Verified" badge flag (`isVerified = true`) onto listings.
  /// Listings are live regardless; rules only allow this flag for a verified
  /// owner (or admin).
  Future<void> publishListings(Iterable<String> propertyIds);

  /// How many inquiries on the owner's listings are still open.
  Stream<int> watchOpenInquiryCount(String ownerId);

  /// Partial update of one listing (plus updatedAt).
  Future<void> updateProperty(String propertyId, Map<String, dynamic> fields);
}
