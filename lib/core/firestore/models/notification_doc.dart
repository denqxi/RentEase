import 'package:cloud_firestore/cloud_firestore.dart';

/// `notifications/{notifId}` — system-generated notifications per user.
class NotificationDoc {
  const NotificationDoc({
    required this.notifId,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.relatedType,
    required this.isRead,
    this.createdAt,
  });

  /// Document ID.
  final String notifId;

  /// References users.
  final String recipientId;

  /// e.g. 'new_match' | 'inquiry' | 'inquiry_accepted' | 'verification'.
  final String type;
  final String title;
  final String body;

  /// ID of the related document (match, inquiry, property...).
  final String? relatedId;
  final String? relatedType;
  final bool isRead;
  final Timestamp? createdAt;

  factory NotificationDoc.fromMap(String id, Map<String, dynamic> map) =>
      NotificationDoc(
        notifId: id,
        recipientId: map['recipientId'] as String? ?? '',
        type: map['type'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        relatedId: map['relatedId'] as String?,
        relatedType: map['relatedType'] as String?,
        isRead: map['isRead'] as bool? ?? false,
        createdAt: map['createdAt'] as Timestamp?,
      );

  factory NotificationDoc.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      NotificationDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        if (relatedId != null) 'relatedId': relatedId,
        if (relatedType != null) 'relatedType': relatedType,
        'isRead': isRead,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
