import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/analytics_cubit.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/users_cubit.dart';
import '../cubit/verifications_cubit.dart';
import '../data/repositories/admin_repository_impl.dart';
import '../domain/repositories/admin_repository.dart';

/// Provides the admin repository and the four admin cubits to [child].
/// Pass [repository] in tests / previews to avoid touching Firebase.
class AdminProviders extends StatelessWidget {
  const AdminProviders({required this.child, this.repository, super.key});

  final Widget child;
  final AdminRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository;
    final providers = <BlocProvider>[
      BlocProvider<AnalyticsCubit>(
        create: (c) => AnalyticsCubit(c.read<AdminRepository>())..start(),
      ),
      BlocProvider<VerificationsCubit>(
        create: (c) => VerificationsCubit(c.read<AdminRepository>())..start(),
      ),
      BlocProvider<UsersCubit>(
        create: (c) => UsersCubit(c.read<AdminRepository>())..start(),
      ),
      BlocProvider<AdminPropertiesCubit>(
        create: (c) => AdminPropertiesCubit(c.read<AdminRepository>())..start(),
      ),
    ];
    final tree = MultiBlocProvider(providers: providers, child: child);
    return repo != null
        ? RepositoryProvider<AdminRepository>.value(value: repo, child: tree)
        : RepositoryProvider<AdminRepository>(
            create: (_) => AdminRepositoryImpl(),
            child: tree,
          );
  }
}
