import 'package:cloud_firestore/cloud_firestore.dart';

/// `inquiries/{inquiryId}` — structured two-phase inquiries between
/// compatible (bScore = 1) tenants and owners.
class InquiryDoc {
  const InquiryDoc({
    required this.inquiryId,
    required this.matchId,
    required this.tenantId,
    required this.ownerId,
    required this.propertyId,
    required this.tenantCiSnapshot,
    required this.stage,
    required this.initiatedBy,
    required this.status,
    required this.ownerDecision,
    this.declineReason,
    required this.autoInfoSent,
    this.createdAt,
    this.updatedAt,
  });

  /// Document ID.
  final String inquiryId;

  /// References matches.
  final String matchId;
  final String tenantId;
  final String ownerId;
  final String propertyId;

  /// Tenant Ci at inquiry time (snapshot, not live).
  final num tenantCiSnapshot;

  /// 1 = auto info exchange (chat locked), 2 = open chat.
  final num stage;

  /// 'tenant' | 'owner'.
  final String initiatedBy;

  /// e.g. 'pending' | 'active' | 'booked' | 'declined' | 'closed'.
  final String status;

  /// 'pending' | 'accepted' | 'declined'.
  final String ownerDecision;
  final String? declineReason;
  final bool autoInfoSent;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  factory InquiryDoc.fromMap(String id, Map<String, dynamic> map) =>
      InquiryDoc(
        inquiryId: id,
        matchId: map['matchId'] as String? ?? '',
        tenantId: map['tenantId'] as String? ?? '',
        ownerId: map['ownerId'] as String? ?? '',
        propertyId: map['propertyId'] as String? ?? '',
        tenantCiSnapshot: map['tenantCiSnapshot'] as num? ?? 0,
        stage: map['stage'] as num? ?? 1,
        initiatedBy: map['initiatedBy'] as String? ?? '',
        status: map['status'] as String? ?? 'pending',
        ownerDecision: map['ownerDecision'] as String? ?? 'pending',
        declineReason: map['declineReason'] as String?,
        autoInfoSent: map['autoInfoSent'] as bool? ?? false,
        createdAt: map['createdAt'] as Timestamp?,
        updatedAt: map['updatedAt'] as Timestamp?,
      );

  factory InquiryDoc.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      InquiryDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'tenantId': tenantId,
        'ownerId': ownerId,
        'propertyId': propertyId,
        'tenantCiSnapshot': tenantCiSnapshot,
        'stage': stage,
        'initiatedBy': initiatedBy,
        'status': status,
        'ownerDecision': ownerDecision,
        if (declineReason != null) 'declineReason': declineReason,
        'autoInfoSent': autoInfoSent,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
