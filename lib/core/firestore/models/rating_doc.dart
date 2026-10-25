import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_parse.dart';

/// `ratings/{ratingId}` — post-booking feedback between tenants and owners.
class RatingDoc {
  const RatingDoc({
    required this.ratingId,
    required this.inquiryId,
    required this.raterId,
    required this.ratedId,
    required this.raterRole,
    required this.stars,
    this.review,
    this.createdAt,
    this.propertyId,
    this.parentPropertyId,
  });

  /// Document ID.
  final String ratingId;

  /// References inquiries.
  final String inquiryId;
  final String raterId;
  final String ratedId;

  /// 'tenant' | 'owner'.
  final String raterRole;

  /// 1–5.
  final num stars;
  final String? review;
  final Timestamp? createdAt;

  /// References property/room that was rented.
  final String? propertyId;

  /// References parent building if this was a room rental.
  final String? parentPropertyId;

  factory RatingDoc.fromMap(String id, Map<String, dynamic> map) => RatingDoc(
        ratingId: id,
        inquiryId: map['inquiryId'] as String? ?? '',
        raterId: map['raterId'] as String? ?? '',
        ratedId: map['ratedId'] as String? ?? '',
        raterRole: map['raterRole'] as String? ?? '',
        stars: parseNum(map['stars'], 0),
        review: map['review'] as String?,
        createdAt: parseTimestamp(map['createdAt']),
        propertyId: map['propertyId'] as String?,
        parentPropertyId: map['parentPropertyId'] as String?,
      );

  factory RatingDoc.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      RatingDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'inquiryId': inquiryId,
        'raterId': raterId,
        'ratedId': ratedId,
        'raterRole': raterRole,
        'stars': stars,
        if (review != null) 'review': review,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        if (propertyId != null) 'propertyId': propertyId,
        if (parentPropertyId != null) 'parentPropertyId': parentPropertyId,
      };
}
