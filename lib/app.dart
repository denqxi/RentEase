import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/cubit/app_theme_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'features/registration/model/user_role.dart';
import 'features/registration/view/registration_flow_screen.dart';

class RentEaseApp extends StatelessWidget {
  const RentEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, bool>(
      builder: (_, isDark) => MaterialApp(
        title: 'RentEase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: Builder(
          builder: (ctx) => SplashScreen(
            onComplete: () => Navigator.of(ctx).pushReplacement(
              MaterialPageRoute<void>(
                builder: (onboardingCtx) => OnboardingScreen(
                  onComplete: () => Navigator.of(onboardingCtx).push(
                    MaterialPageRoute<void>(builder: (_) => const _SignInEntry()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInEntry extends StatelessWidget {
  const _SignInEntry();

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      onSignIn: () => Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.roleSelection,
        (_) => false,
      ),
      onCreateAccount: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RegistrationFlowScreen(
            onComplete: (role) => _pushOnboarding(context, role),
            onSignIn: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _pushOnboarding(BuildContext context, UserRole role) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.verifyEmail,
      (_) => false,
      arguments: role == UserRole.landlord,
    );
  }
}
