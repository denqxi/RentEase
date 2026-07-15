/// Firestore collection paths — single source of truth, matching the
/// RentEase Data Dictionary (RENTEASE_FIREBASE.MD).
///
/// Top-level collections: users, tenantProfiles, ownerProfiles, properties,
/// matches, inquiries, ratings, notifications, adminLogs, reports.
/// Subcollections: properties/{id}/rooms, inquiries/{id}/messages.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String tenantProfiles = 'tenantProfiles';
  static const String ownerProfiles = 'ownerProfiles';
  static const String properties = 'properties';
  static const String matches = 'matches';
  static const String inquiries = 'inquiries';
  static const String ratings = 'ratings';
  static const String notifications = 'notifications';
  static const String adminLogs = 'adminLogs';
  static const String reports = 'reports';

  /// Subcollection of properties: properties/{propertyId}/rooms/{roomId}
  static const String rooms = 'rooms';

  /// Subcollection of inquiries: inquiries/{inquiryId}/messages/{messageId}
  static const String messages = 'messages';
}
