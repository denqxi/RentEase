import 'package:equatable/equatable.dart';

/// The landlord's own property as shown in the property stats card on the home screen.
class LandlordProperty extends Equatable {
  const LandlordProperty({
    required this.id,
    required this.name,
    required this.status,
    required this.matchCount,
    required this.viewCount,
    required this.saveCount,
    required this.imageSeed,
  });

  final String id;
  final String name;

  /// Status label e.g. "Live".
  final String status;

  final int matchCount;
  final int viewCount;
  final int saveCount;

  /// 1–5 — selects the gradient palette for the photo placeholder.
  final int imageSeed;

  static const LandlordProperty sample = LandlordProperty(
    id: '1',
    name: 'Test',
    status: 'Live',
    matchCount: 5,
    viewCount: 124,
    saveCount: 18,
    imageSeed: 1,
  );

  @override
  List<Object?> get props =>
      <Object?>[id, name, status, matchCount, viewCount, saveCount, imageSeed];
}
