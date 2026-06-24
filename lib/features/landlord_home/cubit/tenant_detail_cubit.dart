import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/tenant_detail.dart';

part 'tenant_detail_state.dart';

/// Manages saved state for a single tenant detail screen.
class TenantDetailCubit extends Cubit<TenantDetailState> {
  TenantDetailCubit({required TenantDetail detail})
      : super(TenantDetailState(detail: detail));

  /// Toggles the saved / heart state.
  void toggleSaved() => emit(
        state.copyWith(
          detail: state.detail.copyWith(isSaved: !state.detail.isSaved),
        ),
      );
}
