part of 'tenant_onboarding_cubit.dart';

enum TenantOnboardingStatus { editing, saving, saved, failure }

/// Draft of the tenant profile built up across the five onboarding screens.
/// Nothing is written to Firestore until [TenantOnboardingCubit.submit].
class TenantOnboardingState extends Equatable {
  const TenantOnboardingState({
    this.status = TenantOnboardingStatus.editing,
    this.errorMessage,
    // Step 1 — hard constraints.
    this.maxBudget,
    this.requiredGender,
    this.needsWifi = true,
    // About the tenant — read by the owner-side Layer 1 rules.
    this.isSmoker = false,
    this.hasPet = false,
    this.groupSize = 1,
    // Step 2 — soft preferences.
    this.roomType = 'Either',
    this.preferredAmenities = const <String>[],
    // Step 3 — POI.
    this.poiType = 'School',
    this.poiLatLng,
    this.poiLabel,
    // Step 4 — distance.
    this.maxDistanceKm = 3.0,
    // Step 5 — TOPSIS weights (paper defaults, CLAUDE.md).
    this.wRent = 0.35,
    this.wDistance = 0.35,
    this.wAmenities = 0.30,
  });

  final TenantOnboardingStatus status;
  final String? errorMessage;

  final num? maxBudget;
  final String? requiredGender;
  final bool needsWifi;

  final bool isSmoker;
  final bool hasPet;
  final int groupSize;

  final String roomType;
  final List<String> preferredAmenities;

  final String poiType;
  final GeoPoint? poiLatLng;
  final String? poiLabel;

  final double maxDistanceKm;

  final double wRent;
  final double wDistance;
  final double wAmenities;

  /// Steps 1 and 3 are the only ones whose inputs have no usable default.
  bool get isComplete =>
      maxBudget != null && requiredGender != null && poiLatLng != null;

  TenantOnboardingState copyWith({
    TenantOnboardingStatus? status,
    String? errorMessage,
    num? maxBudget,
    String? requiredGender,
    bool? needsWifi,
    bool? isSmoker,
    bool? hasPet,
    int? groupSize,
    String? roomType,
    List<String>? preferredAmenities,
    String? poiType,
    GeoPoint? poiLatLng,
    String? poiLabel,
    double? maxDistanceKm,
    double? wRent,
    double? wDistance,
    double? wAmenities,
  }) {
    return TenantOnboardingState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      maxBudget: maxBudget ?? this.maxBudget,
      requiredGender: requiredGender ?? this.requiredGender,
      needsWifi: needsWifi ?? this.needsWifi,
      isSmoker: isSmoker ?? this.isSmoker,
      hasPet: hasPet ?? this.hasPet,
      groupSize: groupSize ?? this.groupSize,
      roomType: roomType ?? this.roomType,
      preferredAmenities: preferredAmenities ?? this.preferredAmenities,
      poiType: poiType ?? this.poiType,
      poiLatLng: poiLatLng ?? this.poiLatLng,
      poiLabel: poiLabel ?? this.poiLabel,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      wRent: wRent ?? this.wRent,
      wDistance: wDistance ?? this.wDistance,
      wAmenities: wAmenities ?? this.wAmenities,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    errorMessage,
    maxBudget,
    requiredGender,
    needsWifi,
    isSmoker,
    hasPet,
    groupSize,
    roomType,
    preferredAmenities,
    poiType,
    poiLatLng,
    poiLabel,
    maxDistanceKm,
    wRent,
    wDistance,
    wAmenities,
  ];
}
