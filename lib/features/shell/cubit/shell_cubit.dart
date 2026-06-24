import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shell_state.dart';

/// Manages the active bottom-navigation tab for [MainShell].
class ShellCubit extends Cubit<ShellState> {
  ShellCubit() : super(const ShellState());

  /// Switches to [tab].
  void selectTab(ShellTab tab) => emit(state.copyWith(tab: tab));
}
