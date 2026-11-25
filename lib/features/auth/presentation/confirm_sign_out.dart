import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import 'bloc/auth_bloc.dart';

/// For the back button on a screen that is the only route: going back means
/// signing out, so ask first.
Future<void> confirmSignOutToSignIn(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: const Text('Sign out?'),
      content: const Text(
        "You'll go back to the sign-in screen, where you can use another "
        'account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Stay'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  if (leave != true || !context.mounted) return;
  context.read<AuthBloc>().add(const AuthSignOutRequested());
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRouter.signIn, (_) => false);
}
