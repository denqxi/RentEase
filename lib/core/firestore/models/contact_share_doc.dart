import 'package:cloud_firestore/cloud_firestore.dart';

/// `inquiries/{inquiryId}/contact/{tenant|owner}` — one participant's phone,
/// shared with the other party only after the inquiry is accepted. The email
/// is never shared.
class ContactShareDoc {
  const ContactShareDoc({required this.phone, this.sharedAt});

  final String phone;
  final Timestamp? sharedAt;

  factory ContactShareDoc.fromMap(Map<String, dynamic> map) => ContactShareDoc(
        phone: map['phone'] as String? ?? '',
        sharedAt: map['sharedAt'] as Timestamp?,
      );

  factory ContactShareDoc.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => ContactShareDoc.fromMap(doc.data() ?? const {});

  /// Exactly the fields firestore.rules allow: {phone, sharedAt}.
  Map<String, dynamic> toMap() => {
        'phone': phone,
        'sharedAt': FieldValue.serverTimestamp(),
      };
}
