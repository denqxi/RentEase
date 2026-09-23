import 'package:firebase_auth/firebase_auth.dart' as fb;

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
  }) async {
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
          email: email,
          gender: gender,
          phone: phone,
          role: role,
          status: 'active',
        ),
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
      throw Exception(_messageForAuthError(e));
    }
  }

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
      await _remote.touchLastLogin(fbUser.uid);
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
      throw Exception(_messageForAuthError(e));
    }
  }

  Future<AppUser> _toAppUser(fb.User fbUser) async {
    final doc = await _remote.fetchUserDoc(fbUser.uid);
    return AppUser(
      uid: fbUser.uid,
      email: fbUser.email ?? doc?.email ?? '',
      role: doc?.role ?? '',
      emailVerified: fbUser.emailVerified,
      firstName: doc?.firstName,
      lastName: doc?.lastName,
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
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found for that email and password.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
