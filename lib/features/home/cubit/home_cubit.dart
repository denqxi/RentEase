import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../matching/domain/services/filtering_service.dart';
import '../../matching/domain/services/topsis_service.dart';
import '../domain/repositories/home_repository.dart';
import '../model/listing.dart';

part 'home_state.dart';

/// Manages all listing data and the heart-toggle save state shared across
/// Home, Matches, and Saved tabs.
///
/// [refresh] is CLAUDE.md's client-side matching engine trigger (b): "the
/// tenant opens the recommendations screen (catches listings added since
/// their last visit)" — it re-runs FilteringService + TopsisService before
/// reading the (now current) cached `matches` back, rather than trusting
/// whatever was last computed at onboarding time.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required String tenantId,
    required HomeRepository repository,
    required FilteringService filteringService,
    required TopsisService topsisService,
  }) : _tenantId = tenantId,
       _repository = repository,
       _filteringService = filteringService,
       _topsisService = topsisService,
       super(HomeState(listings: const [], isLoading: true)) {
    refresh();
  }

  /// Guest browsing — no account, so no tenantProfiles/matches to read.
  /// Shows every listing ([Listing.guestSamples]) straight from local mock
  /// data, unranked; [refresh]/[toggleSaved]/[loadPropertyDetail] are no-ops
  /// since there's nothing server-side to hit.
  HomeCubit.guest()
    : _tenantId = '',
      _repository = null,
      _filteringService = null,
      _topsisService = null,
      super(HomeState(listings: Listing.guestSamples, isGuest: true));

  final String _tenantId;
  final HomeRepository? _repository;
  final FilteringService? _filteringService;
  final TopsisService? _topsisService;

  Future<void> refresh() async {
    final repository = _repository;
    final filteringService = _filteringService;
    final topsisService = _topsisService;
    if (repository == null || filteringService == null || topsisService == null) {
      return; // guest mode — nothing to refresh
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await filteringService.runFiltering(_tenantId);
      await topsisService.computeTOPSIS(_tenantId);
      final listings = await repository.fetchCompatibleListings(_tenantId);
      emit(state.copyWith(listings: listings, isLoading: false));
    } on StateError {
      // No tenantProfiles doc yet — onboarding hasn't been completed. Not
      // an error to surface; there's simply nothing to match yet.
      emit(state.copyWith(listings: const [], isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  /// Flips the saved flag for the listing with [id]. Local-only — RentEase's
  /// schema has no `savedProperties` collection, matching the prototype's
  /// existing behavior. Works in guest mode too (session-only, same as
  /// everywhere else).
  void toggleSaved(String id) {
    final updated = state.listings
        .map((l) => l.id == id ? l.copyWith(isSaved: !l.isSaved) : l)
        .toList();
    emit(state.copyWith(listings: updated));
  }

  /// Updates the live search query.
  void updateSearch(String query) => emit(state.copyWith(searchQuery: query));

  /// Assembles the detail-screen map for one listing (owner info included) —
  /// fetched on demand rather than upfront for the whole feed. Null in guest
  /// mode; guest screens build their detail view straight from MockData
  /// instead (see NearbySection/RecommendedSection).
  Future<Map<String, dynamic>?> loadPropertyDetail(String propertyId) {
    final repository = _repository;
    if (repository == null) return Future.value(null);
    return repository.fetchPropertyDetail(
      tenantId: _tenantId,
      propertyId: propertyId,
    );
  }
}
