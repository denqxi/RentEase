import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/registration/model/user_role.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../activity/view/activity_screen.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/current_uid.dart';
import '../../home/cubit/home_cubit.dart';
import '../../inquiry/data/repositories/inquiry_repository_impl.dart';
import '../../home/data/repositories/home_repository_impl.dart';
import '../../home/view/home_screen.dart';
import '../../home/view/search_screen.dart';
import '../../inquiry/view/tenant_inquiries_screen.dart';
import '../../matching/data/repositories/filtering_repository_impl.dart';
import '../../matching/data/repositories/topsis_repository_impl.dart';
import '../../matching/domain/services/filtering_service.dart';
import '../../matching/domain/services/topsis_service.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/view/profile_screen.dart';
import '../cubit/shell_cubit.dart';
import '../widgets/floating_nav_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({this.sessionRole = UserRole.tenant, super.key});

  final UserRole sessionRole;

  @override
  Widget build(BuildContext context) {
    final isGuest = sessionRole == UserRole.guest;

    return MultiBlocProvider(
      providers: <BlocProvider>[
        BlocProvider<HomeCubit>(
          create: (_) {
            if (isGuest) {
              return HomeCubit.guest(repository: HomeRepositoryImpl());
            }
            // MainShell is only ever reached once AuthBloc has confirmed a
            // signed-in tenant (see AppRouter/app.dart routing) for the
            // non-guest path, so this is always available.
            final authState = context.read<AuthBloc>().state;
            final tenantId = switch (authState) {
              AuthAuthenticated(:final user) => user.uid,
              AuthEmailNotVerified(:final user) => user.uid,
              _ => '',
            };
            return HomeCubit(
              tenantId: tenantId,
              repository: HomeRepositoryImpl(),
              filteringService: FilteringService(repository: FilteringRepositoryImpl()),
              topsisService: TopsisService(repository: TopsisRepositoryImpl()),
            );
          },
        ),
        BlocProvider<ActivityCubit>(
          create: (ctx) {
            final uid = isGuest ? null : currentUidOrNull(ctx);
            if (uid == null) return ActivityCubit();
            return ActivityCubit(
              repository: NotificationRepositoryImpl(),
              uid: uid,
            );
          },
        ),
        BlocProvider<ProfileCubit>(
          create: (ctx) {
            final uid = isGuest ? null : currentUidOrNull(ctx);
            if (uid == null) return ProfileCubit(userRole: sessionRole);
            return ProfileCubit(
              userRole: sessionRole,
              uid: uid,
              repository: InquiryRepositoryImpl(),
            );
          },
        ),
        BlocProvider<ShellCubit>(create: (_) => ShellCubit()),
      ],
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatelessWidget {
  const _ShellView();

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    SearchScreen(),
    TenantInquiriesScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  static List<FloatingNavBarItem> _items(int unread) => <FloatingNavBarItem>[
    const FloatingNavBarItem(icon: Icons.home_rounded, label: 'Home'),
    const FloatingNavBarItem(icon: Icons.search_rounded, label: 'Search'),
    const FloatingNavBarItem(
      icon: Icons.chat_bubble_rounded,
      label: 'Inquiries',
    ),
    FloatingNavBarItem(
      icon: Icons.notifications_rounded,
      label: 'Alerts',
      badgeCount: unread,
    ),
    const FloatingNavBarItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellCubit>().state.tab;
    final unread = context.select<ActivityCubit, int>(
      (c) => c.state.unreadCount,
    );

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: tab.index,
        children: _screens,
      ),
      bottomNavigationBar: FloatingNavBar(
        items: _items(unread),
        selectedIndex: tab.index,
        onTap: (i) {
          final isGuest =
              context.read<ProfileCubit>().state.userRole == UserRole.guest;
          // Inquiries (2), Alerts (3), Profile (4) require an account.
          if (isGuest && i >= 2) {
            GuestAccessSheet.show(context);
            return;
          }
          context.read<ShellCubit>().selectTab(ShellTab.values[i]);
        },
      ),
    );
  }
}
