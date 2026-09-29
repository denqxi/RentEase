import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth_bloc.dart';

/// The signed-in user's uid, whether or not their email is verified yet —
/// or null when signed out, or when no [AuthBloc] is above [context] (the
/// offline screenshot harnesses render screens without one).
String? currentUidOrNull(BuildContext context) {
  try {
    return switch (context.read<AuthBloc>().state) {
      AuthAuthenticated(:final user) => user.uid,
      AuthEmailNotVerified(:final user) => user.uid,
      _ => null,
    };
  } on ProviderNotFoundException {
    return null;
  }
}
