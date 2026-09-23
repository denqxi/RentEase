import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns app-wide identity: sign in/up/out, and the email-verification gate.
/// Screens dispatch events and react to [AuthState] instead of talking to
/// Firebase directly.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthEmailVerificationResendRequested>(_onResendRequested);
    on<AuthEmailVerificationCheckRequested>(_onVerificationCheckRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
  }

  final AuthRepository _repository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final user = await _repository.currentUser();
    if (user == null) {
      emit(const AuthUnauthenticated());
    } else if (!user.emailVerified) {
      emit(AuthEmailNotVerified(user));
    } else {
      emit(AuthAuthenticated(user));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(user.emailVerified ? AuthAuthenticated(user) : AuthEmailNotVerified(user));
    } catch (e) {
      emit(AuthOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signUp(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        gender: event.gender,
        phone: event.phone,
        role: event.role,
      );
      // Freshly created accounts are always unverified.
      emit(AuthEmailNotVerified(user));
    } catch (e) {
      emit(AuthOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onResendRequested(
    AuthEmailVerificationResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthEmailNotVerified) return;
    try {
      await _repository.sendEmailVerification();
    } catch (e) {
      emit(AuthOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(current);
    }
  }

  Future<void> _onVerificationCheckRequested(
    AuthEmailVerificationCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthEmailNotVerified) return;
    final verified = await _repository.reloadAndCheckEmailVerified();
    if (verified) {
      emit(
        AuthAuthenticated(
          AppUser(
            uid: current.user.uid,
            email: current.user.email,
            role: current.user.role,
            emailVerified: true,
            firstName: current.user.firstName,
            lastName: current.user.lastName,
          ),
        ),
      );
    } else {
      emit(
        const AuthOperationFailure(
          'Email not verified yet. Please click the link we sent you.',
        ),
      );
      emit(current);
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.sendPasswordResetEmail(email: event.email);
      emit(AuthPasswordResetEmailSent(event.email));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(const AuthUnauthenticated());
    }
  }
}
