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
  });

  final String uid;
  final String email;

  /// 'tenant' | 'owner' | 'admin'.
  final String role;
  final bool emailVerified;
  final String? firstName;
  final String? lastName;

  bool get isTenant => role == 'tenant';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props =>
      [uid, email, role, emailVerified, firstName, lastName];
}
