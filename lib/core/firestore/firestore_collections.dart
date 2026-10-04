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

  /// Private subcollection of ownerProfiles:
  /// ownerProfiles/{uid}/private/documents (verification document links;
  /// readable only by the owner and admins).
  static const String ownerPrivate = 'private';
  static const String ownerPrivateDocuments = 'documents';

  /// Subcollection of inquiries: inquiries/{inquiryId}/messages/{messageId}
  static const String messages = 'messages';

  /// Private subcollection of users: users/{uid}/private/contact (email +
  /// phone; readable only by that user and admins). The public users/{uid}
  /// doc never holds contact details.
  static const String userPrivate = 'private';
  static const String userContact = 'contact';

  /// Subcollection of inquiries: inquiries/{inquiryId}/contact/{role} where
  /// role is 'tenant' or 'owner' — that participant's phone, shared only
  /// after the inquiry is accepted. Each doc is writable only by its own
  /// participant.
  static const String inquiryContact = 'contact';

  /// Private subcollection of tenantProfiles: tenantProfiles/{uid}/private/
  /// prefs (map pin + TOPSIS weights; readable only by that tenant and
  /// admins, hidden from owners).
  static const String tenantPrivate = 'private';
  static const String tenantPrefs = 'prefs';
}
