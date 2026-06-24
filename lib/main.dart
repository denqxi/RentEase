import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/registration/model/user_role.dart';
import 'features/registration/view/registration_flow_screen.dart';
import 'features/shell/view/landlord_shell.dart';
import 'features/shell/view/main_shell.dart';

void main() {
  runApp(const RentEaseApp());
}

/// Root application widget.
class RentEaseApp extends StatelessWidget {
  const RentEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      // Builder gives a context below the Navigator so onboarding can route.
      home: Builder(
        builder: (context) => OnboardingScreen(
          onComplete: () => _push(context, const _SignInEntry()),
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

/// Wires [SignInScreen] so "Create an account" opens registration and both
/// successful paths forward to [MainShell].
class _SignInEntry extends StatelessWidget {
  const _SignInEntry();

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
