import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../activity/cubit/activity_cubit.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../activity/view/activity_screen.dart';
import '../../auth/presentation/current_uid.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../owner/data/repositories/find_tenants_repository_impl.dart';
import '../../owner/data/repositories/owner_property_repository_impl.dart';
import '../../landlord_home/view/landlord_home_screen.dart';
import '../../landlord_matches/view/landlord_matches_screen.dart';
import '../../profile/view/owner_profile_screen.dart';
import '../../../core/router/app_router.dart';
import '../cubit/shell_cubit.dart';
import '../widgets/floating_nav_bar.dart';

/// Root scaffold for the owner variant of the main app.
class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider>[
        BlocProvider<LandlordHomeCubit>(
          create: (ctx) {
            final uid = currentUidOrNull(ctx);
            if (uid == null) return LandlordHomeCubit();
            return LandlordHomeCubit(
              ownerId: uid,
              propertyRepository: OwnerPropertyRepositoryImpl(),
              tenantsRepository: FindTenantsRepositoryImpl(),
            );
          },
        ),
        BlocProvider<ActivityCubit>(
          create: (ctx) {
            final uid = currentUidOrNull(ctx);
            if (uid == null) return ActivityCubit();
            return ActivityCubit(
              repository: NotificationRepositoryImpl(),
              uid: uid,
            );
          },
        ),
        BlocProvider<ShellCubit>(create: (_) => ShellCubit()),
      ],
      child: const _LandlordShellView(),
    );
  }
}

class _LandlordShellView extends StatelessWidget {
  const _LandlordShellView();

  static const List<Widget> _screens = <Widget>[
    LandlordHomeScreen(),
    LandlordMatchesScreen(),
    // index 2 is the Add shortcut — no persistent screen needed
    SizedBox.shrink(),
    ActivityScreen(),
    OwnerProfileScreen(),
  ];

  static List<FloatingNavBarItem> _items(int unread) => <FloatingNavBarItem>[
    const FloatingNavBarItem(icon: Icons.home_rounded, label: 'Home'),
    const FloatingNavBarItem(icon: Icons.favorite_rounded, label: 'Matches'),
    const FloatingNavBarItem(icon: Icons.add_circle_rounded, label: 'Add'),
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
          if (i == 2) {
            // "Add" shortcut — navigate to Add Property without changing tab
            Navigator.of(context).pushNamed(AppRouter.addProperty);
          } else {
            context.read<ShellCubit>().selectTab(ShellTab.values[i]);
          }
        },
      ),
    );
  }
}
