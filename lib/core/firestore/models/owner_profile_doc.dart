import 'package:cloud_firestore/cloud_firestore.dart';

/// `ownerProfiles/{userId}` — owner verification and TOPSIS weights.
/// Document ID references `users/{userId}`.
class OwnerProfileDoc {
  const OwnerProfileDoc({
    required this.userId,
    required this.verificationStatus,
    required this.documentUrls,
    this.submittedAt,
    this.verifiedAt,
    this.rejectedAt,
    this.rejectionReason,
    required this.wStayDuration,
    required this.wCredibility,
    required this.wCompleteness,
    this.avgRating,
    this.totalRatings,
    this.propertyCount,
    this.updatedAt,
  });

  /// Document ID, references users.
  final String userId;

  /// 'verified' | 'pending' | 'none' | 'rejected' — admin-controlled only.
  final String verificationStatus;
  final List<String> documentUrls;
  final Timestamp? submittedAt;
  final Timestamp? verifiedAt;
  final Timestamp? rejectedAt;
  final String? rejectionReason;

  /// TOPSIS weights — wStayDuration + wCredibility + wCompleteness = 1.0.
  final num wStayDuration;
  final num wCredibility;
  final num wCompleteness;

  // Computed server-side.
  final num? avgRating;
  final num? totalRatings;
  final num? propertyCount;
  final Timestamp? updatedAt;

  factory OwnerProfileDoc.fromMap(String id, Map<String, dynamic> map) =>
      OwnerProfileDoc(
        userId: id,
        verificationStatus: map['verificationStatus'] as String? ?? 'none',
        documentUrls: (map['documentUrls'] as List?)?.cast<String>() ?? const [],
        submittedAt: map['submittedAt'] as Timestamp?,
        verifiedAt: map['verifiedAt'] as Timestamp?,
        rejectedAt: map['rejectedAt'] as Timestamp?,
        rejectionReason: map['rejectionReason'] as String?,
        wStayDuration: map['wStayDuration'] as num? ?? 0.4,
        wCredibility: map['wCredibility'] as num? ?? 0.35,
        wCompleteness: map['wCompleteness'] as num? ?? 0.25,
        avgRating: map['avgRating'] as num?,
        totalRatings: map['totalRatings'] as num?,
        propertyCount: map['propertyCount'] as num?,
        updatedAt: map['updatedAt'] as Timestamp?,
      );

  factory OwnerProfileDoc.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      OwnerProfileDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'verificationStatus': verificationStatus,
        'documentUrls': documentUrls,
        if (submittedAt != null) 'submittedAt': submittedAt,
        if (verifiedAt != null) 'verifiedAt': verifiedAt,
        if (rejectedAt != null) 'rejectedAt': rejectedAt,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'wStayDuration': wStayDuration,
        'wCredibility': wCredibility,
        'wCompleteness': wCompleteness,
        if (avgRating != null) 'avgRating': avgRating,
        if (totalRatings != null) 'totalRatings': totalRatings,
        if (propertyCount != null) 'propertyCount': propertyCount,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
