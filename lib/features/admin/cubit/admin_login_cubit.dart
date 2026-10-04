import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/admin_entities.dart';
import '../domain/repositories/admin_repository.dart';

class AdminLoginState extends Equatable {
  const AdminLoginState({
    this.isLoading = false,
    this.isSignedIn = false,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSignedIn;
  final String? errorMessage;

  @override
  List<Object?> get props => [isLoading, isSignedIn, errorMessage];
}

/// Admin sign-in (no sign-up: admin accounts are created in the console).
class AdminLoginCubit extends Cubit<AdminLoginState> {
  AdminLoginCubit(this._repo) : super(const AdminLoginState());

  final AdminRepository _repo;

  Future<void> signIn(String email, String password) async {
    if (state.isLoading) return;
    emit(const AdminLoginState(isLoading: true));
    try {
      await _repo.signIn(email, password);
      emit(const AdminLoginState(isSignedIn: true));
    } on AdminException catch (e) {
      emit(AdminLoginState(errorMessage: e.message));
    } catch (_) {
      emit(const AdminLoginState(errorMessage: 'Could not sign in.'));
    }
  }

  Future<void> signOut() => _repo.signOut();
}
