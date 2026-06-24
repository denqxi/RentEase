part of 'profile_cubit.dart';

/// State for [ProfileCubit].
class ProfileState extends Equatable {
  const ProfileState({
    this.darkMode = false,
    this.userRole = UserRole.tenant,
  });

  final bool darkMode;
  final UserRole userRole;

  ProfileState copyWith({bool? darkMode, UserRole? userRole}) {
    return ProfileState(
      darkMode: darkMode ?? this.darkMode,
      userRole: userRole ?? this.userRole,
    );
  }

  @override
  List<Object?> get props => <Object?>[darkMode, userRole];
}
