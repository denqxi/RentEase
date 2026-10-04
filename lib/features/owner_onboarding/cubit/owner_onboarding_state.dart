part of 'owner_onboarding_cubit.dart';

enum OwnerOnboardingStatus { editing, saving, saved, failure }

/// Draft of the owner's first listing, built up across the "Add property"
/// wizard. Nothing is written to `properties` until
/// [OwnerOnboardingCubit.submitProperty].
class OwnerOnboardingState extends Equatable {
  const OwnerOnboardingState({
    this.status = OwnerOnboardingStatus.editing,
    this.errorMessage,
    this.verificationStatus,
    this.createdPropertyId,
    // Step 1 — basics.
    this.title = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.photos = const <UploadedImage>[],
    // Step 2 — house rules (Layer 1 property-side constraints).
    this.depositAmount = 0,
    this.advanceMonths = 1,
    this.allowedGender = 'Mixed / Any',
    this.smokingAllowed = false,
    this.petsAllowed = false,
    this.curfewHours = 22,
    this.maxOccupants = 1,
    // Step 3 — pricing and amenities (final step; there is no owner-side
    // TOPSIS, so no weight step).
    this.monthlyRent = 0,
    this.amenities = const <String>[],
  });

  final OwnerOnboardingStatus status;
  final String? errorMessage;

  /// Result of the last [OwnerOnboardingCubit.submitForVerification].
  final String? verificationStatus;
  final String? createdPropertyId;

  final String title;
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
  final int curfewHours;
  final int maxOccupants;

  final int monthlyRent;
  final List<String> amenities;

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
    String? title,
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
    int? maxOccupants,
    int? monthlyRent,
    List<String>? amenities,
  }) {
    return OwnerOnboardingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdPropertyId: createdPropertyId ?? this.createdPropertyId,
      title: title ?? this.title,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photos: photos ?? this.photos,
      depositAmount: depositAmount ?? this.depositAmount,
      advanceMonths: advanceMonths ?? this.advanceMonths,
      allowedGender: allowedGender ?? this.allowedGender,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      petsAllowed: petsAllowed ?? this.petsAllowed,
      curfewHours: curfewHours ?? this.curfewHours,
      maxOccupants: maxOccupants ?? this.maxOccupants,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      amenities: amenities ?? this.amenities,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    errorMessage,
    verificationStatus,
    createdPropertyId,
    title,
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
    amenities,
  ];
}
