import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../registration/model/user_role.dart';

part 'profile_state.dart';

/// Manages user profile settings (dark mode toggle, etc.).
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({UserRole userRole = UserRole.tenant})
      : super(ProfileState(userRole: userRole));
}
