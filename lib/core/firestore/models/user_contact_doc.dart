import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}/private/contact` — a user's email and phone. Readable and
/// writable only by that user and admins; never part of the public users doc.
class UserContactDoc {
  const UserContactDoc({
    this.phone = '',
    this.email = '',
    this.emergencyContact,
    this.updatedAt,
  });

  final String phone;
  final String email;

  /// Tenant's emergency contact. Private to the tenant (and admin); never
  /// shown to owners or included in the inquiry contact share.
  final String? emergencyContact;
  final Timestamp? updatedAt;

  factory UserContactDoc.fromMap(Map<String, dynamic> map) => UserContactDoc(
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        emergencyContact: map['emergencyContact'] as String?,
        updatedAt: map['updatedAt'] as Timestamp?,
      );

  factory UserContactDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserContactDoc.fromMap(doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'email': email,
        if (emergencyContact != null) 'emergencyContact': emergencyContact,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
