import 'package:flutter_bloc/flutter_bloc.dart';

class AppThemeCubit extends Cubit<bool> {
  AppThemeCubit() : super(false);
  void toggle() => emit(!state);
}
