import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/cubit/app_theme_cubit.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/matching/data/repositories/filtering_repository_impl.dart';
import 'features/matching/data/repositories/topsis_repository_impl.dart';
import 'features/matching/domain/services/filtering_service.dart';
import 'features/matching/domain/services/topsis_service.dart';
import 'features/tenant_onboarding/cubit/tenant_onboarding_cubit.dart';
import 'features/tenant_onboarding/data/repositories/tenant_profile_repository_impl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppThemeCubit()),
        BlocProvider(
          create: (_) => AuthBloc(repository: AuthRepositoryImpl())
            ..add(const AuthCheckRequested()),
        ),
        // Tenant onboarding spans five pushed routes, so its draft lives
        // above the Navigator rather than in any one screen.
        BlocProvider(
          create: (_) => TenantOnboardingCubit(
            repository: TenantProfileRepositoryImpl(),
            filteringService: FilteringService(
              repository: FilteringRepositoryImpl(),
            ),
            topsisService: TopsisService(
              repository: TopsisRepositoryImpl(),
            ),
          ),
        ),
      ],
      child: const RentEaseApp(),
    ),
  );
}
