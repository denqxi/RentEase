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
    required this._tenantId,
    required HomeRepository this._repository,
    required FilteringService this._filteringService,
    required TopsisService this._topsisService,
  }) : super(HomeState(listings: const [], isLoading: true)) {
    refresh();
  }

  /// Guest browsing — no account, so no tenantProfiles/matches to read.
  /// Loads the newest available listings (the public `properties` view),
  /// unranked and without any personalised score. [refresh] reloads that
  /// feed; saving stays session-only.
  HomeCubit.guest({required HomeRepository this._repository})
    : _tenantId = '',
      _filteringService = null,
      _topsisService = null,
      super(HomeState(listings: const [], isGuest: true, isLoading: true)) {
    refresh();
  }

  final String _tenantId;
  final HomeRepository? _repository;
  final FilteringService? _filteringService;
  final TopsisService? _topsisService;

  Future<void> refresh() async {
    final repository = _repository;
    final filteringService = _filteringService;
    final topsisService = _topsisService;
    if (state.isGuest) {
      if (repository == null) return;
      emit(state.copyWith(isLoading: true, clearError: true));
      try {
        final listings = await repository.fetchGuestListings();
        if (isClosed) return;
        emit(state.copyWith(listings: listings, isLoading: false));
      } catch (e) {
        if (isClosed) return;
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: e.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
      return;
    }
    if (repository == null ||
        filteringService == null ||
        topsisService == null) {
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await filteringService.runFiltering(_tenantId);
      await topsisService.computeTOPSIS(_tenantId);
      final fetched = await repository.fetchCompatibleListings(_tenantId);
      if (isClosed) return;
      // Hearts are session-only; keep them across a refresh (e.g. after
      // editing preferences) instead of silently clearing them.
      final savedIds = {
        for (final l in state.listings)
          if (l.isSaved) l.id,
      };
      final listings = [
        for (final l in fetched)
          savedIds.contains(l.id) ? l.copyWith(isSaved: true) : l,
      ];
      emit(state.copyWith(listings: listings, isLoading: false));
    } on StateError {
      if (isClosed) return;
      // No tenantProfiles doc yet — onboarding hasn't been completed. Not
      // an error to surface; there's simply nothing to match yet.
      emit(state.copyWith(listings: const [], isLoading: false));
    } catch (e) {
      if (isClosed) return;
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
  /// fetched on demand rather than upfront for the whole feed. Guests get the
  /// public view (no owner info, no match).
  Future<Map<String, dynamic>?> loadPropertyDetail(String propertyId) {
    final repository = _repository;
    if (repository == null) return Future.value(null);
    if (state.isGuest) return repository.fetchGuestPropertyDetail(propertyId);
    return repository.fetchPropertyDetail(
      tenantId: _tenantId,
      propertyId: propertyId,
    );
  }
}
