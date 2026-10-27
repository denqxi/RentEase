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
    this.photoPublicIds = const [],
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
    this.curfewHours,
    required this.hasWifi,
    required this.amenityList,
    this.amenityScore,
    this.adminUnlisted = false,
    this.rentalType = 'entire_place',
    this.propertyName,
    this.roomName,
    this.propertyType,
    this.parentPropertyId,
    this.propertyCoverPhoto,
    this.propertyCoverPublicId,
    this.avgRating,
    this.totalRatings,
    this.ratingSum,
  });

  /// 'entire_place' (default, also for legacy docs) | 'room'.
  final String rentalType;

  /// Building name for a room listing (e.g. "GL Boardinghouse").
  final String? propertyName;

  /// Room number/name (e.g. "Room 101"); unique per [parentPropertyId].
  final String? roomName;

  /// "Boarding House", "Dormitory", "Apartment", "Condo", or custom string.
  final String? propertyType;

  /// Groups the rooms of one building. Null for entire places/legacy docs.
  final String? parentPropertyId;

  /// Dedicated cover photo URL for the parent building (separate from room photos).
  final String? propertyCoverPhoto;

  /// Cloudinary public_id for [propertyCoverPhoto].
  final String? propertyCoverPublicId;

  /// Average star rating (1.0 to 5.0) aggregated from tenant reviews.
  final num? avgRating;

  /// Total count of tenant reviews submitted for this property.
  final num? totalRatings;
  final num? ratingSum;

  double? get effectiveAvgRating {
    if (ratingSum != null && totalRatings != null && totalRatings! > 0) {
      return (ratingSum! / totalRatings!).toDouble();
    }
    return avgRating?.toDouble();
  }

  PropertyDoc withRatings({
    num? avgRating,
    num? totalRatings,
    num? ratingSum,
  }) =>
      PropertyDoc(
        propertyId: propertyId,
        ownerId: ownerId,
        title: title,
        description: description,
        address: address,
        location: location,
        geoHash: geoHash,
        photos: photos,
        photoPublicIds: photoPublicIds,
        monthlyRent: monthlyRent,
        depositAmount: depositAmount,
        advanceMonths: advanceMonths,
        isAvailable: isAvailable,
        vacancyStatus: vacancyStatus,
        isVerified: isVerified,
        createdAt: createdAt,
        updatedAt: updatedAt,
        allowedGender: allowedGender,
        smokingAllowed: smokingAllowed,
        petsAllowed: petsAllowed,
        maxOccupants: maxOccupants,
        curfewHours: curfewHours,
        hasWifi: hasWifi,
        amenityList: amenityList,
        amenityScore: amenityScore,
        adminUnlisted: adminUnlisted,
        rentalType: rentalType,
        propertyName: propertyName,
        roomName: roomName,
        propertyType: propertyType,
        parentPropertyId: parentPropertyId,
        propertyCoverPhoto: propertyCoverPhoto,
        propertyCoverPublicId: propertyCoverPublicId,
        avgRating: avgRating ?? this.avgRating,
        totalRatings: totalRatings ?? this.totalRatings,
        ratingSum: ratingSum ?? this.ratingSum,
      );

  /// Returns the building cover photo if set, falling back to the first listing photo.
  String? get effectiveBuildingCoverPhoto =>
      (propertyCoverPhoto?.trim().isNotEmpty ?? false)
          ? propertyCoverPhoto!.trim()
          : (photos.isNotEmpty ? photos.first : null);

  bool get isRoom => rentalType == 'room';

  /// Set only by an admin (with isAvailable=false); the owner cannot clear
  /// it or flip isAvailable back to true (firestore.rules).
  final bool adminUnlisted;

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

  /// Cloudinary public_ids, parallel to [photos] (for later delete/replace).
  final List<String> photoPublicIds;
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
  final num? curfewHours;

  // Layer 2 tenant-side attributes.
  final bool hasWifi;

  /// Fixed 14-item checklist selections.
  final List<String> amenityList;

  /// Computed: amenityList.length (0–14).
  final num? amenityScore;

  static GeoPoint _parseLocation(dynamic val) {
    if (val is GeoPoint) return val;
    if (val is Map) {
      final lat = (val['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (val['longitude'] as num?)?.toDouble() ?? 0.0;
      return GeoPoint(lat, lng);
    }
    return const GeoPoint(0, 0);
  }

  static Timestamp? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val;
    if (val is DateTime) return Timestamp.fromDate(val);
    if (val is String) {
      final dt = DateTime.tryParse(val);
      if (dt != null) return Timestamp.fromDate(dt);
    }
    if (val is int) {
      return Timestamp.fromMillisecondsSinceEpoch(val);
    }
    return null;
  }

  static List<String> _parseStringList(dynamic val) {
    if (val is List) {
      return [for (final item in val) if (item != null) item.toString()];
    }
    return const [];
  }

  static num _parseNum(dynamic val, [num fallback = 0]) {
    if (val is num) return val;
    if (val is String) return num.tryParse(val) ?? fallback;
    return fallback;
  }

  static bool _parseBool(dynamic val, [bool fallback = false]) {
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    if (val is num) return val != 0;
    return fallback;
  }

  factory PropertyDoc.fromMap(String id, Map<String, dynamic> map) =>
      PropertyDoc(
        propertyId: id,
        ownerId: map['ownerId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String?,
        address: map['address'] as String? ?? '',
        location: _parseLocation(map['location']),
        geoHash: map['geoHash'] as String? ?? '',
        photos: _parseStringList(map['photos']),
        photoPublicIds: _parseStringList(map['photoPublicIds']),
        monthlyRent: _parseNum(map['monthlyRent'] ?? map['rent'] ?? map['price'] ?? map['pricePerMonth'], 0),
        depositAmount: _parseNum(map['depositAmount'], 0),
        advanceMonths: _parseNum(map['advanceMonths'], 0),
        isAvailable: _parseBool(map['isAvailable'], false),
        vacancyStatus: map['vacancyStatus'] as String? ?? 'available',
        isVerified: _parseBool(map['isVerified'], false),
        createdAt: _parseTimestamp(map['createdAt']),
        updatedAt: _parseTimestamp(map['updatedAt']),
        allowedGender: map['allowedGender'] as String? ?? '',
        smokingAllowed: _parseBool(map['smokingAllowed'], false),
        petsAllowed: _parseBool(map['petsAllowed'], false),
        maxOccupants: _parseNum(map['maxOccupants'], 1),
        curfewHours: map['curfewHours'] != null ? _parseNum(map['curfewHours']) : null,
        hasWifi: _parseBool(map['hasWifi'], false),
        amenityList: _parseStringList(map['amenityList']),
        amenityScore: map['amenityScore'] != null ? _parseNum(map['amenityScore']) : null,
        adminUnlisted: _parseBool(map['adminUnlisted'], false),
        rentalType: map['rentalType'] as String? ?? 'entire_place',
        propertyName: map['propertyName'] as String?,
        roomName: map['roomName'] as String?,
        propertyType: map['propertyType'] as String?,
        parentPropertyId: map['parentPropertyId'] as String?,
        propertyCoverPhoto: map['propertyCoverPhoto'] as String?,
        propertyCoverPublicId: map['propertyCoverPublicId'] as String?,
        avgRating: map['avgRating'] != null ? _parseNum(map['avgRating']) : null,
        totalRatings: map['totalRatings'] != null ? _parseNum(map['totalRatings']) : null,
        ratingSum: map['ratingSum'] != null ? _parseNum(map['ratingSum']) : null,
      );

  factory PropertyDoc.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => PropertyDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'title': title,
    if (description != null) 'description': description,
    'address': address,
    'location': location,
    'geoHash': geoHash,
    'photos': photos,
    'photoPublicIds': photoPublicIds,
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
    if (curfewHours != null) 'curfewHours': curfewHours,
    'hasWifi': hasWifi,
    'amenityList': amenityList,
    'amenityScore': amenityScore ?? amenityList.length,
    if (adminUnlisted) 'adminUnlisted': true,
    'rentalType': rentalType,
    if (propertyName != null) 'propertyName': propertyName,
    if (roomName != null) 'roomName': roomName,
    if (propertyType != null) 'propertyType': propertyType,
    if (parentPropertyId != null) 'parentPropertyId': parentPropertyId,
    if (propertyCoverPhoto != null) 'propertyCoverPhoto': propertyCoverPhoto,
    if (propertyCoverPublicId != null)
      'propertyCoverPublicId': propertyCoverPublicId,
    if (avgRating != null) 'avgRating': avgRating,
    if (totalRatings != null) 'totalRatings': totalRatings,
    if (ratingSum != null) 'ratingSum': ratingSum,
  };
}
