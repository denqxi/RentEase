import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore/models/models.dart';
import '../domain/repositories/home_repository.dart';

part 'search_state.dart';

/// Search's data: the tenant's already-ranked compatible listings plus their
/// saved constraints (for the filter chips). Only reads cached matches —
/// matching itself re-runs from Home (CLAUDE.md rule 7), and [load] is
/// called again once that finishes. Session filters and the text query are
/// local widget state, not held here (rule 3).
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({required this.tenantId, required this._repository})
    : _guest = false,
      super(const SearchState()) {
    load();
  }

  /// Guest preview: the public newest-available feed, unranked, no profile.
  SearchCubit.guest({required this._repository})
    : tenantId = '',
      _guest = true,
      super(const SearchState()) {
    load();
  }

  final String tenantId;
  final HomeRepository _repository;
  final bool _guest;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.results.isEmpty, clearError: true));
    try {
      if (_guest) {
        final results = await _repository.fetchGuestSearchResults();
        if (isClosed) return;
        emit(SearchState(isLoading: false, results: results));
        return;
      }
      final (results, profile) = await (
        _repository.fetchSearchResults(tenantId),
        _repository.fetchTenantProfile(tenantId),
      ).wait;
      if (isClosed) return;
      emit(
        SearchState(
          isLoading: false,
          results: results,
          profile: profile,
          includeNonMatching: state.includeNonMatching,
          nonMatches: state.nonMatches,
        ),
      );
      if (state.includeNonMatching) await _loadNonMatches();
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

  /// Turns the "outside my preferences" list on or off. Session-only: the
  /// flag lives in this cubit's state and is never persisted (rule 3).
  Future<void> setIncludeNonMatching(bool include) async {
    if (_guest || include == state.includeNonMatching) return;
    if (!include) {
      emit(
        state.copyWith(
          includeNonMatching: false,
          nonMatches: const [],
          nonMatchesFailed: false,
        ),
      );
      return;
    }
    emit(state.copyWith(includeNonMatching: true));
    await _loadNonMatches();
  }

  Future<void> _loadNonMatches() async {
    final profile = state.profile;
    if (profile == null) {
      // Not onboarded: no constraints to compare against.
      emit(state.copyWith(nonMatches: const [], isLoadingNonMatches: false));
      return;
    }
    emit(state.copyWith(isLoadingNonMatches: true, nonMatchesFailed: false));
    try {
      final fetched = await _repository.fetchNonMatchingResults(
        tenantId: tenantId,
        profile: profile,
        excludePropertyIds: {
          for (final r in state.results) r['propertyId'] as String,
        },
      );
      if (isClosed || !state.includeNonMatching) return;
      // Fewest reasons first; the fetch is newest-first, so the index keeps
      // ties newest-first (List.sort is not stable). Never by distance.
      final indexed = fetched.indexed.toList()
        ..sort((a, b) {
          final byReasons = _reasonCount(a.$2).compareTo(_reasonCount(b.$2));
          return byReasons != 0 ? byReasons : a.$1.compareTo(b.$1);
        });
      emit(
        state.copyWith(
          nonMatches: [for (final e in indexed) e.$2],
          isLoadingNonMatches: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          nonMatches: const [],
          isLoadingNonMatches: false,
          nonMatchesFailed: true,
        ),
      );
    }
  }

  static int _reasonCount(Map<String, dynamic> p) =>
      (p['mismatchReasons'] as List?)?.length ?? 0;
}
