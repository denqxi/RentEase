import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';

/// Shows [child] only for an authenticated admin. Everyone else is redirected
/// (signed-out -> admin login, other roles -> their own home) without ever
/// building admin content. While auth is still resolving it shows a spinner.
class AdminOnlyGate extends StatefulWidget {
  const AdminOnlyGate({required this.child, super.key});

  final Widget child;

  @override
  State<AdminOnlyGate> createState() => _AdminOnlyGateState();
}

class _AdminOnlyGateState extends State<AdminOnlyGate> {
  bool _redirected = false;

  static bool _isAdmin(AuthState s) =>
      (s is AuthAuthenticated && s.user.isAdmin) ||
      (s is AuthEmailNotVerified && s.user.isAdmin);

  static bool _isPending(AuthState s) => s is AuthLoading || s is AuthInitial;

  void _redirect(AuthState state) {
    if (_redirected || !mounted) return;
    if (_isAdmin(state) || _isPending(state)) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    _redirected = true;
    final target = switch (state) {
      AuthAuthenticated(:final user) =>
        AppRouter.homeRouteFor(isAdmin: user.isAdmin, isOwner: user.isOwner),
      AuthEmailNotVerified(:final user) =>
        AppRouter.homeRouteFor(isAdmin: user.isAdmin, isOwner: user.isOwner),
      _ => AppRouter.adminLogin,
    };
    Navigator.of(context).pushReplacementNamed(target);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) => _redirect(state),
      builder: (context, state) {
        if (_isAdmin(state)) return widget.child;
        if (!_isPending(state)) {
          // The listener only fires on changes; cover the state we first
          // build with.
          WidgetsBinding.instance.addPostFrameCallback((_) => _redirect(state));
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
