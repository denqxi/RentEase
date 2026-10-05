import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/account_deletion_repository.dart';
import '../../domain/services/account_deletion_service.dart';

part 'delete_account_state.dart';

/// Drives the "Delete my account" screen: validates the typed confirmation
/// and password, runs [AccountDeletionService], and maps failures to friendly
/// text. Retrying after a failure resumes the (idempotent) deletion.
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit({
    required this.uid,
    required this.isOwner,
    required this._service,
  }) : super(const DeleteAccountState());

  /// The word the user must type to confirm.
  static const String confirmWord = 'DELETE';

  final String uid;
  final bool isOwner;
  final AccountDeletionService _service;

  /// Whether the form is complete enough to submit.
  static bool canSubmit({required String password, required String typed}) =>
      password.isNotEmpty && typed.trim() == confirmWord;

  Future<void> delete({required String password, required String typed}) async {
    if (state.status == DeleteAccountStatus.deleting ||
        state.status == DeleteAccountStatus.success) {
      return; // double-tap guard
    }
    if (!canSubmit(password: password, typed: typed)) {
      emit(
        DeleteAccountState(
          status: DeleteAccountStatus.failure,
          errorMessage: password.isEmpty
              ? 'Enter your current password.'
              : 'Type $confirmWord to confirm.',
        ),
      );
      return;
    }
    emit(const DeleteAccountState(status: DeleteAccountStatus.deleting));
    try {
      await _service.deleteAccount(
        uid: uid,
        isOwner: isOwner,
        password: password,
      );
      if (!isClosed) {
        emit(const DeleteAccountState(status: DeleteAccountStatus.success));
      }
    } on AccountDeletionFailure catch (f) {
      if (!isClosed) {
        emit(
          DeleteAccountState(
            status: DeleteAccountStatus.failure,
            errorMessage: messageFor(f.kind),
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          DeleteAccountState(
            status: DeleteAccountStatus.failure,
            errorMessage: messageFor(AccountDeletionFailureKind.unknown),
          ),
        );
      }
    }
  }

  static String messageFor(AccountDeletionFailureKind kind) => switch (kind) {
    AccountDeletionFailureKind.wrongPassword => 'That password is not correct.',
    AccountDeletionFailureKind.requiresRecentLogin =>
      'For security, please log out, sign in again and retry.',
    AccountDeletionFailureKind.network =>
      'No connection. Check your internet and tap Delete again to continue.',
    AccountDeletionFailureKind.denied =>
      'We could not complete the deletion right now. Please try again later.',
    AccountDeletionFailureKind.unknown =>
      'Something went wrong. Tap Delete again to continue where it stopped.',
  };
}
