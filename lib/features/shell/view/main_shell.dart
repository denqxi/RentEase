import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/activity/model/activity_item.dart';
import '../../../features/registration/model/user_role.dart';
import '../../../shared/widgets/guest_access_sheet.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../activity/view/activity_screen.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/view/home_screen.dart';
import '../../home/view/search_screen.dart';
import '../../inquiry/view/tenant_inquiries_screen.dart';
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
        BlocProvider<HomeCubit>(create: (_) => HomeCubit(isGuest: isGuest)),
        BlocProvider<ActivityCubit>(
          create: (_) => ActivityCubit(initialItems: ActivityItem.samples),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) => ProfileCubit(userRole: sessionRole),
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

  static const List<FloatingNavBarItem> _items = <FloatingNavBarItem>[
    FloatingNavBarItem(icon: Icons.home_rounded,       label: 'Home'),
    FloatingNavBarItem(icon: Icons.search_rounded,     label: 'Search'),
    FloatingNavBarItem(icon: Icons.chat_bubble_rounded, label: 'Inquiries'),
    FloatingNavBarItem(icon: Icons.notifications_rounded, label: 'Alerts'),
    FloatingNavBarItem(icon: Icons.person_rounded,     label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellCubit>().state.tab;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: tab.index,
        children: _screens,
      ),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
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
