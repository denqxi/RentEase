import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{userId}` — account info for tenants, owners, and admins.
class UserDoc {
  const UserDoc({
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.phone,
    required this.role,
    required this.status,
    this.profilePhoto,
    this.fcmToken,
    this.lastLoginAt,
    this.createdAt,
  });

  /// Document ID.
  final String userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String gender;

  final String phone;

  /// 'tenant' | 'owner' | 'admin' — permanent after signup.
  final String role;

  /// Account verification status, e.g. 'active' | 'pending' | 'suspended'.
  final String status;
  final String? profilePhoto;
  final String? fcmToken;
  final Timestamp? lastLoginAt;
  final Timestamp? createdAt;

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
      );

  factory UserDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        if (middleName != null) 'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'gender': gender,
        'phone': phone,
        'role': role,
        'status': status,
        if (profilePhoto != null) 'profilePhoto': profilePhoto,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'lastLoginAt': lastLoginAt ?? FieldValue.serverTimestamp(),
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
