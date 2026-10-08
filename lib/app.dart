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

final _navigatorKey = GlobalKey<NavigatorState>();

/// How long the splash waits for an unresolved auth check before falling
/// back to onboarding.
const authResolveTimeout = Duration(seconds: 8);

class RentEaseApp extends StatelessWidget {
  const RentEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // An admin suspended the user while the app was open: the bloc has
      // signed them out, so send them to sign-in (which shows the notice).
      // Not at app start - the splash routes there itself.
      listenWhen: (prev, curr) =>
          curr is AuthSuspended &&
          (prev is AuthAuthenticated || prev is AuthEmailNotVerified),
      listener: (_, _) => _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRouter.signIn,
        (_) => false,
      ),
      child: _themedApp(),
    );
  }

  Widget _themedApp() {
    return BlocBuilder<AppThemeCubit, bool>(
      builder: (_, isDark) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'RentEase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        navigatorObservers: [AppRouter.routeObserver],
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

  Future<void> _routeAfterSplash(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final AuthState resolved;
    final current = bloc.state;
    // On a slow network the auth check can still be running when the splash
    // ends; wait for it to resolve (bounded) instead of misrouting.
    if (current is AuthLoading || current is AuthInitial) {
      resolved = await bloc.stream
          .firstWhere((s) => s is! AuthLoading && s is! AuthInitial)
          .timeout(
            authResolveTimeout,
            onTimeout: () => const AuthUnauthenticated(),
          );
      if (!context.mounted) return;
    } else {
      resolved = current;
    }
    final state = resolved;
    // Admins are created in the console and never go through email
    // verification, so they route home whichever auth state they resolve to.
    final user = switch (state) {
      AuthAuthenticated(:final user) => user,
      AuthEmailNotVerified(:final user) when user.isAdmin => user,
      _ => null,
    };
    if (user != null) {
      final route = await AppRouter.postAuthRouteFor(user);
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (_) => false,
      );
    } else if (state is AuthEmailNotVerified && !state.user.isAdmin) {
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
      onSignIn: (user) async {
        final route = await AppRouter.postAuthRouteFor(user);
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          route,
          (_) => false,
        );
      },
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EmailVerificationScreen(
          isOwner: role == UserRole.landlord,
        ),
      ),
    );
  }
}
