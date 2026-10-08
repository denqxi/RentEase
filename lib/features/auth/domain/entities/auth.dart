import 'package:equatable/equatable.dart';

/// The authenticated app user — merges the Firebase Auth identity with the
/// `users/{uid}` Firestore role, which is permanent after signup (see
/// CLAUDE.md "Role is Permanent").
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.firstName,
    this.lastName,
    this.status = 'active',
  });

  final String uid;
  final String email;

  /// 'tenant' | 'owner' | 'admin'.
  final String role;
  final bool emailVerified;
  final String? firstName;
  final String? lastName;

  /// `users.status`: 'active' | 'pending' | 'suspended' (admin-controlled).
  final String status;

  bool get isTenant => role == 'tenant';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isSuspended => status == 'suspended';

  @override
  List<Object?> get props =>
      [uid, email, role, emailVerified, firstName, lastName, status];
}

/// Sign-up hit an email that already has an account which could not be
/// resumed. [verified] is true when the signed-in check proved the account is
/// a real, verified one; false when the password didn't match (unknown).
class EmailAlreadyRegisteredException implements Exception {
  const EmailAlreadyRegisteredException({required this.verified});

  final bool verified;
}
