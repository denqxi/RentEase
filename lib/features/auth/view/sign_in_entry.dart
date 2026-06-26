import 'package:flutter/material.dart';

import '../../../features/registration/model/user_role.dart';
import '../../../features/registration/view/registration_flow_screen.dart';
import '../../../features/shell/view/landlord_shell.dart';
import '../../../features/shell/view/main_shell.dart';
import '../presentation/screens/auth_screen.dart';

/// Wires [SignInScreen] so "Create an account" opens registration and both
/// successful paths forward to the correct shell.
class SignInEntry extends StatelessWidget {
  const SignInEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      onCreateAccount: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationFlowScreen(
            onComplete: (role) => _pushShell(context, role),
            onSignIn: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _pushShell(BuildContext context, UserRole role) {
    final shell = role == UserRole.landlord
        ? const LandlordShell()
        : const MainShell();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => shell),
      (route) => false,
    );
  }
}
