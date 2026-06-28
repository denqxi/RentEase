import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

<<<<<<< Updated upstream
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'features/auth/view/sign_in_entry.dart';
import 'features/onboarding/view/onboarding_screen.dart';

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
      onGenerateRoute: onGenerateRoute,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      // Builder gives a context below the Navigator so onboarding can route.
      home: Builder(
        builder: (context) => OnboardingScreen(
          onComplete: () => _push(context, const SignInEntry()),
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

=======
import 'app.dart';
import 'core/cubit/app_theme_cubit.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => AppThemeCubit(),
      child: const RentEaseApp(),
    ),
  );
}
>>>>>>> Stashed changes
