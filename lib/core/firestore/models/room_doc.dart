import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_parse.dart';

/// `properties/{propertyId}/rooms/{roomId}` — individual rooms in a property.
class RoomDoc {
  const RoomDoc({
    required this.roomId,
    required this.propertyId,
    required this.label,
    required this.maxOccupants,
    required this.monthlyRent,
    required this.isAvailable,
    this.photos,
    this.notes,
  });

  /// Document ID.
  final String roomId;

  /// References properties (parent document).
  final String propertyId;
  final String label;
  final num maxOccupants;
  final num monthlyRent;
  final bool isAvailable;
  final List<String>? photos;
  final String? notes;

  factory RoomDoc.fromMap(String id, Map<String, dynamic> map) => RoomDoc(
        roomId: id,
        propertyId: map['propertyId'] as String? ?? '',
        label: map['label'] as String? ?? '',
        maxOccupants: parseNum(map['maxOccupants'], 1),
        monthlyRent: parseNum(map['monthlyRent'], 0),
        isAvailable: parseBool(map['isAvailable'], false),
        photos: parseStringListOrNull(map['photos']),
        notes: map['notes'] as String?,
      );

  factory RoomDoc.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RoomDoc.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toMap() => {
        'propertyId': propertyId,
        'label': label,
        'maxOccupants': maxOccupants,
        'monthlyRent': monthlyRent,
        'isAvailable': isAvailable,
        if (photos != null) 'photos': photos,
        if (notes != null) 'notes': notes,
      };
}
