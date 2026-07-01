import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/activity/model/activity_item.dart';
import '../../../features/registration/model/user_role.dart';
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
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider>[
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
        BlocProvider<ActivityCubit>(
          create: (_) => ActivityCubit(initialItems: ActivityItem.samples),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) => ProfileCubit(userRole: UserRole.tenant),
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
        onTap: (i) => context.read<ShellCubit>().selectTab(ShellTab.values[i]),
      ),
    );
  }
}
