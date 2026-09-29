import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/repositories/owner_onboarding_repository.dart';

part 'owner_onboarding_state.dart';

/// Drives owner onboarding: the verification request, then the "Add
/// property" wizard, whose draft spans three pushed routes (so, like
/// `TenantOnboardingCubit`, this lives above the Navigator).
class OwnerOnboardingCubit extends Cubit<OwnerOnboardingState> {
  OwnerOnboardingCubit({required OwnerOnboardingRepository repository})
    : _repository = repository,
      super(const OwnerOnboardingState());

  final OwnerOnboardingRepository _repository;

  /// Clears any property draft from a previous run of the wizard.
  void reset() => emit(const OwnerOnboardingState());

  // ── Verification ────────────────────────────────────────────────────────

  Future<void> submitForVerification(String uid) async {
    emit(state.copyWith(status: OwnerOnboardingStatus.saving));
    try {
      final status = await _repository.submitForVerification(uid);
      emit(
        state.copyWith(
          status: OwnerOnboardingStatus.saved,
          verificationStatus: status,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OwnerOnboardingStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Stream<String> watchVerificationStatus(String uid) =>
      _repository.watchVerificationStatus(uid);

  // ── Step 1: basics ──────────────────────────────────────────────────────

  void saveBasics({
    required String title,
    required String address,
    required double latitude,
    required double longitude,
  }) {
    emit(
      state.copyWith(
        status: OwnerOnboardingStatus.editing,
        title: title,
        address: address,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  // ── Step 2: house rules ─────────────────────────────────────────────────

  void saveRules({
    required int depositAmount,
    required int advanceMonths,
    required String allowedGender,
    required bool smokingAllowed,
    required bool petsAllowed,
    required int curfewHours,
    required int maxOccupants,
  }) {
    emit(
      state.copyWith(
        status: OwnerOnboardingStatus.editing,
        depositAmount: depositAmount,
        advanceMonths: advanceMonths,
        allowedGender: allowedGender,
        smokingAllowed: smokingAllowed,
        petsAllowed: petsAllowed,
        curfewHours: curfewHours,
        maxOccupants: maxOccupants,
      ),
    );
  }

  // ── Step 3: pricing and amenities ───────────────────────────────────────

  void savePricing({required int monthlyRent, required List<String> amenities}) {
    emit(
      state.copyWith(
        status: OwnerOnboardingStatus.editing,
        monthlyRent: monthlyRent,
        amenities: List<String>.unmodifiable(amenities),
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  /// Creates the `properties` doc. Owner-side TOPSIS weights are fixed
  /// (CLAUDE.md "Two TOPSIS Instances" — unlike the tenant side, the owner
  /// does not adjust them), so there's no weight step to collect here.
  /// Emits [OwnerOnboardingStatus.saved] on success; on failure the draft is
  /// kept so the owner can retry.
  Future<void> submitProperty({required String uid}) async {
    final draft = state;

    if (!draft.isComplete) {
      emit(
        draft.copyWith(
          status: OwnerOnboardingStatus.failure,
          errorMessage:
              'Some steps are incomplete. Please go back and fill in the '
              'property name, address, map pin and monthly rent.',
        ),
      );
      return;
    }

    emit(draft.copyWith(status: OwnerOnboardingStatus.saving));

    final property = PropertyDoc(
      propertyId: '',
      ownerId: uid,
      title: draft.title,
      address: draft.address,
      location: GeoPoint(draft.latitude!, draft.longitude!),
      // Not used for querying yet — distance filtering runs on-device over
      // all available listings (DistanceUtils), not via geohash ranges.
      geoHash: '',
      photos: const [],
      monthlyRent: draft.monthlyRent,
      depositAmount: draft.depositAmount,
      advanceMonths: draft.advanceMonths,
      isAvailable: true,
      vacancyStatus: 'available',
      // Mirrors the owner's own verification; the create rule only accepts
      // this write from an admin-verified owner in the first place.
      isVerified: true,
      allowedGender: draft.allowedGender,
      smokingAllowed: draft.smokingAllowed,
      petsAllowed: draft.petsAllowed,
      maxOccupants: draft.maxOccupants,
      curfewHours: draft.curfewHours,
      hasWifi: draft.amenities.contains('WiFi'),
      amenityList: draft.amenities,
      amenityScore: draft.amenities.length,
    );

    try {
      final propertyId = await _repository.createProperty(property);
      emit(
        draft.copyWith(
          status: OwnerOnboardingStatus.saved,
          createdPropertyId: propertyId,
        ),
      );
    } catch (e) {
      emit(
        draft.copyWith(
          status: OwnerOnboardingStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
