import 'package:cloud_firestore/cloud_firestore.dart';

/// `adminLogs/{logId}` — audit trail of administrator actions.
class AdminLogDoc {
  const AdminLogDoc({
    required this.logId,
    required this.adminId,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.reason,
    this.createdAt,
  });

  /// Document ID.
  final String logId;

  /// References users.
  final String adminId;

  /// e.g. 'approve_owner' | 'reject_owner' | 'suspend_user'.
  final String action;
  final String targetId;
  final String targetType;
  final String reason;
  final Timestamp? createdAt;

  factory AdminLogDoc.fromMap(String id, Map<String, dynamic> map) =>
      AdminLogDoc(
        logId: id,
        adminId: map['adminId'] as String? ?? '',
        action: map['action'] as String? ?? '',
        targetId: map['targetId'] as String? ?? '',
        targetType: map['targetType'] as String? ?? '',
        reason: map['reason'] as String? ?? '',
        createdAt: map['createdAt'] as Timestamp?,
      );

  factory AdminLogDoc.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      AdminLogDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'adminId': adminId,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
