import 'package:cloud_firestore/cloud_firestore.dart';

/// `reports/{reportId}` — user reports against users or listings.
class ReportDoc {
  const ReportDoc({
    required this.reportId,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.status,
    this.createdAt,
  });

  /// Document ID.
  final String reportId;

  /// References users.
  final String reporterId;
  final String targetId;

  /// 'user' | 'property'.
  final String targetType;
  final String reason;

  /// e.g. 'open' | 'reviewed' | 'resolved' | 'dismissed'.
  final String status;
  final Timestamp? createdAt;

  factory ReportDoc.fromMap(String id, Map<String, dynamic> map) => ReportDoc(
        reportId: id,
        reporterId: map['reporterId'] as String? ?? '',
        targetId: map['targetId'] as String? ?? '',
        targetType: map['targetType'] as String? ?? '',
        reason: map['reason'] as String? ?? '',
        status: map['status'] as String? ?? 'open',
        createdAt: map['createdAt'] as Timestamp?,
      );

  factory ReportDoc.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      ReportDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'status': status,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
