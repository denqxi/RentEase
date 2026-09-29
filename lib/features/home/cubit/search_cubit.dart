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
  SearchCubit({required this.tenantId, required HomeRepository repository})
    : _repository = repository,
      super(const SearchState()) {
    load();
  }

  final String tenantId;
  final HomeRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: state.results.isEmpty, clearError: true));
    try {
      final (results, profile) = await (
        _repository.fetchSearchResults(tenantId),
        _repository.fetchTenantProfile(tenantId),
      ).wait;
      if (isClosed) return;
      emit(SearchState(isLoading: false, results: results, profile: profile));
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
}
