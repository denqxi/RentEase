part of 'delete_account_cubit.dart';

enum DeleteAccountStatus { idle, deleting, success, failure }

class DeleteAccountState extends Equatable {
  const DeleteAccountState({
    this.status = DeleteAccountStatus.idle,
    this.errorMessage,
  });

  final DeleteAccountStatus status;
  final String? errorMessage;

  bool get isDeleting => status == DeleteAccountStatus.deleting;

  @override
  List<Object?> get props => <Object?>[status, errorMessage];
}
