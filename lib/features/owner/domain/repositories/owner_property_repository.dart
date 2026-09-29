import '../../../../core/firestore/models/models.dart';

/// The owner's own listings — "My properties" and Edit property. Writes are
/// guarded by firestore.rules (verified owner, own listing, amenityScore ==
/// amenityList length).
abstract class OwnerPropertyRepository {
  /// The owner's properties, newest first, live.
  Stream<List<PropertyDoc>> watchOwnerProperties(String ownerId);

  /// How many inquiries on the owner's listings are still open.
  Stream<int> watchOpenInquiryCount(String ownerId);

  /// Partial update of one listing (plus updatedAt).
  Future<void> updateProperty(String propertyId, Map<String, dynamic> fields);
}
