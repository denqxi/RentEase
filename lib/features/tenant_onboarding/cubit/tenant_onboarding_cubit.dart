import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/tenant_profile_doc.dart';
import '../../matching/domain/services/filtering_service.dart';
import '../../matching/domain/services/topsis_service.dart';
import '../domain/repositories/tenant_profile_repository.dart';

part 'tenant_onboarding_state.dart';

/// Collects the tenant's matching inputs across the onboarding screens and
/// writes them to `tenantProfiles/{uid}` once, on "Find My Matches".
///
/// A single write (rather than one per step) means the client-side matching
/// engine (`FilteringService` — no Cloud Functions, see CLAUDE.md
/// "Client-Side Matching Engine") runs exactly once, on a complete profile —
/// see CLAUDE.md rule 7 ("matching runs at profile-save time").
class TenantOnboardingCubit extends Cubit<TenantOnboardingState> {
  TenantOnboardingCubit({
    required TenantProfileRepository repository,
    required FilteringService filteringService,
    required TopsisService topsisService,
  }) : _repository = repository,
       _filteringService = filteringService,
       _topsisService = topsisService,
       super(const TenantOnboardingState());

  final TenantProfileRepository _repository;
  final FilteringService _filteringService;
  final TopsisService _topsisService;

  /// Clears any draft from a previous run of the flow.
  void reset() => emit(const TenantOnboardingState());

  // ── Step 1: hard constraints ────────────────────────────────────────────

  void saveHardConstraints({
    required num maxBudget,
    required String requiredGender,
    required bool needsWifi,
    required bool isSmoker,
    required bool hasPet,
    required int groupSize,
  }) {
    emit(
      state.copyWith(
        maxBudget: maxBudget,
        requiredGender: requiredGender,
        needsWifi: needsWifi,
        isSmoker: isSmoker,
        hasPet: hasPet,
        groupSize: groupSize,
      ),
    );
  }

  // ── Step 2: soft preferences ────────────────────────────────────────────

  void saveSoftPreferences({
    required String roomType,
    required List<String> preferredAmenities,
  }) {
    emit(
      state.copyWith(
        roomType: roomType,
        preferredAmenities: List<String>.unmodifiable(preferredAmenities),
      ),
    );
  }

  // ── Step 3: POI ─────────────────────────────────────────────────────────

  void savePoi({
    required String poiType,
    required double latitude,
    required double longitude,
    required String label,
  }) {
    emit(
      state.copyWith(
        poiType: poiType,
        poiLatLng: GeoPoint(latitude, longitude),
        poiLabel: label,
      ),
    );
  }

  // ── Step 4: distance ────────────────────────────────────────────────────

  void saveMaxDistance(double km) => emit(state.copyWith(maxDistanceKm: km));

  // ── Step 5: TOPSIS weights + submit ─────────────────────────────────────

  /// Stores the weights and persists the whole profile. Emits
  /// [TenantOnboardingStatus.saved] on success; on failure the draft is kept
  /// so the user can simply retry.
  Future<void> submit({
    required String uid,
    required double wRent,
    required double wDistance,
    required double wAmenities,
  }) async {
    final draft = state.copyWith(
      wRent: wRent,
      wDistance: wDistance,
      wAmenities: wAmenities,
    );

    if (!draft.isComplete) {
      emit(
        draft.copyWith(
          status: TenantOnboardingStatus.failure,
          errorMessage:
              'Some onboarding steps are incomplete. Please go back and fill '
              'in your budget, gender policy and location.',
        ),
      );
      return;
    }

    emit(draft.copyWith(status: TenantOnboardingStatus.saving));

    final profile = TenantProfileDoc(
      userId: uid,
      maxBudget: draft.maxBudget!,
      requiredGender: draft.requiredGender!,
      needsWifi: draft.needsWifi,
      roomType: draft.roomType,
      preferredAmenities: draft.preferredAmenities,
      maxDistanceKm: draft.maxDistanceKm,
      poiLatLng: draft.poiLatLng!,
      poiLabel: draft.poiLabel ?? '',
      poiType: draft.poiType,
      isSmoker: draft.isSmoker,
      hasPet: draft.hasPet,
      groupSize: draft.groupSize,
      isSeeking: true,
      wRent: draft.wRent,
      wDistance: draft.wDistance,
      wAmenities: draft.wAmenities,
    );

    try {
      await _repository.saveProfile(profile);
      // Profile-save time is when matching runs (CLAUDE.md rule 7) — not
      // deferred to when the tenant later opens the recommendations screen.
      // TOPSIS is chained immediately after filtering (SPRINTPLAN Day 5),
      // ranking only the pool filtering just produced.
      await _filteringService.runFiltering(uid);
      await _topsisService.computeTOPSIS(uid);
      emit(draft.copyWith(status: TenantOnboardingStatus.saved));
    } catch (e) {
      emit(
        draft.copyWith(
          status: TenantOnboardingStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
