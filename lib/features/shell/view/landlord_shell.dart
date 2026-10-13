import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../activity/cubit/activity_cubit.dart';
import '../../activity/data/repositories/notification_repository_impl.dart';
import '../../owner/view/owner_inquiries_screen.dart';
import '../../auth/presentation/current_uid.dart';
import '../../landlord_home/cubit/landlord_home_cubit.dart';
import '../../owner/data/repositories/find_tenants_repository_impl.dart';
import '../../owner/data/repositories/owner_property_repository_impl.dart';
import '../../landlord_home/view/landlord_home_screen.dart';
import '../../landlord_matches/view/landlord_matches_screen.dart';
import '../../profile/view/owner_profile_screen.dart';
import '../../../core/constants/app_svg_icons.dart';
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
    OwnerInquiriesScreen(),
    OwnerProfileScreen(),
  ];

  static List<FloatingNavBarItem> _items() => const <FloatingNavBarItem>[
    FloatingNavBarItem(svgString: AppSvgIcons.home, label: 'Home'),
    FloatingNavBarItem(svgString: AppSvgIcons.save, label: 'Matches'),
    FloatingNavBarItem(
      svgString: AppSvgIcons.ownerAdd,
      label: 'Add',
      iconSize: 28,
      activeIconSize: 24,
    ),
    FloatingNavBarItem(
      svgString: AppSvgIcons.inquiry,
      label: 'Inquiries',
    ),
    FloatingNavBarItem(svgString: AppSvgIcons.profile, label: 'Profile'),
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
        items: _items(),
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
