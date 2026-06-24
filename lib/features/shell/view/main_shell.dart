import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/model/user_role.dart';
import '../../activity/cubit/activity_cubit.dart';
import '../../activity/view/activity_screen.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/view/home_screen.dart';
import '../../matches/view/matches_screen.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/view/profile_screen.dart';
import '../../saved/view/saved_screen.dart';
import '../cubit/shell_cubit.dart';

/// Root scaffold of the main app: provides all feature cubits and manages
/// the bottom navigation between five tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider>[
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
        BlocProvider<ActivityCubit>(create: (_) => ActivityCubit()),
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
    MatchesScreen(),
    SavedScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellCubit>().state.tab;
    final unreadCount =
        context.select<ActivityCubit, int>((c) => c.state.unreadCount);

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: tab.index,
        unreadCount: unreadCount,
        onTap: (i) =>
            context.read<ShellCubit>().selectTab(ShellTab.values[i]),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.unreadCount,
    required this.onTap,
  });

  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.fieldBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: <Widget>[
              _NavItem(
                index: 0,
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label: 'Home',
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                icon: Icons.favorite_rounded,
                outlinedIcon: Icons.favorite_border,
                label: 'Matches',
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                icon: Icons.bookmark_rounded,
                outlinedIcon: Icons.bookmark_border,
                label: 'Saved',
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItemAlerts(
                index: 3,
                selectedIndex: selectedIndex,
                unreadCount: unreadCount,
                onTap: onTap,
              ),
              _NavItem(
                index: 4,
                icon: Icons.person_rounded,
                outlinedIcon: Icons.person_outlined,
                label: 'Profile',
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.selectedIndex,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  bool get _selected => index == selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _selected ? icon : outlinedIcon,
              color: _selected ? AppColors.accent : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _selected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemAlerts extends StatelessWidget {
  const _NavItemAlerts({
    required this.index,
    required this.selectedIndex,
    required this.unreadCount,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;

  bool get _selected => index == selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(
                  _selected
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined,
                  color:
                      _selected ? AppColors.accent : AppColors.textSecondary,
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.destructive,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Alerts',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _selected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
