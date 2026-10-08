import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/constants/app_strings.dart';
import '../../../../core/firestore/models/user_contact_doc.dart';
import '../../../../core/firestore/models/user_doc.dart';
import '../../domain/entities/auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthRemoteDataSource? remote})
      : _remote = remote ?? AuthRemoteDataSource();

  final AuthRemoteDataSource _remote;

  @override
  Future<AppUser?> currentUser() async {
    final fbUser = _remote.currentFirebaseUser;
    if (fbUser == null) return null;
    return _toAppUser(fbUser);
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _remote.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _toAppUser(fbUser);
    });
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String phone,
    required String role,
    bool ageConfirmed = false,
  }) async {
    if (!ageConfirmed) {
      throw Exception(AppStrings.ageConfirmationRequired);
    }
    try {
      final credential = await _remote.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;

      await _remote.createUserDoc(
        UserDoc(
          userId: fbUser.uid,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          role: role,
          status: 'active',
          confirmAgeNow: true,
        ),
        // Email + phone go to the private doc only (same batch).
        contact: UserContactDoc(phone: phone, email: email),
      );

      await _remote.sendEmailVerification();

      return AppUser(
        uid: fbUser.uid,
        email: email,
        role: role,
        emailVerified: fbUser.emailVerified,
        firstName: firstName,
        lastName: lastName,
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Abandoned, unverified signup of this same person? Clear it and
        // register again; otherwise this throws EmailAlreadyRegistered.
        await _clearAbandonedSignUp(email: email, password: password);
        return signUp(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          phone: phone,
          role: role,
          ageConfirmed: ageConfirmed,
        );
      }
      throw Exception(_messageForAuthError(e));
    }
  }

  /// Called when the email is taken. Signs in with the password just typed:
  /// - unverified (and not an admin) → it's a leftover signup; delete it.
  /// - verified / admin → real account; sign out and report it.
  /// - wrong password → can't tell whose it is; report it.
  Future<void> _clearAbandonedSignUp({
    required String email,
    required String password,
  }) async {
    final fb.User user;
    try {
      user = (await _remote.signInWithEmailAndPassword(
        email: email,
        password: password,
      ))
          .user!;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-not-found') {
        throw const EmailAlreadyRegisteredException(verified: false);
      }
      throw Exception(_messageForAuthError(e));
    }
    final doc = await _remote.fetchUserDoc(user.uid);
    if (user.emailVerified || doc?.role == 'admin') {
      await _remote.signOut();
      throw const EmailAlreadyRegisteredException(verified: true);
    }
    try {
      await _remote.deleteCurrentAccountAndProfile();
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_messageForAuthError(e));
    }
  }

  @override
  Future<void> deleteUnverifiedAccount() =>
      _remote.deleteCurrentAccountAndProfile();

  @override
  Stream<bool> watchSuspended(String uid) => _remote.watchUserStatus(uid).map(
    (status) => status == 'suspended',
  );

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _remote.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;
      // Best-effort: a failed timestamp write (missing doc, rules, offline)
      // must not fail a sign-in that already succeeded.
      try {
        await _remote.touchLastLogin(fbUser.uid);
      } catch (_) {}
      return _toAppUser(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_messageForAuthError(e));
    }
  }

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> sendEmailVerification() => _remote.sendEmailVerification();

  @override
  Future<bool> reloadAndCheckEmailVerified() async {
    final fbUser = await _remote.reloadCurrentUser();
    return fbUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _remote.sendPasswordResetEmail(email);
    } on fb.FirebaseAuthException catch (e) {
      // Same outcome whether or not the email is registered (no enumeration).
      if (e.code == 'user-not-found') return;
      throw Exception(_messageForAuthError(e));
    }
  }

  Future<AppUser> _toAppUser(fb.User fbUser) async {
    final doc = await _remote.fetchUserDoc(fbUser.uid);
    if (doc != null && doc.hasLegacyContact) {
      // Best effort and never blocks sign-in: a failure (offline, rules,
      // suspended) just retries on the next sign-in / app start.
      try {
        await _remote.migrateLegacyContact(doc);
      } catch (_) {}
    }
    if (doc != null && doc.role == 'tenant') {
      try {
        await _remote.migrateLegacyEmergencyContact(fbUser.uid);
      } catch (_) {}
      // Map pin + weights move to the owner-hidden private prefs doc.
      try {
        await _remote.migrateLegacyTenantPrefs(fbUser.uid);
      } catch (_) {}
    }
    return AppUser(
      uid: fbUser.uid,
      email: fbUser.email ?? doc?.email ?? '',
      role: doc?.role ?? '',
      emailVerified: fbUser.emailVerified,
      firstName: doc?.firstName,
      lastName: doc?.lastName,
      status: doc?.status ?? 'active',
    );
  }

  String _messageForAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      // One message for every bad-credential code so the response never
      // reveals whether an email is registered.
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
