import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../inquiry/domain/repositories/inquiry_repository.dart';
import '../../registration/model/user_role.dart';

part 'profile_state.dart';

/// Holds the signed-in user's profile header data (real name, photo) and
/// live inquiry count. Without a [repository]/[uid] (guests, offline
/// harnesses) it only carries the role.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    UserRole userRole = UserRole.tenant,
    String? uid,
    InquiryRepository? repository,
  }) : super(ProfileState(userRole: userRole)) {
    if (uid != null && repository != null) _start(uid, repository);
  }

  StreamSubscription<dynamic>? _inquiriesSub;

  void _start(String uid, InquiryRepository repository) {
    repository
        .fetchUser(uid)
        .then((user) {
          if (isClosed || user == null) return;
          final full = [
            user.firstName,
            user.lastName,
          ].where((s) => s.trim().isNotEmpty).join(' ');
          emit(state.copyWith(fullName: full, photoUrl: user.profilePhoto));
        })
        .catchError((Object _) {
          // The header falls back to a neutral name; not worth a banner.
        });
    _inquiriesSub = repository
        .watchTenantInquiries(uid)
        .listen(
          (inquiries) => emit(state.copyWith(inquiryCount: inquiries.length)),
          onError: (Object _) {},
        );
  }

  @override
  Future<void> close() {
    _inquiriesSub?.cancel();
    return super.close();
  }
}
