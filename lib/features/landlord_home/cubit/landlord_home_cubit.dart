import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/landlord_property.dart';
import '../model/tenant.dart';

part 'landlord_home_state.dart';

/// Manages the landlord's tenant list, saved state, and search query.
class LandlordHomeCubit extends Cubit<LandlordHomeState> {
  LandlordHomeCubit() : super(const LandlordHomeState());

  /// Flips the saved flag for the tenant with [id].
  void toggleSaved(String id) {
    final updated = state.tenants.map((t) {
      return t.id == id ? t.copyWith(isSaved: !t.isSaved) : t;
    }).toList();
    emit(state.copyWith(tenants: updated));
  }

  /// Updates the live search query.
  void updateSearch(String query) => emit(state.copyWith(searchQuery: query));
}
