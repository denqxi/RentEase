part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched once at app start to pick up an already-signed-in session.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.phone,
    required this.role,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;

  /// 'Female' | 'Male' — the account holder's own gender.
  final String gender;
  final String phone;

  /// 'tenant' | 'owner'.
  final String role;

  @override
  List<Object?> get props =>
      [email, password, firstName, lastName, gender, phone, role];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthEmailVerificationResendRequested extends AuthEvent {
  const AuthEmailVerificationResendRequested();
}

/// Re-checks whether the pending user has clicked the verification link.
class AuthEmailVerificationCheckRequested extends AuthEvent {
  const AuthEmailVerificationCheckRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}
