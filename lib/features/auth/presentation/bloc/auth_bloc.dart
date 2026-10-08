import 'dart:async';

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
  AuthBloc({required this._repository})
      : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthEmailVerificationResendRequested>(_onResendRequested);
    on<AuthEmailVerificationCheckRequested>(_onVerificationCheckRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthSuspensionDetected>(_onSuspensionDetected);
  }

  /// Shown on the sign-in screen after an admin suspends the account.
  static const suspendedMessage =
      'Your account has been suspended. Contact support.';

  final AuthRepository _repository;
  StreamSubscription<bool>? _suspensionSub;

  /// Follows the signed-in user's status so a suspension applies even while
  /// the app is open; cancelled on sign-out and in [close].
  void _watchSuspension(AppUser user) {
    _suspensionSub?.cancel();
    _suspensionSub = _repository.watchSuspended(user.uid).listen((suspended) {
      if (suspended) add(const AuthSuspensionDetected());
    }, onError: (_) {});
  }

  void _stopWatching() {
    _suspensionSub?.cancel();
    _suspensionSub = null;
  }

  /// Signs a suspended [user] out. Returns true when it did.
  Future<bool> _rejectIfSuspended(AppUser user, Emitter<AuthState> emit) async {
    if (!user.isSuspended) return false;
    _stopWatching();
    await _repository.signOut();
    emit(const AuthSuspended());
    return true;
  }

  Future<void> _onSuspensionDetected(
    AuthSuspensionDetected event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated && state is! AuthEmailNotVerified) return;
    _stopWatching();
    await _repository.signOut();
    emit(const AuthSuspended());
  }

  /// Repository errors arrive as `Exception(message)`; anything else (a raw
  /// FirebaseException, etc.) must not leak its technical text to the UI.
  static String _friendly(Object e) {
    final text = e.toString();
    if (e is Exception && text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Future<void> close() {
    _suspensionSub?.cancel();
    return super.close();
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final user = await _repository.currentUser();
    if (user == null) {
      emit(const AuthUnauthenticated());
    } else if (await _rejectIfSuspended(user, emit)) {
      return;
    } else if (!user.emailVerified) {
      emit(AuthEmailNotVerified(user));
      _watchSuspension(user);
    } else {
      emit(AuthAuthenticated(user));
      _watchSuspension(user);
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
      if (await _rejectIfSuspended(user, emit)) return;
      emit(user.emailVerified ? AuthAuthenticated(user) : AuthEmailNotVerified(user));
      _watchSuspension(user);
    } catch (e) {
      emit(AuthOperationFailure(_friendly(e)));
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
        ageConfirmed: event.ageConfirmed,
      );
      // Freshly created accounts are always unverified.
      emit(AuthEmailNotVerified(user));
      _watchSuspension(user);
    } on EmailAlreadyRegisteredException catch (e) {
      emit(AuthEmailAlreadyRegistered(email: event.email, verified: e.verified));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthOperationFailure(_friendly(e)));
      emit(const AuthUnauthenticated());
    }
  }

  /// Deletes the pending, unverified account (profile + Auth user) so the
  /// user can edit their details and register again. Returns false on failure.
  Future<bool> deletePendingAccount() async {
    try {
      await _repository.deleteUnverifiedAccount();
    } catch (_) {
      return false;
    }
    add(const AuthSignOutRequested());
    return true;
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _stopWatching();
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
      emit(const AuthVerificationEmailResent());
      emit(current);
    } catch (e) {
      emit(AuthOperationFailure(_friendly(e)));
      emit(current);
    }
  }

  Future<void> _onVerificationCheckRequested(
    AuthEmailVerificationCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! AuthEmailNotVerified) return;
    final bool verified;
    try {
      verified = await _repository.reloadAndCheckEmailVerified();
    } catch (e) {
      emit(const AuthOperationFailure('Could not check verification. Try again.'));
      emit(current);
      return;
    }
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
            status: current.user.status,
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
      emit(AuthOperationFailure(_friendly(e)));
      emit(const AuthUnauthenticated());
    }
  }
}
