part of 'shell_cubit.dart';

/// Navigation tab destinations. Tenant shell uses home/search/inquiries/profile.
/// Landlord shell reuses all 5 slots (extra = 5th tab).
enum ShellTab { home, search, inquiries, profile, extra }

/// State for [ShellCubit] — tracks which tab is active.
class ShellState extends Equatable {
  const ShellState({this.tab = ShellTab.home});

  final ShellTab tab;

  ShellState copyWith({ShellTab? tab}) => ShellState(tab: tab ?? this.tab);

  @override
  List<Object?> get props => <Object?>[tab];
}
