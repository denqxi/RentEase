import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/tenant_profile_doc.dart';
import '../../matching/domain/services/filtering_service.dart';
import '../../matching/domain/services/topsis_service.dart';
import '../../tenant_onboarding/domain/repositories/tenant_profile_repository.dart';

enum EditPreferencesStatus { loading, ready, saving, saved, failure }

class EditPreferencesState extends Equatable {
  const EditPreferencesState({
    this.status = EditPreferencesStatus.loading,
    this.profile,
    this.errorMessage,
  });

  final EditPreferencesStatus status;
  final TenantProfileDoc? profile;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, profile, errorMessage];
}

/// Backs Profile's "My preferences" (hard constraints) and "Ranking
/// priorities" (TOPSIS weights) screens. Saving is a profile-save, so the
/// matching engine re-runs right away (CLAUDE.md rule 7) — the Home and
/// Search tabs then just re-read the refreshed `matches`.
class EditPreferencesCubit extends Cubit<EditPreferencesState> {
  EditPreferencesCubit({
    required this.uid,
    required TenantProfileRepository repository,
    required FilteringService filteringService,
    required TopsisService topsisService,
  }) : _repository = repository,
       _filteringService = filteringService,
       _topsisService = topsisService,
       super(const EditPreferencesState()) {
    _load();
  }

  final String uid;
  final TenantProfileRepository _repository;
  final FilteringService _filteringService;
  final TopsisService _topsisService;

  Future<void> _load() async {
    try {
      final profile = await _repository.fetchProfile(uid);
      if (isClosed) return;
      emit(
        profile == null
            ? const EditPreferencesState(
                status: EditPreferencesStatus.failure,
                errorMessage:
                    'Finish onboarding first — there are no preferences to '
                    'edit yet.',
              )
            : EditPreferencesState(
                status: EditPreferencesStatus.ready,
                profile: profile,
              ),
      );
    } catch (e) {
      _fail(e);
    }
  }

  /// Hard constraints change who is eligible at all, so both filtering and
  /// TOPSIS re-run.
  Future<void> saveConstraints({
    required num maxBudget,
    required String requiredGender,
    required bool needsWifi,
    required double maxDistanceKm,
  }) async {
    if (maxBudget <= 0) {
      _fail(Exception('Enter a monthly budget above ₱0.'));
      return;
    }
    await _save(
      fields: {
        'maxBudget': maxBudget,
        'requiredGender': requiredGender,
        'needsWifi': needsWifi,
        'maxDistanceKm': maxDistanceKm,
      },
      refilter: true,
    );
  }

  /// Weights only change the ranking, not eligibility — TOPSIS alone
  /// re-runs. CLAUDE.md: the three weights must always sum to 1.0.
  Future<void> saveWeights({
    required double wRent,
    required double wDistance,
    required double wAmenities,
  }) async {
    if ((wRent + wDistance + wAmenities - 1).abs() > 1e-6) {
      _fail(Exception('Your priorities must add up to exactly 100%.'));
      return;
    }
    await _save(
      fields: {
        'wRent': wRent,
        'wDistance': wDistance,
        'wAmenities': wAmenities,
      },
      refilter: false,
    );
  }

  Future<void> _save({
    required Map<String, dynamic> fields,
    required bool refilter,
  }) async {
    final profile = state.profile;
    emit(EditPreferencesState(status: EditPreferencesStatus.saving, profile: profile));
    try {
      await _repository.updateFields(uid, fields);
      if (refilter) await _filteringService.runFiltering(uid);
      await _topsisService.computeTOPSIS(uid);
      if (isClosed) return;
      emit(EditPreferencesState(status: EditPreferencesStatus.saved, profile: profile));
    } catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    if (isClosed) return;
    emit(
      EditPreferencesState(
        status: state.profile == null
            ? EditPreferencesStatus.failure
            : EditPreferencesStatus.ready,
        profile: state.profile,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ),
    );
  }
}
