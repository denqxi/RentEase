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
        recipientId: map['recipientId']?.toString() ?? '',
        type: map['type']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        relatedId: map['relatedId']?.toString(),
        relatedType: map['relatedType']?.toString(),
        isRead: _parseBool(map['isRead']),
        createdAt: _parseTimestamp(map['createdAt']),
      );

  static bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value == 1 || value == '1' || value == 'true') return true;
    if (value == 0 || value == '0' || value == 'false') return false;
    return fallback;
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return Timestamp.fromDate(parsed);
    }
    return null;
  }

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
