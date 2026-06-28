import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/registration/model/user_role.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/view/home_screen.dart';
import '../../home/view/search_screen.dart';
import '../../inquiry/view/tenant_inquiries_screen.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/view/profile_screen.dart';
import '../cubit/shell_cubit.dart';

<<<<<<< Updated upstream
/// Root scaffold of the tenant app: four tabs — Home, Search, Inquiries, Profile.
=======
>>>>>>> Stashed changes
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
      extendBody: true,
      body: IndexedStack(
        index: tab.index,
        children: _screens,
      ),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: tab.index,
        onTap: (i) =>
            context.read<ShellCubit>().selectTab(ShellTab.values[i]),
      ),
    );
  }
}

<<<<<<< Updated upstream
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
=======
// â”€â”€ Bottom nav bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//
// Active tab: gray outer ring (70px) + teal inner circle (54px), floats above bar.
// Inactive tab: gray circle (44px) with dark icon, centred in white bar.

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
>>>>>>> Stashed changes
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const double _outerD    = 70.0; // gray ring diameter
  static const double _innerD    = 54.0; // teal circle diameter
  static const double _barH      = 52.0; // white bar height
  static const double _totalH    = 86.0; // extra headroom so teal circle clears the top

  // bar top edge = _totalH - _barH = 34px from slot top
  // barCenter = 34 + 26 = 60 â†’ alignY = (60/86)*2-1 â‰ˆ 0.40
  static const double _inactiveY = 0.40;
  static const double _barTopPx  = _totalH - _barH; // 34

  static const _items = <_NavItemData>[
    _NavItemData(icon: Icons.home_rounded,       label: 'Home'),
    _NavItemData(icon: Icons.search_rounded,      label: 'Search'),
    _NavItemData(icon: Icons.chat_bubble_rounded, label: 'Inquiries'),
    _NavItemData(icon: Icons.person_rounded,      label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _totalH,
        child: Stack(
          children: <Widget>[
<<<<<<< Updated upstream
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
=======
            // White grounded bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: _barH,
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 12,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
              ),
            ),
            // Nav items
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  _items.length,
                  (i) => Expanded(
                    child: _NavItem(
                      data: _items[i],
                      selected: i == selectedIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
                ),
>>>>>>> Stashed changes
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: widget.selected ? 1.0 : 0.0,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Inactive icon â€” fades out as active animates in
              Align(
                alignment: const Alignment(0, _FloatingNavBar._inactiveY),
                child: Opacity(
                  opacity: (1.0 - _fade.value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * (1.0 - _fade.value),
                    child: Icon(widget.data.icon, size: 24, color: context.appColors.ink),
                  ),
                ),
              ),
              // Active content â€” scales + fades in
              Opacity(
                opacity: _fade.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scale.value.clamp(0.0, 1.5),
                  alignment: const Alignment(0, -0.6),
                  child: _buildActiveContent(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveContent() {
    const double barTop  = _FloatingNavBar._barTopPx;
    const double tealTop = barTop - _FloatingNavBar._innerD / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Gray ring â€” bottom half clipped at bar top edge
        Positioned(
          top: barTop,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: Container(
                  width: _FloatingNavBar._outerD,
                  height: _FloatingNavBar._outerD,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldFill,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Teal circle floating above bar top
        Positioned(
          top: tealTop,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: _FloatingNavBar._innerD,
              height: _FloatingNavBar._innerD,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(widget.data.icon, size: 20, color: Colors.white),
                  SizedBox(height: 2),
                  Text(
                    widget.data.label,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
