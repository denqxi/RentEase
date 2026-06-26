import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/registration/model/user_role.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/view/home_screen.dart';
import '../../home/view/search_screen.dart';
import '../../inquiry/view/tenant_inquiries_screen.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/view/profile_screen.dart';
import '../cubit/shell_cubit.dart';

/// Root scaffold of the tenant app: four tabs — Home, Search, Inquiries, Profile.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider>[
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()),
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
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<ShellCubit>().state.tab;

    return Scaffold(
      body: IndexedStack(
        index: tab.index,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: tab.index,
        onTap: (i) =>
            context.read<ShellCubit>().selectTab(ShellTab.values[i]),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
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
                icon: Icons.search_rounded,
                outlinedIcon: Icons.search_outlined,
                label: 'Search',
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                icon: Icons.chat_bubble_rounded,
                outlinedIcon: Icons.chat_bubble_outline_rounded,
                label: 'Inquiries',
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                index: 3,
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
              color: _selected ? AppColors.primaryMid : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _selected ? AppColors.primaryMid : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
