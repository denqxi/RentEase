import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../../../core/constants/cloudinary_config.dart';
import '../../uploads/domain/entities/uploaded_image.dart';
import '../domain/repositories/owner_onboarding_repository.dart';

part 'owner_onboarding_state.dart';

/// Drives owner onboarding: the verification request, then the "Add
/// property" wizard (`CreateListingWizardScreen`); like
/// `TenantOnboardingCubit`, this lives above the Navigator.
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

  // ── Create-listing wizard ────────────────────────────────────────────────

  /// Commits the full wizard draft (all 6 steps) to state.
  /// `title` is generated: `"$propertyName – $roomName"` for a room.
  void saveListing({
    required String rentalType,
    required String propertyName,
    String? propertyType,
    String? roomName,
    String? parentPropertyId,
    required String address,
    required double latitude,
    required double longitude,
    required List<UploadedImage> photos,
    UploadedImage? propertyCoverPhoto,
    required int depositAmount,
    required int advanceMonths,
    required String allowedGender,
    required bool smokingAllowed,
    required bool petsAllowed,
    int? curfewHours,
    required int maxOccupants,
    required int monthlyRent,
    required bool isAvailable,
    required List<String> amenities,
  }) {
    final isRoom = rentalType == 'room';
    emit(
      state.copyWith(
        status: OwnerOnboardingStatus.editing,
        rentalType: rentalType,
        title: isRoom ? '$propertyName – ${roomName ?? ''}' : propertyName,
        propertyName: propertyName,
        propertyType: propertyType,
        roomName: isRoom ? roomName : null,
        parentPropertyId: parentPropertyId,
        clearParentPropertyId: parentPropertyId == null,
        address: address,
        latitude: latitude,
        longitude: longitude,
        photos: List<UploadedImage>.unmodifiable(photos),
        propertyCoverPhoto: propertyCoverPhoto,
        clearPropertyCoverPhoto: propertyCoverPhoto == null,
        depositAmount: depositAmount,
        advanceMonths: advanceMonths,
        allowedGender: allowedGender,
        smokingAllowed: smokingAllowed,
        petsAllowed: petsAllowed,
        curfewHours: curfewHours,
        clearCurfew: curfewHours == null,
        maxOccupants: maxOccupants < 1 ? 1 : maxOccupants,
        monthlyRent: monthlyRent,
        isAvailable: isAvailable,
        amenities: List<String>.unmodifiable(amenities),
      ),
    );
  }

  /// The signed-in owner's listings (saved-property picker source).
  Future<List<PropertyDoc>> fetchOwnerListings(String uid) =>
      _repository.fetchOwnerProperties(uid);

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

    try {
      if (draft.isRoom) {
        final existing = await _repository.fetchOwnerProperties(uid);
        if (isDuplicateRoom(
          existing,
          parentPropertyId: draft.parentPropertyId,
          propertyName: draft.propertyName,
          roomName: draft.roomName,
        )) {
          emit(
            draft.copyWith(
              status: OwnerOnboardingStatus.failure,
              errorMessage:
                  '"${draft.roomName}" already exists in this property. '
                  'Please use a different room name or number.',
            ),
          );
          return;
        }
      }

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
        isAvailable: draft.isAvailable,
        vacancyStatus: draft.isAvailable ? 'available' : 'booked',
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
        rentalType: draft.rentalType,
        propertyName: draft.propertyName,
        roomName: draft.isRoom ? draft.roomName : null,
        propertyType: draft.propertyType,
        parentPropertyId: draft.isRoom ? draft.parentPropertyId : null,
        propertyCoverPhoto: draft.isRoom ? draft.propertyCoverPhoto?.url : null,
        propertyCoverPublicId:
            draft.isRoom ? draft.propertyCoverPhoto?.publicId : null,
      );

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

  /// True when [roomName] is already used by another room of the same
  /// property (matched by [parentPropertyId], falling back to the property
  /// name for older listings). Case/whitespace-insensitive.
  static bool isDuplicateRoom(
    List<PropertyDoc> existing, {
    String? parentPropertyId,
    String? propertyName,
    String? roomName,
  }) {
    String norm(String? s) => (s ?? '').trim().toLowerCase();
    final wanted = norm(roomName);
    if (wanted.isEmpty) return false;
    return existing.any((p) {
      if (!p.isRoom) return false;
      final sameProperty = parentPropertyId != null
          ? p.parentPropertyId == parentPropertyId
          : norm(p.propertyName) == norm(propertyName);
      return sameProperty && norm(p.roomName) == wanted;
    });
  }

}
