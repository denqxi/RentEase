part of 'owner_onboarding_cubit.dart';

enum OwnerOnboardingStatus { editing, saving, saved, failure }

/// Draft of the owner's listing, built up across the "Create listing"
/// wizard. Nothing is written to `properties` until
/// [OwnerOnboardingCubit.submitProperty].
class OwnerOnboardingState extends Equatable {
  const OwnerOnboardingState({
    this.status = OwnerOnboardingStatus.editing,
    this.errorMessage,
    this.verificationStatus,
    this.createdPropertyId,
    // Step 1 — rental type.
    this.rentalType = 'entire_place',
    // Step 2 — property details.
    this.title = '',
    this.propertyName,
    this.propertyType,
    this.roomName,
    this.parentPropertyId,
    this.address = '',
    this.latitude,
    this.longitude,
    this.photos = const <UploadedImage>[],
    // Step 3 — house rules (Layer 1 property-side constraints).
    this.depositAmount = 0,
    this.advanceMonths = 1,
    this.allowedGender = 'Mixed / Any',
    this.smokingAllowed = false,
    this.petsAllowed = false,
    this.curfewHours = 22,
    // Step 4 — rent & occupants.
    this.maxOccupants = 1,
    this.monthlyRent = 0,
    this.isAvailable = true,
    // Step 5 — amenities.
    this.amenities = const <String>[],
  });

  final OwnerOnboardingStatus status;
  final String? errorMessage;

  /// Result of the last [OwnerOnboardingCubit.submitForVerification].
  final String? verificationStatus;
  final String? createdPropertyId;

  /// 'entire_place' | 'room'.
  final String rentalType;

  /// Listing title. For a room this is generated as
  /// `"$propertyName – $roomName"`.
  final String title;

  /// Building name (rooms) or the place name (entire place).
  final String? propertyName;
  final String? propertyType;
  final String? roomName;

  /// Groups rooms of the same building. Null for an entire place.
  final String? parentPropertyId;
  final String address;
  final double? latitude;
  final double? longitude;

  /// Uploaded listing photos (1–5), first is the cover.
  final List<UploadedImage> photos;

  final int depositAmount;
  final int advanceMonths;
  final String allowedGender;
  final bool smokingAllowed;
  final bool petsAllowed;

  /// 24h hour, or null for "No curfew".
  final int? curfewHours;
  final int maxOccupants;

  final int monthlyRent;
  final bool isAvailable;
  final List<String> amenities;

  bool get isRoom => rentalType == 'room';

  /// The pin is required — LocationMatch needs real coordinates.
  bool get isComplete =>
      title.isNotEmpty &&
      address.isNotEmpty &&
      latitude != null &&
      longitude != null &&
      photos.isNotEmpty &&
      monthlyRent > 0;

  OwnerOnboardingState copyWith({
    OwnerOnboardingStatus? status,
    String? errorMessage,
    String? verificationStatus,
    String? createdPropertyId,
    String? rentalType,
    String? title,
    String? propertyName,
    String? propertyType,
    String? roomName,
    String? parentPropertyId,
    bool clearParentPropertyId = false,
    String? address,
    double? latitude,
    double? longitude,
    List<UploadedImage>? photos,
    int? depositAmount,
    int? advanceMonths,
    String? allowedGender,
    bool? smokingAllowed,
    bool? petsAllowed,
    int? curfewHours,
    bool clearCurfew = false,
    int? maxOccupants,
    int? monthlyRent,
    bool? isAvailable,
    List<String>? amenities,
  }) {
    return OwnerOnboardingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdPropertyId: createdPropertyId ?? this.createdPropertyId,
      rentalType: rentalType ?? this.rentalType,
      title: title ?? this.title,
      propertyName: propertyName ?? this.propertyName,
      propertyType: propertyType ?? this.propertyType,
      roomName: roomName ?? this.roomName,
      parentPropertyId: clearParentPropertyId
          ? null
          : (parentPropertyId ?? this.parentPropertyId),
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photos: photos ?? this.photos,
      depositAmount: depositAmount ?? this.depositAmount,
      advanceMonths: advanceMonths ?? this.advanceMonths,
      allowedGender: allowedGender ?? this.allowedGender,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      curfewHours: clearCurfew ? null : (curfewHours ?? this.curfewHours),
      maxOccupants: maxOccupants ?? this.maxOccupants,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      isAvailable: isAvailable ?? this.isAvailable,
      amenities: amenities ?? this.amenities,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    errorMessage,
    verificationStatus,
    createdPropertyId,
    rentalType,
    title,
    propertyName,
    propertyType,
    roomName,
    parentPropertyId,
    address,
    latitude,
    longitude,
    photos,
    depositAmount,
    advanceMonths,
    allowedGender,
    smokingAllowed,
    petsAllowed,
    curfewHours,
    maxOccupants,
    monthlyRent,
    isAvailable,
    amenities,
  ];
}
