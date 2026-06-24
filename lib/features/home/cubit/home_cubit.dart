import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/listing.dart';

part 'home_state.dart';

/// Manages all listing data and the heart-toggle save state shared across
/// Home, Matches, and Saved tabs.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  /// Flips the saved flag for the listing with [id].
  void toggleSaved(String id) {
    final updated = state.listings
        .map((l) => l.id == id ? l.copyWith(isSaved: !l.isSaved) : l)
        .toList();
    emit(state.copyWith(listings: updated));
  }

  /// Updates the live search query.
  void updateSearch(String query) => emit(state.copyWith(searchQuery: query));
}
