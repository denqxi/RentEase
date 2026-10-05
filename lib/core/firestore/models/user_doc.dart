import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{userId}` — account info for tenants, owners, and admins.
class UserDoc {
  const UserDoc({
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.email = '',
    required this.gender,
    this.phone = '',
    required this.role,
    required this.status,
    this.profilePhoto,
    this.fcmToken,
    this.lastLoginAt,
    this.createdAt,
    this.ageConfirmedAt,
    this.confirmAgeNow = false,
    this.hasLegacyContact = false,
  });

  /// Document ID.
  final String userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String gender;

  /// Contact details are PRIVATE: they live in `users/{uid}/private/contact`
  /// (see [UserContactDoc]) and are never written to the public users doc.
  /// These two stay empty unless a caller merges the private contact in via
  /// [withContact] (admin views, own profile) or the doc is a pre-migration
  /// legacy one that still holds them.
  final String email;
  final String phone;

  /// 'tenant' | 'owner' | 'admin' — permanent after signup.
  final String role;

  /// Account verification status, e.g. 'active' | 'pending' | 'suspended'.
  final String status;
  final String? profilePhoto;
  final String? fcmToken;
  final Timestamp? lastLoginAt;
  final Timestamp? createdAt;

  /// When the user confirmed they are at least 18 (server time, set once at
  /// sign-up; absent on accounts created before the confirmation existed).
  final Timestamp? ageConfirmedAt;

  /// Create-time flag: [toMap] stamps `ageConfirmedAt` with the server time.
  /// Never read back from Firestore.
  final bool confirmAgeNow;

  /// True when the stored users doc still carries `phone` / `email` keys
  /// (written before contact moved to the private doc). Drives the
  /// best-effort self-migration at sign-in. Never serialised.
  final bool hasLegacyContact;

  UserDoc withContact({String? email, String? phone}) => UserDoc(
        userId: userId,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email ?? this.email,
        gender: gender,
        phone: phone ?? this.phone,
        role: role,
        status: status,
        profilePhoto: profilePhoto,
        fcmToken: fcmToken,
        lastLoginAt: lastLoginAt,
        createdAt: createdAt,
        ageConfirmedAt: ageConfirmedAt,
        confirmAgeNow: confirmAgeNow,
        hasLegacyContact: hasLegacyContact,
      );

  factory UserDoc.fromMap(String id, Map<String, dynamic> map) => UserDoc(
        userId: id,
        firstName: map['firstName'] as String? ?? '',
        middleName: map['middleName'] as String?,
        lastName: map['lastName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        gender: map['gender'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        role: map['role'] as String? ?? '',
        status: map['status'] as String? ?? '',
        profilePhoto: map['profilePhoto'] as String?,
        fcmToken: map['fcmToken'] as String?,
        lastLoginAt: map['lastLoginAt'] as Timestamp?,
        createdAt: map['createdAt'] as Timestamp?,
        ageConfirmedAt: map['ageConfirmedAt'] as Timestamp?,
        hasLegacyContact: map.containsKey('phone') || map.containsKey('email'),
      );

  factory UserDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        if (middleName != null) 'middleName': middleName,
        'lastName': lastName,
        'gender': gender,
        'role': role,
        'status': status,
        if (profilePhoto != null) 'profilePhoto': profilePhoto,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'lastLoginAt': lastLoginAt ?? FieldValue.serverTimestamp(),
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        // firestore.rules require this to equal request.time when present.
        if (confirmAgeNow) 'ageConfirmedAt': FieldValue.serverTimestamp(),
      };
}
