import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_parse.dart';

/// `ownerProfiles/{userId}` — owner verification. Document ID references
/// `users/{userId}`.
///
/// No TOPSIS weight fields here — owner-side tenant discovery is
/// filtering-only, there is no owner-side TOPSIS instance (CLAUDE.md).
///
/// Verification document links are NOT here (this doc is world-readable); they
/// live in `ownerProfiles/{uid}/private/documents`.
class OwnerProfileDoc {
  const OwnerProfileDoc({
    required this.userId,
    required this.verificationStatus,
    this.submittedAt,
    this.verifiedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.avgRating,
    this.totalRatings,
    this.ratingSum,
    this.propertyCount,
    this.updatedAt,
  });

  /// Document ID, references users.
  final String userId;

  /// 'verified' | 'pending' | 'none' | 'rejected' — admin-controlled only.
  final String verificationStatus;
  final Timestamp? submittedAt;
  final Timestamp? verifiedAt;
  final Timestamp? rejectedAt;
  final String? rejectionReason;

  // Computed server-side.
  final num? avgRating;
  final num? totalRatings;
  final num? ratingSum;

  double? get effectiveAvgRating {
    if (ratingSum != null && totalRatings != null && totalRatings! > 0) {
      return (ratingSum! / totalRatings!).toDouble();
    }
    return avgRating?.toDouble();
  }
  final num? propertyCount;
  final Timestamp? updatedAt;

  factory OwnerProfileDoc.fromMap(String id, Map<String, dynamic> map) =>
      OwnerProfileDoc(
        userId: id,
        verificationStatus: map['verificationStatus'] as String? ?? 'none',
        submittedAt: parseTimestamp(map['submittedAt']),
        verifiedAt: parseTimestamp(map['verifiedAt']),
        rejectedAt: parseTimestamp(map['rejectedAt']),
        rejectionReason: map['rejectionReason'] as String?,
        avgRating: parseNumOrNull(map['avgRating']),
        totalRatings: parseNumOrNull(map['totalRatings']),
        ratingSum: parseNumOrNull(map['ratingSum']),
        propertyCount: parseNumOrNull(map['propertyCount']),
        updatedAt: parseTimestamp(map['updatedAt']),
      );

  factory OwnerProfileDoc.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => OwnerProfileDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
    'verificationStatus': verificationStatus,
    if (submittedAt != null) 'submittedAt': submittedAt,
    if (verifiedAt != null) 'verifiedAt': verifiedAt,
    if (rejectedAt != null) 'rejectedAt': rejectedAt,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (avgRating != null) 'avgRating': avgRating,
    if (totalRatings != null) 'totalRatings': totalRatings,
    if (ratingSum != null) 'ratingSum': ratingSum,
    if (propertyCount != null) 'propertyCount': propertyCount,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
