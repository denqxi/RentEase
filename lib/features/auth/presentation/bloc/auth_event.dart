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
    this.ageConfirmed = false,
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

  /// The user ticked "I am at least 18 and have read the Privacy Notice".
  final bool ageConfirmed;

  @override
  List<Object?> get props =>
      [email, password, firstName, lastName, gender, phone, role, ageConfirmed];
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

/// Internal: the signed-in user's users doc turned `suspended` while the app
/// was open (see [AuthRepository.watchSuspended]).
class AuthSuspensionDetected extends AuthEvent {
  const AuthSuspensionDetected();
}
