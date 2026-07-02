import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/router/app_router.dart';
import '../../../features/home/cubit/home_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/profile_menu_card.dart';
import 'edit_constraints_screen.dart';
import 'saved_screen.dart';
import 'soft_preferences_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.settings_outlined, size: 24, color: cs.onSurface),
                  ],
                ),
              ),

              // Avatar + name + badge
              SizedBox(height: AppSpacing.md),
              Center(
                child: Column(
                  children: <Widget>[
                    const _ProfileAvatar(),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      MockData.tenantName,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _RoleBadge(role: state.userRole.label),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _StatsRow(),
              ),

              SizedBox(height: AppSpacing.lg),

              // Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ProfileMenuCard(
                  onLogout: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.signIn,
                    (_) => false,
                  ),
                  onEditPreferences: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditConstraintsScreen(),
                    ),
                  ),
                  onSoftPreferences: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SoftPreferencesScreen(),
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              Center(
                child: Text(
                  'RentEase prototype · v1.0',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// Avatar

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: <Color>[Color(0xFFDBC59C), Color(0xFF8B6914)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.person, color: Colors.white, size: 44),
        ),
      ),
    );
  }
}

// Role badge

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.matchHigh,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            role,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// Stats row

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final savedCount = context.watch<HomeCubit>().state.saved.length;
    final homeCubit = context.read<HomeCubit>();

    final stats = <_StatData>[
      _StatData(
        icon: Icons.bookmark_outline,
        count: savedCount,
        label: 'Saved',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider<HomeCubit>.value(
              value: homeCubit,
              child: const SavedScreen(),
            ),
          ),
        ),
      ),
      _StatData(icon: Icons.chat_bubble_outline, count: 2, label: 'Inquiries'),
      _StatData(icon: Icons.home_outlined, count: 8, label: 'Matches'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            for (int i = 0; i < stats.length; i++) ...<Widget>[
              Expanded(child: _StatTile(data: stats[i])),
              if (i < stats.length - 1)
                Container(
                  width: 1,
                  color: cs.outlineVariant,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.count,
    this.onTap,
    required this.label,
  });
  final IconData icon;
  final int count;
  final String label;
  final VoidCallback? onTap;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: AppColors.primary, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              '${data.count}',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 2),
            Text(
              data.label,
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
