import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/listing_detail.dart';

part 'listing_detail_state.dart';

/// Manages saved state and contact action for a single listing detail screen.
class ListingDetailCubit extends Cubit<ListingDetailState> {
  ListingDetailCubit({required ListingDetail detail})
      : super(ListingDetailState(detail: detail));

  /// Toggles the saved / heart state.
  void toggleSaved() =>
      emit(state.copyWith(detail: state.detail.copyWith(isSaved: !state.detail.isSaved)));
}
