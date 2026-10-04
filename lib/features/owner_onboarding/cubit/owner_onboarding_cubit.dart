import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../domain/repositories/owner_onboarding_repository.dart';

part 'owner_onboarding_state.dart';

/// Drives owner onboarding: the verification request, then the "Add
/// property" wizard, whose draft spans three pushed routes (so, like
/// `TenantOnboardingCubit`, this lives above the Navigator).
class OwnerOnboardingCubit extends Cubit<OwnerOnboardingState> {
  OwnerOnboardingCubit({required this._repository})
    : super(const OwnerOnboardingState());

  final OwnerOnboardingRepository _repository;

  /// Clears any property draft from a previous run of the wizard.
  void reset() => emit(const OwnerOnboardingState());

  // ── Verification ────────────────────────────────────────────────────────

  Future<void> submitForVerification(
    String uid, {
    List<UploadedImage> documents = const [],
  }) async {
    // Two required documents (ID, ownership); the business permit is optional.
    if (documents.length < CloudinaryConfig.requiredDocumentCount ||
        documents.length > CloudinaryConfig.documentCount) {
      emit(
        state.copyWith(
          status: OwnerOnboardingStatus.failure,
          errorMessage:
              'Please upload your government ID and property ownership document.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: OwnerOnboardingStatus.saving));
    try {
      final status = await _repository.submitForVerification(
        uid,
        documents: documents,
      );
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
    List<UploadedImage> photos = const [],
  }) {
    emit(
      state.copyWith(
        status: OwnerOnboardingStatus.editing,
        title: title,
        address: address,
        latitude: latitude,
        longitude: longitude,
        photos: List<UploadedImage>.unmodifiable(photos),
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

  /// Creates the `properties` doc. There is no owner-side TOPSIS, so no
  /// weight step to collect here.
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
              'property name, address, map pin, at least one photo and monthly rent.',
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
      photos: [for (final p in draft.photos) p.url],
      photoPublicIds: [for (final p in draft.photos) p.publicId],
      monthlyRent: draft.monthlyRent,
      depositAmount: draft.depositAmount,
      advanceMonths: draft.advanceMonths,
      isAvailable: true,
      vacancyStatus: 'available',
      // Placeholder: the datasource sets the real value from the owner's
      // verification status (badge only; the listing is live regardless).
      isVerified: false,
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
