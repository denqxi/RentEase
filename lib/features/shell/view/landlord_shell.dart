import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/activity/model/activity_item.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../activity/view/activity_screen.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../landlord_home/view/landlord_home_screen.dart';
import '../../landlord_matches/view/landlord_matches_screen.dart';
import '../../landlord_saved/view/landlord_saved_screen.dart';
import '../../profile/view/owner_profile_screen.dart';
import '../cubit/shell_cubit.dart';
import '../widgets/floating_nav_bar.dart';

/// Root scaffold for the owner variant of the main app.
class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider>[
        BlocProvider<LandlordHomeCubit>(create: (_) => LandlordHomeCubit()),
        BlocProvider<ActivityCubit>(
          create: (_) =>
              ActivityCubit(initialItems: ActivityItem.landlordSamples),
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
    LandlordSavedScreen(),
    ActivityScreen(),
    OwnerProfileScreen(),
  ];

  static const List<FloatingNavBarItem> _items = <FloatingNavBarItem>[
    FloatingNavBarItem(icon: Icons.home_rounded,          label: 'Home'),
    FloatingNavBarItem(icon: Icons.favorite_rounded,      label: 'Matches'),
    FloatingNavBarItem(icon: Icons.bookmark_rounded,      label: 'Saved'),
    FloatingNavBarItem(icon: Icons.notifications_rounded, label: 'Alerts'),
    FloatingNavBarItem(icon: Icons.person_rounded,        label: 'Profile'),
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
