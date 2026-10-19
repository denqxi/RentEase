part of 'shell_cubit.dart';

/// Navigation tab destinations:
/// 0: home
/// 1: search / matches
/// 2: saved / center action
/// 3: inquiries
/// 4: profile
enum ShellTab {
  home,
  search,
  saved,
  inquiries,
  profile;

  /// Backwards-compatible aliases.
  static const ShellTab alerts = inquiries;
  static const ShellTab extra = profile;
}

/// State for [ShellCubit] — tracks which tab is active.
class ShellState extends Equatable {
  const ShellState({this.tab = ShellTab.home});

  final ShellTab tab;

  ShellState copyWith({ShellTab? tab}) => ShellState(tab: tab ?? this.tab);

  @override
  List<Object?> get props => <Object?>[tab];
}
