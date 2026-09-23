import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/cubit/app_theme_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/email_verification_screen.dart';
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
            // AuthCheckRequested was dispatched at app start (main.dart); by
            // the time the splash animation finishes it has resolved, so we
            // can route straight past onboarding/sign-in for a returning,
            // already-verified user instead of always restarting the flow.
            onComplete: () => _routeAfterSplash(ctx),
          ),
        ),
      ),
    );
  }

  void _routeAfterSplash(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        state.user.isOwner ? AppRouter.landlordHome : AppRouter.tenantHome,
        (_) => false,
      );
    } else if (state is AuthEmailNotVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              EmailVerificationScreen(isOwner: state.user.isOwner),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (onboardingCtx) => OnboardingScreen(
            onComplete: () => Navigator.of(onboardingCtx).push(
              MaterialPageRoute<void>(builder: (_) => const _SignInEntry()),
            ),
          ),
        ),
      );
    }
  }
}

class _SignInEntry extends StatelessWidget {
  const _SignInEntry();

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      // Pushed directly on the app's single root Navigator (via the named
      // routes AppRouter already handles) rather than through a second
      // nested Navigator — a nested one only knows its initial route, so any
      // later pushNamed from inside the shell (e.g. the profile screen's
      // Log out button) would silently fail to resolve.
      onSignIn: (user) => Navigator.of(context).pushNamedAndRemoveUntil(
        user.isOwner ? AppRouter.landlordHome : AppRouter.tenantHome,
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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => EmailVerificationScreen(
          isOwner: role == UserRole.landlord,
        ),
      ),
      (_) => false,
    );
  }
}
