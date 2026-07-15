import 'package:cloud_firestore/cloud_firestore.dart';

/// `properties/{propertyId}` — boarding house listings by verified owners.
class PropertyDoc {
  const PropertyDoc({
    required this.propertyId,
    required this.ownerId,
    required this.title,
    this.description,
    required this.address,
    required this.location,
    required this.geoHash,
    required this.photos,
    required this.monthlyRent,
    required this.depositAmount,
    required this.advanceMonths,
    required this.isAvailable,
    required this.vacancyStatus,
    required this.isVerified,
    this.createdAt,
    this.updatedAt,
    required this.allowedGender,
    required this.smokingAllowed,
    required this.petsAllowed,
    required this.maxOccupants,
    required this.minStayMonths,
    this.curfewHours,
    required this.hasWifi,
    required this.bathroomType,
    required this.amenityList,
    this.amenityScore,
  });

  /// Document ID.
  final String propertyId;

  /// References users.
  final String ownerId;
  final String title;
  final String? description;
  final String address;

  /// GeoPoint — pinned coordinates used for Haversine distance.
  final GeoPoint location;
  final String geoHash;
  final List<String> photos;
  final num monthlyRent;
  final num depositAmount;
  final num advanceMonths;
  /// Convenience flag: vacancyStatus == 'available'.
  final bool isAvailable;

  /// 'available' | 'pending' | 'booked' — owner-controlled 3-state status.
  final String vacancyStatus;
  final bool isVerified;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  // Layer 1 property-side constraints (owner rules).
  final String allowedGender;
  final bool smokingAllowed;
  final bool petsAllowed;
  final num maxOccupants;
  final num minStayMonths;
  final num? curfewHours;

  // Layer 2 tenant-side attributes.
  final bool hasWifi;
  final String bathroomType;

  /// Fixed 14-item checklist selections.
  final List<String> amenityList;

  /// Computed: amenityList.length (0–14).
  final num? amenityScore;

  factory PropertyDoc.fromMap(String id, Map<String, dynamic> map) =>
      PropertyDoc(
        propertyId: id,
        ownerId: map['ownerId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String?,
        address: map['address'] as String? ?? '',
        location: map['location'] as GeoPoint? ?? const GeoPoint(0, 0),
        geoHash: map['geoHash'] as String? ?? '',
        photos: (map['photos'] as List?)?.cast<String>() ?? const [],
        monthlyRent: map['monthlyRent'] as num? ?? 0,
        depositAmount: map['depositAmount'] as num? ?? 0,
        advanceMonths: map['advanceMonths'] as num? ?? 0,
        isAvailable: map['isAvailable'] as bool? ?? false,
        vacancyStatus: map['vacancyStatus'] as String? ?? 'available',
        isVerified: map['isVerified'] as bool? ?? false,
        createdAt: map['createdAt'] as Timestamp?,
        updatedAt: map['updatedAt'] as Timestamp?,
        allowedGender: map['allowedGender'] as String? ?? '',
        smokingAllowed: map['smokingAllowed'] as bool? ?? false,
        petsAllowed: map['petsAllowed'] as bool? ?? false,
        maxOccupants: map['maxOccupants'] as num? ?? 1,
        minStayMonths: map['minStayMonths'] as num? ?? 0,
        curfewHours: map['curfewHours'] as num?,
        hasWifi: map['hasWifi'] as bool? ?? false,
        bathroomType: map['bathroomType'] as String? ?? '',
        amenityList: (map['amenityList'] as List?)?.cast<String>() ?? const [],
        amenityScore: map['amenityScore'] as num?,
      );

  factory PropertyDoc.fromSnapshot(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      PropertyDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title,
        if (description != null) 'description': description,
        'address': address,
        'location': location,
        'geoHash': geoHash,
        'photos': photos,
        'monthlyRent': monthlyRent,
        'depositAmount': depositAmount,
        'advanceMonths': advanceMonths,
        'isAvailable': isAvailable,
        'vacancyStatus': vacancyStatus,
        'isVerified': isVerified,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'allowedGender': allowedGender,
        'smokingAllowed': smokingAllowed,
        'petsAllowed': petsAllowed,
        'maxOccupants': maxOccupants,
        'minStayMonths': minStayMonths,
        if (curfewHours != null) 'curfewHours': curfewHours,
        'hasWifi': hasWifi,
        'bathroomType': bathroomType,
        'amenityList': amenityList,
        'amenityScore': amenityScore ?? amenityList.length,
      };
}
