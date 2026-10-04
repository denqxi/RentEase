part of 'profile_cubit.dart';

/// State for [ProfileCubit].
class ProfileState extends Equatable {
  const ProfileState({
    this.userRole = UserRole.tenant,
    this.fullName = '',
    this.photoUrl,
    this.inquiryCount = 0,
  });

  final UserRole userRole;
  final String fullName;
  final String? photoUrl;
  final int inquiryCount;

  ProfileState copyWith({
    UserRole? userRole,
    String? fullName,
    String? photoUrl,
    int? inquiryCount,
  }) {
    return ProfileState(
      userRole: userRole ?? this.userRole,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      inquiryCount: inquiryCount ?? this.inquiryCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    userRole,
    fullName,
    photoUrl,
    inquiryCount,
  ];
}
