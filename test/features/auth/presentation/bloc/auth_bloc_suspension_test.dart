import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/auth/domain/entities/auth.dart';
import 'package:rentease/features/auth/domain/repositories/auth_repository.dart';
import 'package:rentease/features/auth/presentation/bloc/auth_bloc.dart';

AppUser _user({String status = 'active', bool verified = true}) => AppUser(
  uid: 'u1',
  email: 'a@b.com',
  role: 'tenant',
  emailVerified: verified,
  status: status,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  AppUser? user;
  final suspended = StreamController<bool>.broadcast();
  int signOuts = 0;

  @override
  Future<AppUser?> currentUser() async => user;

  @override
  Future<AppUser> signIn({required String email, required String password}) async =>
      user!;

  @override
  Stream<bool> watchSuspended(String uid) => suspended.stream;

  @override
  Future<void> signOut() async => signOuts++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('app start with a suspended user signs out and reports AuthSuspended', () async {
    final repo = _FakeAuthRepository(_user(status: 'suspended'));
    final bloc = AuthBloc(repository: repo)..add(const AuthCheckRequested());

    await expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthSuspended>()]),
    );
    expect(repo.signOuts, 1);
    await bloc.close();
  });

  test('signing in as a suspended user is rejected', () async {
    final repo = _FakeAuthRepository(_user(status: 'suspended'));
    final bloc = AuthBloc(repository: repo)
      ..add(const AuthSignInRequested(email: 'a@b.com', password: 'secret1'));

    await expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthSuspended>()]),
    );
    expect(repo.signOuts, 1);
    await bloc.close();
  });

  test('an active user signs in normally', () async {
    final repo = _FakeAuthRepository(_user());
    final bloc = AuthBloc(repository: repo)
      ..add(const AuthSignInRequested(email: 'a@b.com', password: 'secret1'));

    await expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
    );
    expect(repo.signOuts, 0);
    await bloc.close();
  });

  test('a user suspended while the app is open is signed out live', () async {
    final repo = _FakeAuthRepository(_user());
    final bloc = AuthBloc(repository: repo)..add(const AuthCheckRequested());
    await bloc.stream.firstWhere((s) => s is AuthAuthenticated);

    repo.suspended.add(false); // still active: nothing happens
    repo.suspended.add(true);

    await bloc.stream.firstWhere((s) => s is AuthSuspended);
    expect(repo.signOuts, 1);
    await bloc.close();
  });

  test('no watching after sign-out', () async {
    final repo = _FakeAuthRepository(_user());
    final bloc = AuthBloc(repository: repo)..add(const AuthCheckRequested());
    await bloc.stream.firstWhere((s) => s is AuthAuthenticated);

    bloc.add(const AuthSignOutRequested());
    await bloc.stream.firstWhere((s) => s is AuthUnauthenticated);
    repo.suspended.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state, isA<AuthUnauthenticated>());
    expect(repo.signOuts, 1); // only the explicit sign-out
    await bloc.close();
  });

  test('the notice text is the documented message', () {
    expect(
      AuthBloc.suspendedMessage,
      'Your account has been suspended. Contact support.',
    );
  });
}
