import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/services/inquiry_service.dart';
import '../model/invite_option.dart';

part 'invite_state.dart';

/// Whether (and to which of their properties) an owner can invite one
/// compatible tenant, and the send action itself. All eligibility rules live
/// in [InquiryService.inviteOptions] — this only holds UI state, so the
/// Invite button can simply be absent when [InviteState.canInvite] is false.
class InviteCubit extends Cubit<InviteState> {
  InviteCubit({
    required this.ownerId,
    required this.tenantId,
    required this._service,
    this.propertyId,
  }) : super(const InviteState()) {
    load();
  }

  final String ownerId;
  final String tenantId;

  /// Restricts the invite to one property (Find Tenants' selected one).
  final String? propertyId;
  final InquiryService _service;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final options = await _service.inviteOptions(
        ownerId: ownerId,
        tenantId: tenantId,
        propertyId: propertyId,
      );
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, options: options));
    } catch (e) {
      if (isClosed) return;
      // Eligibility couldn't be established, so offer nothing.
      emit(state.copyWith(isLoading: false, options: const []));
    }
  }

  /// Sends the invitation for [option]. Ignored while another send is in
  /// flight (double taps). On success the option disappears, so the button
  /// goes away; [InviteState.sentTitle] drives the confirmation snackbar.
  Future<bool> send(InviteOption option) async {
    if (state.isSending) return false;
    emit(state.copyWith(isSending: true, clearError: true, clearSent: true));
    try {
      await _service.sendInvite(ownerId: ownerId, matchId: option.matchId);
      if (isClosed) return true;
      emit(
        state.copyWith(
          isSending: false,
          options: [
            for (final o in state.options)
              if (o.matchId != option.matchId) o,
          ],
          sentTitle: option.propertyTitle,
        ),
      );
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  void clearMessages() => emit(state.copyWith(clearError: true, clearSent: true));
}
