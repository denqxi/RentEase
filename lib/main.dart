import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
