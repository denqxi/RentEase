import 'package:cloud_firestore/cloud_firestore.dart';

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
        maxOccupants: map['maxOccupants'] as num? ?? 1,
        monthlyRent: map['monthlyRent'] as num? ?? 0,
        isAvailable: map['isAvailable'] as bool? ?? false,
        photos: (map['photos'] as List?)?.cast<String>(),
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
