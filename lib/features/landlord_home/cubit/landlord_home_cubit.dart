import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/landlord_property.dart';
import '../model/tenant.dart';

part 'landlord_home_state.dart';

/// Manages the landlord's tenant list and search query.
class LandlordHomeCubit extends Cubit<LandlordHomeState> {
  LandlordHomeCubit() : super(const LandlordHomeState());

  /// Updates the live search query.
  void updateSearch(String query) => emit(state.copyWith(searchQuery: query));
}
