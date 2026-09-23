import '../entities/auth.dart';

/// Contract for authentication + the `users/{uid}` account record.
///
/// Implementations throw a plain [Exception] with a user-readable message on
/// failure (see [AuthRepositoryImpl]'s Firebase error mapping) — callers
/// (the auth bloc) catch and surface `error.toString()`-safe messages.
abstract class AuthRepository {
  /// The currently signed-in Firebase user, if any, mapped with the role
  /// looked up from Firestore. Null when signed out.
  Future<AppUser?> currentUser();

  /// Fires whenever the underlying Firebase auth state changes. Emits `null`
  /// on sign-out.
  Stream<AppUser?> authStateChanges();

  /// Creates the Firebase Auth account, writes the `users/{uid}` document
  /// (role is set once here and never changes — CLAUDE.md rule 4), and
  /// triggers the verification email.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String phone,
    required String role,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  /// Re-sends the verification email to the currently signed-in user.
  Future<void> sendEmailVerification();

  /// Reloads the current user from Firebase and returns the fresh
  /// `emailVerified` flag.
  Future<bool> reloadAndCheckEmailVerified();

  Future<void> sendPasswordResetEmail({required String email});
}
