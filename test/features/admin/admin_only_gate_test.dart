import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/features/admin/widgets/admin_only_gate.dart';
import 'package:rentease/features/auth/domain/entities/auth.dart';
import 'package:rentease/features/auth/domain/repositories/auth_repository.dart';
import 'package:rentease/features/auth/presentation/bloc/auth_bloc.dart';

class _Repo implements AuthRepository {
  _Repo(this.user);
  final AppUser? user;

  @override
  Future<AppUser?> currentUser() async => user;

  @override
  Stream<bool> watchSuspended(String uid) => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

AppUser _u(String role) => AppUser(
      uid: 'u',
      email: 'a@b.com',
      role: role,
      emailVerified: true,
      status: 'active',
    );

Future<void> _pump(WidgetTester t, AppUser? user) async {
  final bloc = AuthBloc(repository: _Repo(user))
    ..add(const AuthCheckRequested());
  addTearDown(bloc.close);
  await t.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        onGenerateRoute: (s) => MaterialPageRoute<void>(
          settings: s,
          builder: (_) => s.name == '/'
              ? const AdminOnlyGate(child: Text('ADMIN CONTENT'))
              : Text('ROUTE ${s.name}'),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('admin sees content', (t) async {
    await _pump(t, _u('admin'));
    expect(find.text('ADMIN CONTENT'), findsOneWidget);
  });

  testWidgets('tenant is redirected home, never sees content', (t) async {
    await _pump(t, _u('tenant'));
    expect(find.text('ADMIN CONTENT'), findsNothing);
    expect(find.text('ROUTE /tenant/home'), findsOneWidget);
  });

  testWidgets('signed-out goes to admin login', (t) async {
    await _pump(t, null);
    expect(find.text('ADMIN CONTENT'), findsNothing);
    expect(find.text('ROUTE /admin/login'), findsOneWidget);
  });
}
