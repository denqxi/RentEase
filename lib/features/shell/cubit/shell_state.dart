part of 'shell_cubit.dart';

/// The five main navigation destinations.
enum ShellTab { home, matches, saved, alerts, profile }

/// State for [ShellCubit] — tracks which tab is active.
class ShellState extends Equatable {
  const ShellState({this.tab = ShellTab.home});

  final ShellTab tab;

  ShellState copyWith({ShellTab? tab}) => ShellState(tab: tab ?? this.tab);

  @override
  List<Object?> get props => <Object?>[tab];
}
