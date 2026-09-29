import 'package:cloud_firestore/cloud_firestore.dart';

/// `ownerProfiles/{userId}` — owner verification. Document ID references
/// `users/{userId}`.
///
/// No TOPSIS weight fields here — owner-side tenant discovery is
/// filtering-only, there is no owner-side TOPSIS instance (CLAUDE.md).
class OwnerProfileDoc {
  const OwnerProfileDoc({
    required this.userId,
    required this.verificationStatus,
    required this.documentUrls,
    this.submittedAt,
    this.verifiedAt,
    this.rejectedAt,
    this.rejectionReason,
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

  // Computed server-side.
  final num? avgRating;
  final num? totalRatings;
  final num? propertyCount;
  final Timestamp? updatedAt;

  factory OwnerProfileDoc.fromMap(String id, Map<String, dynamic> map) =>
      OwnerProfileDoc(
        userId: id,
        verificationStatus: map['verificationStatus'] as String? ?? 'none',
        documentUrls:
            (map['documentUrls'] as List?)?.cast<String>() ?? const [],
        submittedAt: map['submittedAt'] as Timestamp?,
        verifiedAt: map['verifiedAt'] as Timestamp?,
        rejectedAt: map['rejectedAt'] as Timestamp?,
        rejectionReason: map['rejectionReason'] as String?,
        avgRating: map['avgRating'] as num?,
        totalRatings: map['totalRatings'] as num?,
        propertyCount: map['propertyCount'] as num?,
        updatedAt: map['updatedAt'] as Timestamp?,
      );

  factory OwnerProfileDoc.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => OwnerProfileDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
    'verificationStatus': verificationStatus,
    'documentUrls': documentUrls,
    if (submittedAt != null) 'submittedAt': submittedAt,
    if (verifiedAt != null) 'verifiedAt': verifiedAt,
    if (rejectedAt != null) 'rejectedAt': rejectedAt,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (avgRating != null) 'avgRating': avgRating,
    if (totalRatings != null) 'totalRatings': totalRatings,
    if (propertyCount != null) 'propertyCount': propertyCount,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
