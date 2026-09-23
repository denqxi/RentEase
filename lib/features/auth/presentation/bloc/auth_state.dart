part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Nothing checked yet — shown only for the instant before
/// [AuthCheckRequested] resolves.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Signed in, email verified, role loaded — safe to route to the app.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// Signed in (or just signed up) but the email link hasn't been clicked
/// yet — CLAUDE.md's registration flow gates onboarding behind this.
class AuthEmailNotVerified extends AuthState {
  const AuthEmailNotVerified(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// A sign-in/sign-up/reset attempt failed. Transient — the UI shows the
/// message once, then the bloc falls back to [AuthUnauthenticated].
class AuthOperationFailure extends AuthState {
  const AuthOperationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetEmailSent extends AuthState {
  const AuthPasswordResetEmailSent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
