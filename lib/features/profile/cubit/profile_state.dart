part of 'profile_cubit.dart';

/// State for [ProfileCubit].
class ProfileState extends Equatable {
  const ProfileState({this.userRole = UserRole.tenant});

  final UserRole userRole;

  ProfileState copyWith({UserRole? userRole}) {
    return ProfileState(userRole: userRole ?? this.userRole);
  }

  @override
  List<Object?> get props => <Object?>[userRole];
}
