import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/auth/domain/entities/auth.dart';
import 'package:rentease/features/auth/domain/repositories/auth_repository.dart';
import 'package:rentease/features/auth/presentation/bloc/auth_bloc.dart';

class _Repo implements AuthRepository {
  _Repo({this.failResend = false});
  final bool failResend;
  final user = const AppUser(
    uid: 'u',
    email: 'a@b.com',
    role: 'tenant',
    emailVerified: false,
    status: 'active',
  );

  @override
  Future<AppUser?> currentUser() async => user;

  @override
  Stream<bool> watchSuspended(String uid) => const Stream.empty();

  @override
  Future<void> sendEmailVerification() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failResend) throw Exception('boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('resend success emits Resent only (no failure)', () async {
    final bloc = AuthBloc(repository: _Repo())..add(const AuthCheckRequested());
    await bloc.stream.firstWhere((s) => s is AuthEmailNotVerified);
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const AuthEmailVerificationResendRequested());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(states.first, isA<AuthVerificationEmailResent>());
    expect(states.whereType<AuthOperationFailure>(), isEmpty);
    await sub.cancel();
    await bloc.close();
  });

  test('resend failure emits failure and never Resent', () async {
    final bloc = AuthBloc(repository: _Repo(failResend: true))
      ..add(const AuthCheckRequested());
    await bloc.stream.firstWhere((s) => s is AuthEmailNotVerified);
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const AuthEmailVerificationResendRequested());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(states.whereType<AuthVerificationEmailResent>(), isEmpty);
    expect(states.first, isA<AuthOperationFailure>());
    await sub.cancel();
    await bloc.close();
  });
}
