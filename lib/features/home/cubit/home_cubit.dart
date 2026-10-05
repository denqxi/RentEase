import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../saved/domain/repositories/saved_listings_repository.dart';
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
    this._savedRepository,
  }) : super(HomeState(listings: const [], isLoading: true)) {
    refresh();
    _watchSaved();
  }

  /// Guest browsing — no account, so no tenantProfiles/matches to read.
  /// Loads the newest available listings (the public `properties` view),
  /// unranked and without any personalised score. [refresh] reloads that
  /// feed; saving stays session-only.
  HomeCubit.guest({required HomeRepository this._repository})
    : _tenantId = '',
      _filteringService = null,
      _topsisService = null,
      _savedRepository = null,
      super(HomeState(listings: const [], isGuest: true, isLoading: true)) {
    refresh();
  }

  final String _tenantId;
  final HomeRepository? _repository;
  final FilteringService? _filteringService;
  final TopsisService? _topsisService;
  final SavedListingsRepository? _savedRepository;
  StreamSubscription<Set<String>>? _savedSub;
  final Set<String> _savingNow = {};

  /// Live saved ids (users/{uid}/savedListings): 1 listener, 1 read per saved
  /// doc on first snapshot, then one read per remote change. A stream error
  /// leaves the current hearts as they are.
  void _watchSaved() {
    final repo = _savedRepository;
    if (repo == null || _tenantId.isEmpty) return;
    _savedSub = repo
        .watchSavedIds(_tenantId)
        .listen(
          (ids) {
            if (isClosed) return;
            // While a toggle is in flight its optimistic value wins.
            final merged = {
              for (final id in ids)
                if (!_savingNow.contains(id)) id,
              for (final id in _savingNow)
                if (state.savedIds.contains(id)) id,
            };
            emit(_withSaved(state, merged));
          },
          onError: (_) {},
        );
  }

  /// [base] with [ids] as the saved set, mirrored onto every listing's flag.
  HomeState _withSaved(HomeState base, Set<String> ids) => base.copyWith(
    savedIds: ids,
    listings: [
      for (final l in base.listings)
        l.isSaved == ids.contains(l.id) ? l : l.copyWith(isSaved: ids.contains(l.id)),
    ],
  );

  @override
  Future<void> close() async {
    await _savedSub?.cancel();
    return super.close();
  }

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
      // Hearts live in [HomeState.savedIds]; mirror them onto the new cards.
      final savedIds = state.savedIds;
      final listings = [
        for (final l in fetched)
          savedIds.contains(l.id) ? l.copyWith(isSaved: true) : l,
      ];
      emit(state.copyWith(listings: listings, isLoading: false));
      // Separate, best-effort section; never affects the compatible list.
      await _loadOthers(repository);
    } on StateError {
      if (isClosed) return;
      // No tenantProfiles doc yet — onboarding hasn't been completed. Not
      // an error to surface; there's simply nothing to match yet.
      emit(
        state.copyWith(
          listings: const [],
          isLoading: false,
          otherListings: const [],
          othersFailed: false,
        ),
      );
      return;
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

  static const int _othersShown = 10;
  static const int _othersFetched = 20;

  /// Loads "Other listings": available properties that fail the saved
  /// preferences, view-only. Cost: one properties query (limit 20), the
  /// tenant profile + user docs, and owner lookups for the shown cards only.
  /// A failure keeps the compatible sections and just flags [othersFailed].
  Future<void> _loadOthers(HomeRepository repository) async {
    emit(state.copyWith(isLoadingOthers: true, othersFailed: false));
    try {
      final profile = await repository.fetchTenantProfile(_tenantId);
      if (isClosed) return;
      if (profile == null) {
        emit(state.copyWith(otherListings: const [], isLoadingOthers: false));
        return;
      }
      final fetched = await repository.fetchNonMatchingResults(
        tenantId: _tenantId,
        profile: profile,
        excludePropertyIds: {for (final l in state.listings) l.id},
        limit: _othersFetched,
        displayLimit: _othersShown,
      );
      if (isClosed) return;
      // Fewest reasons first, ties newest-first (fetch order); never by Ci
      // or distance, and never merged into the compatible list.
      final indexed = fetched.indexed.toList()
        ..sort((a, b) {
          final byReasons = _reasonCount(a.$2).compareTo(_reasonCount(b.$2));
          return byReasons != 0 ? byReasons : a.$1.compareTo(b.$1);
        });
      emit(
        state.copyWith(
          otherListings: [for (final e in indexed.take(_othersShown)) e.$2],
          isLoadingOthers: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          otherListings: const [],
          isLoadingOthers: false,
          othersFailed: true,
        ),
      );
    }
  }

  static int _reasonCount(Map<String, dynamic> p) =>
      (p['mismatchReasons'] as List?)?.length ?? 0;

  /// Retry for just the "Other listings" section.
  Future<void> retryOthers() async {
    final repository = _repository;
    if (state.isGuest || repository == null) return;
    await _loadOthers(repository);
  }

  /// "See more": asks Search to switch its (session-only) non-match toggle on.
  void requestSearchWithNonMatches() => emit(
    state.copyWith(searchNonMatchesRequests: state.searchNonMatchesRequests + 1),
  );

  /// Hearts / un-hearts [id]. Optimistic: the UI flips at once, the write goes
  /// to users/{uid}/savedListings (1 write), and on failure the flip is rolled
  /// back and [HomeState.saveFailures] is bumped for a SnackBar. A second tap
  /// while the first write is in flight is ignored. Guests have no repository
  /// (the UI shows the guest sheet) so nothing is ever written for them.
  Future<void> toggleSaved(String id) async {
    if (_savingNow.contains(id)) return;
    final wasSaved = state.savedIds.contains(id);
    final next = {...state.savedIds};
    wasSaved ? next.remove(id) : next.add(id);
    emit(_withSaved(state, next));

    final repo = _savedRepository;
    if (repo == null || state.isGuest || _tenantId.isEmpty) return;
    _savingNow.add(id);
    try {
      if (wasSaved) {
        await repo.unsave(_tenantId, id);
      } else {
        await repo.save(_tenantId, id);
      }
      _savingNow.remove(id);
    } catch (_) {
      _savingNow.remove(id);
      if (isClosed) return;
      final rolledBack = {...state.savedIds};
      wasSaved ? rolledBack.add(id) : rolledBack.remove(id);
      emit(
        _withSaved(state, rolledBack).copyWith(
          saveFailures: state.saveFailures + 1,
        ),
      );
    }
  }

  /// Loads the Saved screen: the available properties among the current saved
  /// ids, in chunks of 30 (ceil(n/30) reads of up to 30 docs). Cards of
  /// compatible listings keep their match percent; others show none.
  Future<void> loadSaved() async {
    final repo = _savedRepository;
    if (repo == null || state.isGuest) return;
    emit(state.copyWith(isLoadingSaved: true, savedLoadFailed: false));
    try {
      final fetched = await repo.fetchSavedListings(state.savedIds.toList());
      if (isClosed) return;
      final percentById = {for (final l in state.listings) l.id: l.matchPercent};
      emit(
        state.copyWith(
          savedListings: [
            for (final l in fetched)
              l.copyWith(
                isSaved: true,
                matchPercent: percentById[l.id] ?? l.matchPercent,
              ),
          ],
          isLoadingSaved: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingSaved: false, savedLoadFailed: true));
    }
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
